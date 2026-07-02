# ORBIT Market Intelligence — macro overview, FX, UK data, Form 144
# Co-authored with CoCo
import streamlit as st
import pandas as pd
import altair as alt

conn = st.session_state.conn


@st.cache_data(ttl=300)
def get_yield_curve():
    return conn.query("""
        SELECT MATURITY_LABEL, YIELD_PCT, MATURITY_MONTHS
        FROM ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS
        WHERE DATE = (SELECT MAX(DATE) FROM ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS)
        ORDER BY MATURITY_MONTHS
    """)


@st.cache_data(ttl=300)
def get_fx_rates():
    return conn.query("""
        SELECT QUOTE_CURRENCY, EXCHANGE_RATE, DATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_FX_RATES
        QUALIFY ROW_NUMBER() OVER (PARTITION BY QUOTE_CURRENCY ORDER BY DATE DESC) = 1
        ORDER BY QUOTE_CURRENCY
    """)


@st.cache_data(ttl=300)
def get_fx_currencies():
    return conn.query("""
        SELECT DISTINCT QUOTE_CURRENCY
        FROM ORBIT_DEMO.MARKET_DATA.FACT_FX_RATES
        ORDER BY QUOTE_CURRENCY
    """)


@st.cache_data(ttl=300)
def get_fx_history(currency):
    return conn.query("""
        SELECT DATE, EXCHANGE_RATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_FX_RATES
        WHERE QUOTE_CURRENCY = :1
        ORDER BY DATE
    """, params=[currency])


@st.cache_data(ttl=300)
def get_economic_categories():
    return conn.query("""
        SELECT DISTINCT INDICATOR_CATEGORY
        FROM ORBIT_DEMO.MARKET_DATA.FACT_ECONOMIC_INDICATORS
        ORDER BY INDICATOR_CATEGORY
    """)


@st.cache_data(ttl=300)
def get_indicators_for_category(category):
    return conn.query("""
        SELECT DISTINCT INDICATOR_NAME
        FROM ORBIT_DEMO.MARKET_DATA.FACT_ECONOMIC_INDICATORS
        WHERE INDICATOR_CATEGORY = :1
        ORDER BY INDICATOR_NAME
    """, params=[category])


@st.cache_data(ttl=300)
def get_indicator_timeseries(indicator_name):
    return conn.query("""
        SELECT DATE, VALUE, UNIT
        FROM ORBIT_DEMO.MARKET_DATA.FACT_ECONOMIC_INDICATORS
        WHERE INDICATOR_NAME = :1
        ORDER BY DATE
    """, params=[indicator_name])


@st.cache_data(ttl=300)
def get_economic_indicators_latest():
    return conn.query("""
        SELECT INDICATOR_NAME, INDICATOR_CATEGORY, VALUE, UNIT, DATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_ECONOMIC_INDICATORS
        QUALIFY ROW_NUMBER() OVER (PARTITION BY INDICATOR_NAME ORDER BY DATE DESC) = 1
        ORDER BY INDICATOR_CATEGORY, INDICATOR_NAME
    """)


@st.cache_data(ttl=300)
def get_policy_rates():
    return conn.query("""
        SELECT COUNTRY,
               REGEXP_REPLACE(RATE_NAME, 'Central bank policy rates: |\\s*-\\s*End of period.*', '') AS RATE_NAME,
               RATE_PCT * 100 AS RATE_PCT, DATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_POLICY_RATES
        QUALIFY ROW_NUMBER() OVER (PARTITION BY COUNTRY ORDER BY DATE DESC) = 1
        ORDER BY COUNTRY
    """)


@st.cache_data(ttl=300)
def get_form144_filings():
    return conn.query("""
        SELECT ISSUER_NAME, FILER_NAME, SECURITY_TITLE, TRANSACTION_SHARES, FILED_DATE
        FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_FORM144_SECURITIES_TO_BE_SOLD_INDEX
        WHERE FILED_DATE >= DATEADD(day, -60, CURRENT_DATE())
        ORDER BY FILED_DATE DESC LIMIT 100
    """)


tab_macro, tab_fx, tab_form144 = st.tabs(["US Macro", "FX & UK", "Form 144"])

# ─── TAB 1: US MACRO ─────────────────────────────────────────────────────────
with tab_macro:
    with st.container(border=True):
        st.markdown("**US Treasury yield curve (latest)**")
        try:
            yields = get_yield_curve()
            if not yields.empty:
                chart = alt.Chart(yields).mark_bar().encode(
                    x=alt.X('MATURITY_LABEL', sort=None, title='Maturity'),
                    y=alt.Y('YIELD_PCT', title='Yield %', scale=alt.Scale(zero=False)),
                )
                st.altair_chart(chart, use_container_width=True)
            else:
                st.info("No yield curve data")
        except Exception as e:
            st.warning(f"Yield curve unavailable: {e}")

    col1, col2 = st.columns(2)

    with col1:
        with st.container(border=True):
            st.markdown("**Central bank policy rates**")
            try:
                rates = get_policy_rates()
                if not rates.empty:
                    st.dataframe(
                        rates,
                        column_config={
                            "COUNTRY": "Country",
                            "RATE_NAME": "Rate",
                            "RATE_PCT": st.column_config.NumberColumn("Rate %", format="%.2f%%"),
                            "DATE": st.column_config.DateColumn("Effective"),
                        },
                        hide_index=True,
                        use_container_width=True,
                    )
                else:
                    st.info("No policy rate data")
            except Exception as e:
                st.warning(f"Policy rates unavailable: {e}")

    with col2:
        with st.container(border=True):
            st.markdown("**Economic indicators (latest per category)**")
            try:
                econ = get_economic_indicators_latest()
                if not econ.empty:
                    st.dataframe(
                        econ,
                        column_config={
                            "INDICATOR_CATEGORY": "Category",
                            "INDICATOR_NAME": "Indicator",
                            "VALUE": st.column_config.NumberColumn("Value", format="%.2f"),
                            "UNIT": "Unit",
                            "DATE": st.column_config.DateColumn("Date"),
                        },
                        hide_index=True,
                        use_container_width=True,
                    )
                else:
                    st.info("No economic data")
            except Exception as e:
                st.warning(f"Economic data unavailable: {e}")

    with st.container(border=True):
        st.markdown("**Economic indicator explorer**")
        try:
            categories = get_economic_categories()
            if not categories.empty:
                selected_cat = st.selectbox(
                    "Category", categories['INDICATOR_CATEGORY'].tolist(), key="econ_cat"
                )
                if selected_cat:
                    indicators = get_indicators_for_category(selected_cat)
                    if not indicators.empty:
                        selected_ind = st.selectbox(
                            "Indicator", indicators['INDICATOR_NAME'].tolist(), key="econ_ind"
                        )
                        if selected_ind:
                            ts = get_indicator_timeseries(selected_ind)
                            if not ts.empty:
                                unit = ts.iloc[0]['UNIT']
                                latest_val = ts.iloc[-1]['VALUE']
                                st.metric(selected_ind, f"{latest_val:.2f} {unit}")
                                st.line_chart(ts, x="DATE", y="VALUE")
                            else:
                                st.info("No time series data")
            else:
                st.info("No economic categories found")
        except Exception as e:
            st.warning(f"Indicator explorer unavailable: {e}")

# ─── TAB 2: FX & UK ──────────────────────────────────────────────────────────
with tab_fx:
    # FX pair picker at top — most useful control
    with st.container(border=True):
        st.markdown("**FX rates — pick any pair vs USD**")
        try:
            currencies = get_fx_currencies()
            if not currencies.empty:
                ccy_list = currencies['QUOTE_CURRENCY'].tolist()
                default_idx = ccy_list.index('GBP') if 'GBP' in ccy_list else 0
                selected_ccy = st.selectbox(
                    "Currency", ccy_list, index=default_idx, key="fx_picker"
                )
                if selected_ccy:
                    fx_hist = get_fx_history(selected_ccy)
                    if not fx_hist.empty:
                        latest = fx_hist.iloc[-1]['EXCHANGE_RATE']
                        first = fx_hist.iloc[0]['EXCHANGE_RATE']
                        change_pct = ((latest - first) / first) * 100

                        with st.container(horizontal=True):
                            st.metric(f"{selected_ccy}/USD", f"{latest:.4f}", f"{change_pct:+.2f}% (period)", border=True)
                            st.metric("Data points", len(fx_hist), border=True)
                            st.metric("Latest date", str(fx_hist.iloc[-1]['DATE']), border=True)

                        st.line_chart(fx_hist, x="DATE", y="EXCHANGE_RATE", height=280)
                    else:
                        st.info(f"No history for {selected_ccy}")
            else:
                st.info("No FX currencies available")
        except Exception as e:
            st.warning(f"FX data unavailable: {e}")

    # All FX snapshot
    with st.expander("All FX rates vs USD (latest snapshot)"):
        try:
            fx = get_fx_rates()
            if not fx.empty:
                st.dataframe(
                    fx,
                    column_config={
                        "QUOTE_CURRENCY": "Currency",
                        "EXCHANGE_RATE": st.column_config.NumberColumn("Rate", format="%.4f"),
                        "DATE": st.column_config.DateColumn("Date"),
                    },
                    hide_index=True,
                    use_container_width=True,
                )
        except Exception as e:
            st.warning(f"FX snapshot unavailable: {e}")

    # Bank of England + policy rates
    st.markdown("---")
    try:
        rates = get_policy_rates()
        boe = rates[rates['COUNTRY'].str.contains('United Kingdom', case=False, na=False)]
        if not boe.empty:
            st.metric("Bank of England base rate", f"{boe.iloc[0]['RATE_PCT']:.2f}%")
    except Exception:
        pass

    # UK economic indicators
    st.markdown("---")
    with st.container(border=True):
        st.markdown("**UK economic indicators**")
        st.caption("Source: Snowflake Public Data (Paid) — UK data updated periodically; latest observations may lag.")

        search = st.text_input("Search UK data", placeholder="retail, GDP, population, unemployment", key="uk_s")

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
            selected_var = st.selectbox("Indicator", uk_vars["VARIABLE_NAME"].tolist(), label_visibility="collapsed", key="uk_var")

            ts_df = conn.query("""
                SELECT DATE, VALUE, UNIT
                FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.UNITED_KINGDOM_TIMESERIES
                WHERE VARIABLE_NAME = ? ORDER BY DATE DESC LIMIT 200
            """, params=[selected_var])

            if not ts_df.empty:
                ts_df = ts_df.sort_values("DATE")
                latest = ts_df.iloc[-1]
                with st.container(horizontal=True):
                    st.metric("Latest", f"{float(latest['VALUE']):,.2f}", border=True)
                    st.metric("Date", str(latest["DATE"]), border=True)
                    st.metric("Frequency", uk_vars[uk_vars["VARIABLE_NAME"] == selected_var].iloc[0]["FREQUENCY"], border=True)

                st.line_chart(ts_df.set_index("DATE")["VALUE"], height=280)

                with st.expander("Data table"):
                    st.dataframe(ts_df, use_container_width=True, hide_index=True)
        else:
            st.info("Search for UK indicators (retail, GDP, population, unemployment, etc.)")

# ─── TAB 3: FORM 144 ─────────────────────────────────────────────────────────
with tab_form144:
    st.markdown("**Form 144 — Intent to Sell (last 60 days)**")
    st.caption("Form 144 filings signal insider intent to sell restricted/control securities.")
    try:
        f144_df = get_form144_filings()
        if not f144_df.empty:
            with st.container(horizontal=True):
                st.metric("Filings (60d)", len(f144_df), border=True)
                unique_issuers = f144_df["ISSUER_NAME"].nunique()
                st.metric("Unique issuers", unique_issuers, border=True)

            with st.container(border=True):
                st.markdown("**Top issuers by filing count**")
                top_issuers = f144_df["ISSUER_NAME"].value_counts().head(10).reset_index()
                top_issuers.columns = ["ISSUER", "FILINGS"]
                st.bar_chart(top_issuers, x="ISSUER", y="FILINGS", height=250)

            with st.container(border=True):
                st.markdown("**All filings**")
                st.dataframe(
                    f144_df,
                    column_config={
                        "ISSUER_NAME": "Issuer",
                        "FILER_NAME": "Filer",
                        "SECURITY_TITLE": "Security",
                        "TRANSACTION_SHARES": st.column_config.NumberColumn("Shares", format="%,.0f"),
                        "FILED_DATE": st.column_config.DateColumn("Filed"),
                    },
                    hide_index=True,
                    use_container_width=True,
                    height=400,
                )
        else:
            st.info("No recent Form 144 filings found.")
    except Exception as e:
        st.warning(f"Form 144 data unavailable: {e}")
