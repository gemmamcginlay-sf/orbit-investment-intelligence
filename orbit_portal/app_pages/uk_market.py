# UK Market — UK economic indicators and GBP FX rates
# Co-authored with CoCo
import streamlit as st

conn = st.session_state.conn

tab1, tab2 = st.tabs(["UK indicators", "GBP rates"])

with tab1:
    search = st.text_input("Search UK data", placeholder="retail, population, GDP", key="uk_s")

    if search:
        uk_vars = conn.query("""
            SELECT DISTINCT VARIABLE_NAME, FREQUENCY
            FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.UNITED_KINGDOM_ATTRIBUTES
            WHERE UPPER(VARIABLE_NAME) LIKE UPPER(?) LIMIT 30
        """, params=[f"%{search}%"])
    else:
        uk_vars = conn.query("""
            SELECT DISTINCT VARIABLE_NAME, FREQUENCY
            FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.UNITED_KINGDOM_ATTRIBUTES
            WHERE VARIABLE_NAME LIKE '%Retail Sales%' OR VARIABLE_NAME LIKE '%all retailing%'
            LIMIT 30
        """)

    if not uk_vars.empty:
        selected_var = st.selectbox("Indicator", uk_vars["VARIABLE_NAME"].tolist(), label_visibility="collapsed")

        ts_df = conn.query("""
            SELECT DATE, VALUE, UNIT
            FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.UNITED_KINGDOM_TIMESERIES
            WHERE VARIABLE_NAME = ? ORDER BY DATE DESC LIMIT 200
        """, params=[selected_var])

        if not ts_df.empty:
            ts_df = ts_df.sort_values("DATE")
            latest = ts_df.iloc[-1]
            c1, c2 = st.columns(2)
            c1.metric("Latest", f"{float(latest['VALUE']):,.2f}")
            c2.metric("Date", str(latest["DATE"]))

            with st.container(border=True):
                st.line_chart(ts_df.set_index("DATE")["VALUE"], height=300)

            with st.expander("Data"):
                st.dataframe(ts_df, use_container_width=True, hide_index=True)
    else:
        st.info("Search for UK indicators (retail, population, deaths, etc.)")

with tab2:
    quote_options = ["USD", "EUR", "JPY", "CHF", "AUD", "CAD"]
    selected_quote = st.selectbox("GBP vs", quote_options, label_visibility="collapsed")

    fx_df = conn.query("""
        SELECT DATE, VALUE FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.FX_RATES_TIMESERIES
        WHERE BASE_CURRENCY_ID = 'GBP' AND QUOTE_CURRENCY_ID = ?
        ORDER BY DATE DESC LIMIT 365
    """, params=[selected_quote])

    if not fx_df.empty:
        fx_df = fx_df.sort_values("DATE")
        latest = float(fx_df.iloc[-1]["VALUE"])
        first = float(fx_df.iloc[0]["VALUE"])
        change = ((latest - first) / first) * 100

        c1, c2, c3 = st.columns(3)
        c1.metric(f"GBP/{selected_quote}", f"{latest:.4f}")
        c2.metric("Change", f"{change:+.2f}%")
        c3.metric("Points", len(fx_df))

        with st.container(border=True):
            st.line_chart(fx_df.set_index("DATE")["VALUE"], height=300)
    else:
        st.warning(f"No data for GBP/{selected_quote}.")
