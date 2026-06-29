"""ORBIT — Portfolio Page"""
import streamlit as st

st.set_page_config(page_title="ORBIT | Portfolio", layout="wide")
st.title("Portfolio Analytics")

from snowflake.snowpark.context import get_active_session
session = get_active_session()


@st.cache_data(ttl=300)
def get_portfolios():
    return session.sql(
        "SELECT PORTFOLIO_ID, PORTFOLIO_NAME, STRATEGY, BENCHMARK_NAME, AUM_USD "
        "FROM ORBIT_DEMO.CURATED.DIM_PORTFOLIO ORDER BY PORTFOLIO_ID"
    ).to_pandas()


@st.cache_data(ttl=300)
def get_holdings(portfolio_id):
    return session.sql(f"""
        SELECT p.TICKER, i.COMPANY_NAME, i.GICS_SECTOR,
               p.WEIGHT, p.SHARES, p.CURRENT_PRICE, p.POSITION_VALUE_USD
        FROM ORBIT_DEMO.CURATED.FACT_POSITION_DAILY p
        JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON p.ISSUER_ID = i.ISSUER_ID
        WHERE p.PORTFOLIO_ID = {portfolio_id}
        ORDER BY p.WEIGHT DESC
    """).to_pandas()


@st.cache_data(ttl=300)
def get_sector_allocation(portfolio_id):
    return session.sql(f"""
        SELECT i.GICS_SECTOR, SUM(p.WEIGHT) AS SECTOR_WEIGHT, COUNT(*) AS NUM_HOLDINGS
        FROM ORBIT_DEMO.CURATED.FACT_POSITION_DAILY p
        JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON p.ISSUER_ID = i.ISSUER_ID
        WHERE p.PORTFOLIO_ID = {portfolio_id}
        GROUP BY i.GICS_SECTOR
        ORDER BY SECTOR_WEIGHT DESC
    """).to_pandas()


# Portfolio selector
portfolios = get_portfolios()
selected_name = st.selectbox("Select Portfolio", portfolios['PORTFOLIO_NAME'].tolist())

if selected_name:
    portfolio_row = portfolios[portfolios['PORTFOLIO_NAME'] == selected_name].iloc[0]
    portfolio_id = portfolio_row['PORTFOLIO_ID']

    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Strategy", portfolio_row['STRATEGY'])
    with col2:
        st.metric("Benchmark", portfolio_row['BENCHMARK_NAME'])
    with col3:
        aum = portfolio_row['AUM_USD']
        st.metric("AUM", f"${aum/1e9:.1f}B")

    st.divider()

    col1, col2 = st.columns([2, 1])

    with col1:
        st.subheader("Holdings")
        try:
            holdings = get_holdings(portfolio_id)
            if not holdings.empty:
                st.dataframe(
                    holdings,
                    column_config={
                        "WEIGHT": st.column_config.ProgressColumn("Weight", min_value=0, max_value=0.15, format="%.1f%%"),
                        "POSITION_VALUE_USD": st.column_config.NumberColumn("Value (USD)", format="$%,.0f"),
                        "CURRENT_PRICE": st.column_config.NumberColumn("Price", format="$%.2f"),
                    },
                    hide_index=True
                )
            else:
                st.info("No position data available")
        except Exception as e:
            st.warning(f"Error: {e}")

    with col2:
        st.subheader("Sector Allocation")
        try:
            sectors = get_sector_allocation(portfolio_id)
            if not sectors.empty:
                st.bar_chart(sectors.set_index('GICS_SECTOR')['SECTOR_WEIGHT'])
            else:
                st.info("No allocation data")
        except Exception as e:
            st.warning(f"Error: {e}")

    # Agent link
    st.divider()
    account_url = f"https://{session.get_current_account()}.snowflakecomputing.com"
    st.link_button(
        "Ask Portfolio Agent",
        f"{account_url}/intelligence/cowork?agent=ORBIT_DEMO.AI.ORBIT_PORTFOLIO_AGENT"
    )
