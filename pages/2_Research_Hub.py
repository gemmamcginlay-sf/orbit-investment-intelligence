"""ORBIT — Research Hub Page"""
import streamlit as st

st.set_page_config(page_title="ORBIT | Research Hub", layout="wide")
st.title("Research Hub")

from snowflake.snowpark.context import get_active_session
session = get_active_session()


@st.cache_data(ttl=300)
def get_companies():
    return session.sql(
        "SELECT TICKER, COMPANY_NAME, GICS_SECTOR FROM ORBIT_DEMO.CURATED.DIM_ISSUER ORDER BY COMPANY_NAME"
    ).to_pandas()


@st.cache_data(ttl=300)
def get_financials(ticker):
    return session.sql(f"""
        SELECT PERIOD_END_DATE, FISCAL_PERIOD, REVENUE, NET_INCOME, OPERATING_INCOME,
               EPS_BASIC, GROSS_MARGIN_PCT, OPERATING_MARGIN_PCT, NET_MARGIN_PCT, ROE_PCT,
               FREE_CASH_FLOW, DEBT_TO_EQUITY
        FROM ORBIT_DEMO.MARKET_DATA.FACT_SEC_FINANCIALS
        WHERE TICKER = '{ticker}' AND FISCAL_PERIOD = 'Q'
        ORDER BY PERIOD_END_DATE DESC
        LIMIT 12
    """).to_pandas()


@st.cache_data(ttl=300)
def get_price_history(ticker):
    return session.sql(f"""
        SELECT PRICE_DATE, PRICE_CLOSE, VOLUME
        FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES
        WHERE TICKER = '{ticker}'
        ORDER BY PRICE_DATE
    """).to_pandas()


@st.cache_data(ttl=300)
def get_insider_trades(ticker):
    return session.sql(f"""
        SELECT TRANSACTION_DATE, ISSUER_NAME, TRANSACTION_TYPE,
               TRANSACTION_SHARES, TRANSACTION_PRICE_PER_SHARE, OWNERSHIP
        FROM ORBIT_DEMO.MARKET_DATA.FACT_INSIDER_TRANSACTIONS
        WHERE TICKER = '{ticker}'
        ORDER BY TRANSACTION_DATE DESC
        LIMIT 20
    """).to_pandas()


@st.cache_data(ttl=300)
def get_holders(ticker):
    return session.sql(f"""
        SELECT INSTITUTION_NAME, SHARES_HELD, MARKET_VALUE_USD, FILING_DATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_INSTITUTIONAL_HOLDINGS
        WHERE TICKER = '{ticker}'
        ORDER BY MARKET_VALUE_USD DESC
        LIMIT 15
    """).to_pandas()


# Company selector
companies = get_companies()
selected = st.selectbox(
    "Select a company",
    companies['TICKER'].tolist(),
    format_func=lambda t: f"{t} — {companies[companies['TICKER']==t]['COMPANY_NAME'].values[0]}"
)

if selected:
    company_name = companies[companies['TICKER'] == selected]['COMPANY_NAME'].values[0]
    sector = companies[companies['TICKER'] == selected]['GICS_SECTOR'].values[0]
    st.markdown(f"**{company_name}** | {sector}")

    tab1, tab2, tab3, tab4 = st.tabs(["Stock Price", "Financials", "Insider Trades", "Institutional Holders"])

    with tab1:
        try:
            prices = get_price_history(selected)
            if not prices.empty:
                st.line_chart(prices.set_index('PRICE_DATE')['PRICE_CLOSE'])
            else:
                st.info("No price data available")
        except Exception as e:
            st.warning(f"Error: {e}")

    with tab2:
        try:
            fin = get_financials(selected)
            if not fin.empty:
                st.dataframe(fin, hide_index=True)
            else:
                st.info("No financial data available")
        except Exception as e:
            st.warning(f"Error: {e}")

    with tab3:
        try:
            insiders = get_insider_trades(selected)
            if not insiders.empty:
                st.dataframe(insiders, hide_index=True)
            else:
                st.info("No insider trading data available")
        except Exception as e:
            st.warning(f"Error: {e}")

    with tab4:
        try:
            holders = get_holders(selected)
            if not holders.empty:
                st.dataframe(holders, hide_index=True)
            else:
                st.info("No institutional holdings data available")
        except Exception as e:
            st.warning(f"Error: {e}")

    # Agent link
    st.divider()
    account_url = f"https://{session.get_current_account()}.snowflakecomputing.com"
    st.link_button(
        f"Ask Research Agent about {selected}",
        f"{account_url}/intelligence/cowork?agent=ORBIT_DEMO.AI.ORBIT_RESEARCH_AGENT"
    )
