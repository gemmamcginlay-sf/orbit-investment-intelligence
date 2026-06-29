"""ORBIT — Market Intelligence Page"""
import streamlit as st

st.set_page_config(page_title="ORBIT | Market Intelligence", layout="wide")
st.title("Market Intelligence")

from snowflake.snowpark.context import get_active_session
session = get_active_session()


@st.cache_data(ttl=300)
def get_yield_curve():
    return session.sql("""
        SELECT MATURITY_CODE, YIELD_PCT
        FROM ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS
        WHERE DATE = (SELECT MAX(DATE) FROM ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS)
          AND MATURITY_CODE != 'OTHER'
        ORDER BY YIELD_PCT
    """).to_pandas()


@st.cache_data(ttl=300)
def get_fx_rates():
    return session.sql("""
        SELECT CURRENCY_PAIR, QUOTE_CURRENCY, EXCHANGE_RATE, DATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_FX_RATES
        WHERE DATE = (SELECT MAX(DATE) FROM ORBIT_DEMO.MARKET_DATA.FACT_FX_RATES)
        ORDER BY QUOTE_CURRENCY
    """).to_pandas()


@st.cache_data(ttl=300)
def get_economic_indicators():
    return session.sql("""
        SELECT INDICATOR_NAME, INDICATOR_CATEGORY, VALUE, DATE, UNIT
        FROM ORBIT_DEMO.MARKET_DATA.FACT_ECONOMIC_INDICATORS
        WHERE DATE = (SELECT MAX(DATE) FROM ORBIT_DEMO.MARKET_DATA.FACT_ECONOMIC_INDICATORS
                      WHERE INDICATOR_CATEGORY = FACT_ECONOMIC_INDICATORS.INDICATOR_CATEGORY)
        ORDER BY INDICATOR_CATEGORY, INDICATOR_NAME
    """).to_pandas()


@st.cache_data(ttl=300)
def get_policy_rates():
    return session.sql("""
        SELECT COUNTRY, RATE_NAME, RATE_PCT, DATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_POLICY_RATES
        QUALIFY ROW_NUMBER() OVER (PARTITION BY COUNTRY ORDER BY DATE DESC) = 1
        ORDER BY COUNTRY
    """).to_pandas()


# Layout
col1, col2 = st.columns(2)

with col1:
    st.subheader("US Treasury Yield Curve")
    try:
        df = get_yield_curve()
        st.line_chart(df.set_index('MATURITY_CODE')['YIELD_PCT'])
        st.dataframe(df, hide_index=True)
    except Exception as e:
        st.warning(f"Yield data not available: {e}")

with col2:
    st.subheader("FX Rates (vs USD)")
    try:
        df = get_fx_rates()
        st.dataframe(df[['QUOTE_CURRENCY', 'EXCHANGE_RATE', 'DATE']], hide_index=True)
    except Exception as e:
        st.warning(f"FX data not available: {e}")

st.divider()

col3, col4 = st.columns(2)

with col3:
    st.subheader("Economic Indicators (Latest)")
    try:
        df = get_economic_indicators()
        st.dataframe(df[['INDICATOR_CATEGORY', 'INDICATOR_NAME', 'VALUE', 'DATE']], hide_index=True)
    except Exception as e:
        st.warning(f"Economic data not available: {e}")

with col4:
    st.subheader("Central Bank Policy Rates")
    try:
        df = get_policy_rates()
        st.dataframe(df[['COUNTRY', 'RATE_PCT', 'DATE']], hide_index=True)
    except Exception as e:
        st.warning(f"Policy rate data not available: {e}")

# Agent link
st.divider()
account_url = f"https://{session.get_current_account()}.snowflakecomputing.com"
st.link_button(
    "Ask Market Intelligence Agent",
    f"{account_url}/intelligence/cowork?agent=ORBIT_DEMO.AI.ORBIT_MARKET_AGENT"
)
