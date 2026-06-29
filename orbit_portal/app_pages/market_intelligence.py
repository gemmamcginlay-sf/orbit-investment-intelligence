# ORBIT Market Intelligence — macro overview + UK and FX focus
# Co-authored with CoCo
import streamlit as st

conn = st.session_state.conn


@st.cache_data(ttl=300)
def get_yield_curve():
    return conn.query("""
        SELECT MATURITY_LABEL, YIELD_PCT
        FROM ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS
        WHERE DATE = (SELECT MAX(DATE) FROM ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS)
        ORDER BY MATURITY_MONTHS
    """)


@st.cache_data(ttl=300)
def get_fx_rates():
    return conn.query("""
        SELECT QUOTE_CURRENCY, EXCHANGE_RATE, DATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_FX_RATES
        WHERE DATE = (SELECT MAX(DATE) FROM ORBIT_DEMO.MARKET_DATA.FACT_FX_RATES)
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
        QUALIFY ROW_NUMBER() OVER (PARTITION BY INDICATOR_CATEGORY ORDER BY DATE DESC) = 1
        ORDER BY INDICATOR_CATEGORY
    """)


@st.cache_data(ttl=300)
def get_policy_rates():
    return conn.query("""
        SELECT COUNTRY, RATE_NAME, RATE_PCT * 100 AS RATE_PCT, DATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_POLICY_RATES
        QUALIFY ROW_NUMBER() OVER (PARTITION BY COUNTRY ORDER BY DATE DESC) = 1
        ORDER BY COUNTRY
    """)


tab1, tab2 = st.tabs(["Macro overview", "UK and FX"])

with tab1:
    with st.container(border=True):
        st.markdown("**US Treasury yield curve (latest)**")
        try:
            yields = get_yield_curve()
            if not yields.empty:
                st.bar_chart(yields, x="MATURITY_LABEL", y="YIELD_PCT")
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

    # Interactive economic indicator explorer
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

with tab2:
    col1, col2 = st.columns(2)

    with col1:
        with st.container(border=True):
            st.markdown("**GBP/USD history**")
            try:
                gbp = get_fx_history('GBP')
                if not gbp.empty:
                    latest_rate = gbp.iloc[-1]['EXCHANGE_RATE']
                    st.metric("GBP/USD (latest)", f"{latest_rate:.4f}")
                    st.line_chart(gbp, x="DATE", y="EXCHANGE_RATE")
                else:
                    st.info("No GBP/USD data")
            except Exception as e:
                st.warning(f"GBP data unavailable: {e}")

        # Bank of England rate
        with st.container(border=True):
            st.markdown("**Bank of England base rate**")
            try:
                rates = get_policy_rates()
                boe = rates[rates['COUNTRY'].str.contains('United Kingdom', case=False, na=False)]
                if not boe.empty:
                    row = boe.iloc[0]
                    st.metric("BoE base rate", f"{row['RATE_PCT']:.2f}%")
                else:
                    st.caption("BoE rate not found — showing all countries:")
                    st.dataframe(rates[['COUNTRY', 'RATE_PCT']], hide_index=True, use_container_width=True)
            except Exception as e:
                st.warning(f"BoE rate unavailable: {e}")

    with col2:
        with st.container(border=True):
            st.markdown("**All FX rates vs USD (latest)**")
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
                else:
                    st.info("No FX data")
            except Exception as e:
                st.warning(f"FX data unavailable: {e}")

    # FX pair picker
    with st.container(border=True):
        st.markdown("**FX pair chart — pick any currency**")
        try:
            currencies = get_fx_currencies()
            if not currencies.empty:
                selected_ccy = st.selectbox(
                    "Currency vs USD", currencies['QUOTE_CURRENCY'].tolist(),
                    index=currencies['QUOTE_CURRENCY'].tolist().index('GBP') if 'GBP' in currencies['QUOTE_CURRENCY'].values else 0,
                    key="fx_picker"
                )
                if selected_ccy:
                    fx_hist = get_fx_history(selected_ccy)
                    if not fx_hist.empty:
                        latest = fx_hist.iloc[-1]['EXCHANGE_RATE']
                        first = fx_hist.iloc[0]['EXCHANGE_RATE']
                        change_pct = ((latest - first) / first) * 100
                        st.metric(f"{selected_ccy}/USD", f"{latest:.4f}", f"{change_pct:+.2f}%")
                        st.line_chart(fx_hist, x="DATE", y="EXCHANGE_RATE")
                    else:
                        st.info(f"No history for {selected_ccy}")
            else:
                st.info("No FX currencies available")
        except Exception as e:
            st.warning(f"FX picker unavailable: {e}")
