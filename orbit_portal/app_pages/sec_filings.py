# SEC Filings — XBRL segments, filing sections, report attributes
# Co-authored with CoCo
import streamlit as st

conn = st.session_state.conn

selected_ticker = st.session_state.get("selected_ticker")
selected_company = st.session_state.get("selected_company")


@st.cache_data(ttl=300)
def resolve_cik(ticker):
    result = conn.query("""
        SELECT CIK FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_INDEX
        WHERE UPPER(PRIMARY_TICKER) = UPPER(?) LIMIT 1
    """, params=[ticker])
    if not result.empty:
        return result.iloc[0]["CIK"]
    return None


if selected_ticker and selected_company:
    st.caption(f"COMPANY: {selected_company} ({selected_ticker})")
    cik = resolve_cik(selected_ticker)
else:
    company_search = st.text_input("Company or ticker", placeholder="Microsoft, MSFT")
    cik = None
    if company_search:
        lookup = conn.query("""
            SELECT DISTINCT ci.CIK, ci.COMPANY_NAME, ci.PRIMARY_TICKER
            FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_INDEX ci
            WHERE UPPER(ci.COMPANY_NAME) LIKE UPPER(?) OR UPPER(ci.PRIMARY_TICKER) = UPPER(?)
            LIMIT 10
        """, params=[f"%{company_search}%", company_search])
        if not lookup.empty:
            sel = st.selectbox("Select", lookup.index.tolist(),
                format_func=lambda i: f"{lookup.iloc[i]['COMPANY_NAME']}  •  {lookup.iloc[i]['PRIMARY_TICKER'] or '—'}",
                label_visibility="collapsed")
            cik = lookup.iloc[sel]["CIK"]
        else:
            st.warning("Not found.")
    else:
        st.info("Select a company on the Research Hub, or search here.")
        st.stop()

if not cik:
    st.warning("Could not resolve CIK for this ticker.")
    st.stop()

# Filing summary
summary = conn.query("""
    SELECT FORM_TYPE, COUNT(*) AS CNT
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_REPORT_INDEX
    WHERE CIK = ? GROUP BY FORM_TYPE ORDER BY CNT DESC LIMIT 8
""", params=[cik])
if not summary.empty:
    with st.expander("Filing types available"):
        st.dataframe(summary, use_container_width=True, hide_index=True, height=180)

tab1, tab2, tab3 = st.tabs(["Segments", "XBRL", "Sections"])

with tab1:
    rev_df = conn.query("""
        SELECT PERIOD_END_DATE, VARIABLE_NAME, VALUE, BUSINESS_SEGMENT, UNIT
        FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_METRICS_TIMESERIES
        WHERE CIK = ? AND VALUE IS NOT NULL ORDER BY PERIOD_END_DATE DESC LIMIT 500
    """, params=[cik])

    if not rev_df.empty:
        variables = rev_df["VARIABLE_NAME"].dropna().unique().tolist()
        selected_var = st.selectbox("Metric", variables, label_visibility="collapsed")
        filtered = rev_df[rev_df["VARIABLE_NAME"] == selected_var] if selected_var else rev_df

        if not filtered.empty:
            segments = filtered["BUSINESS_SEGMENT"].dropna().unique().tolist()
            with st.container(border=True):
                if segments:
                    chart = filtered[filtered["BUSINESS_SEGMENT"].notna()].pivot_table(
                        index="PERIOD_END_DATE", columns="BUSINESS_SEGMENT", values="VALUE", aggfunc="sum")
                    st.line_chart(chart, height=300)
                else:
                    st.line_chart(filtered.set_index("PERIOD_END_DATE")["VALUE"], height=300)
            with st.expander("Data"):
                st.dataframe(filtered, use_container_width=True, hide_index=True)
    else:
        st.warning("No segment data. Foreign issuers (20-F filers) may lack structured XBRL. Try Sections tab.")

with tab2:
    xbrl_df = conn.query("""
        SELECT TAG, VALUE, UNIT_OF_MEASURE, PERIOD_END_DATE, STATEMENT, MEASURE_DESCRIPTION
        FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_REPORT_ATTRIBUTES
        WHERE CIK = ? AND STATEMENT IN ('BS','IS','CF')
        ORDER BY PERIOD_END_DATE DESC LIMIT 500
    """, params=[cik])

    if not xbrl_df.empty:
        stmt_filter = st.selectbox("Statement", ["All", "BS", "IS", "CF"], label_visibility="collapsed")
        if stmt_filter != "All":
            xbrl_df = xbrl_df[xbrl_df["STATEMENT"] == stmt_filter]

        with st.container(border=True):
            st.caption("TOP TAGS")
            tags = xbrl_df["TAG"].value_counts().head(10).reset_index()
            tags.columns = ["TAG", "COUNT"]
            st.bar_chart(tags, x="TAG", y="COUNT", height=200)

        with st.expander("Full table"):
            st.dataframe(xbrl_df, use_container_width=True, hide_index=True)
    else:
        st.warning("No XBRL data. Foreign issuers often lack this. Try Sections tab.")

with tab3:
    items_df = conn.query("""
        SELECT ITEM_TITLE, FORM_TYPE, FILED_DATE, LEFT(PLAINTEXT_CONTENT, 1500) AS PREVIEW
        FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_ITEM_ATTRIBUTES
        WHERE CIK = ? ORDER BY FILED_DATE DESC LIMIT 20
    """, params=[cik])

    if not items_df.empty:
        sel_item = st.selectbox("Section", items_df.index.tolist(),
            format_func=lambda i: f"{items_df.iloc[i]['FORM_TYPE']} — {items_df.iloc[i]['ITEM_TITLE']}  ({items_df.iloc[i]['FILED_DATE']})",
            label_visibility="collapsed")
        if sel_item is not None:
            row = items_df.iloc[sel_item]
            with st.container(border=True):
                st.caption(f"{row['FORM_TYPE']} • {row['FILED_DATE']}")
                st.markdown(f"**{row['ITEM_TITLE']}**")
                st.text_area("", value=row["PREVIEW"] or "—", height=350, disabled=True, label_visibility="collapsed")
    else:
        st.info("No parsed sections available.")
