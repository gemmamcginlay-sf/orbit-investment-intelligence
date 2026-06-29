# ORBIT Market Intelligence — yields, FX, indicators, policy rates
# Co-authored with CoCo
import streamlit as st

conn = st.session_state.conn


@st.cache_data(ttl=300)
def get_yield_curve():
    return conn.query("""
        SELECT MATURITY_CODE, YIELD_PCT
        FROM ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS
        WHERE DATE = (SELECT MAX(DATE) FROM ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS)
          AND MATURITY_CODE != 'OTHER'
        ORDER BY YIELD_PCT
    """)


@st.cache_data(ttl=300)
def get_fx_rates():
    return conn.query("""
        SELECT CURRENCY_PAIR, QUOTE_CURRENCY, EXCHANGE_RATE, DATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_FX_RATES
        WHERE DATE = (SELECT MAX(DATE) FROM ORBIT_DEMO.MARKET_DATA.FACT_FX_RATES)
        ORDER BY QUOTE_CURRENCY
    """)


@st.cache_data(ttl=300)
def get_economic_indicators():
    return conn.query("""
        SELECT INDICATOR_NAME, INDICATOR_CATEGORY, VALUE, DATE, UNIT
        FROM ORBIT_DEMO.MARKET_DATA.FACT_ECONOMIC_INDICATORS
        WHERE DATE = (SELECT MAX(DATE) FROM ORBIT_DEMO.MARKET_DATA.FACT_ECONOMIC_INDICATORS
                      WHERE INDICATOR_CATEGORY = FACT_ECONOMIC_INDICATORS.INDICATOR_CATEGORY)
        ORDER BY INDICATOR_CATEGORY, INDICATOR_NAME
    """)


@st.cache_data(ttl=300)
def get_policy_rates():
    return conn.query("""
        SELECT COUNTRY, RATE_NAME, RATE_PCT, DATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_POLICY_RATES
        QUALIFY ROW_NUMBER() OVER (PARTITION BY COUNTRY ORDER BY DATE DESC) = 1
        ORDER BY COUNTRY
    """)


# Yield curve section
with st.container(border=True):
    st.markdown("**US Treasury yield curve**")
    try:
        df = get_yield_curve()
        if not df.empty:
            st.bar_chart(df, x="MATURITY_CODE", y="YIELD_PCT", horizontal=False)
        else:
            st.info("No yield data available")
    except Exception as e:
        st.warning(f"Yield data unavailable: {e}")

col1, col2 = st.columns(2)

with col1:
    with st.container(border=True):
        st.markdown("**FX rates vs USD**")
        try:
            df = get_fx_rates()
            if not df.empty:
                st.dataframe(
                    df[['QUOTE_CURRENCY', 'EXCHANGE_RATE', 'DATE']],
                    column_config={
                        "QUOTE_CURRENCY": st.column_config.TextColumn("Currency"),
                        "EXCHANGE_RATE": st.column_config.NumberColumn("Rate", format="%.4f"),
                        "DATE": st.column_config.DateColumn("As of"),
                    },
                    hide_index=True,
                    use_container_width=True,
                )
            else:
                st.info("No FX data available")
        except Exception as e:
            st.warning(f"FX data unavailable: {e}")

with col2:
    with st.container(border=True):
        st.markdown("**Central bank policy rates**")
        try:
            df = get_policy_rates()
            if not df.empty:
                st.dataframe(
                    df[['COUNTRY', 'RATE_PCT', 'DATE']],
                    column_config={
                        "COUNTRY": st.column_config.TextColumn("Country"),
                        "RATE_PCT": st.column_config.NumberColumn("Rate %", format="%.2f%%"),
                        "DATE": st.column_config.DateColumn("Effective"),
                    },
                    hide_index=True,
                    use_container_width=True,
                )
            else:
                st.info("No policy rate data")
        except Exception as e:
            st.warning(f"Policy rate data unavailable: {e}")

with st.container(border=True):
    st.markdown("**Economic indicators (latest reading per category)**")
    try:
        df = get_economic_indicators()
        if not df.empty:
            st.dataframe(
                df[['INDICATOR_CATEGORY', 'INDICATOR_NAME', 'VALUE', 'UNIT', 'DATE']],
                column_config={
                    "INDICATOR_CATEGORY": st.column_config.TextColumn("Category"),
                    "INDICATOR_NAME": st.column_config.TextColumn("Indicator"),
                    "VALUE": st.column_config.NumberColumn("Value", format="%.2f"),
                    "UNIT": st.column_config.TextColumn("Unit"),
                    "DATE": st.column_config.DateColumn("Date"),
                },
                hide_index=True,
                use_container_width=True,
            )
        else:
            st.info("No economic data available")
    except Exception as e:
        st.warning(f"Economic data unavailable: {e}")
