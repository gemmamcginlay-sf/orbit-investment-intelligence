# ORBIT Portfolio — holdings, sector allocation, and summary
# Co-authored with CoCo
import streamlit as st

conn = st.session_state.conn


@st.cache_data(ttl=300)
def get_portfolios():
    return conn.query(
        "SELECT PORTFOLIO_ID, PORTFOLIO_NAME, STRATEGY, BENCHMARK_NAME, AUM_USD "
        "FROM ORBIT_DEMO.CURATED.DIM_PORTFOLIO ORDER BY PORTFOLIO_ID"
    )


@st.cache_data(ttl=300)
def get_holdings(portfolio_id):
    return conn.query("""
        SELECT p.TICKER, i.COMPANY_NAME, i.GICS_SECTOR,
               p.WEIGHT, p.SHARES, p.CURRENT_PRICE, p.POSITION_VALUE_USD
        FROM ORBIT_DEMO.CURATED.FACT_POSITION_DAILY p
        JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON p.ISSUER_ID = i.ISSUER_ID
        WHERE p.PORTFOLIO_ID = :1
        ORDER BY p.WEIGHT DESC
    """, params=[portfolio_id])


@st.cache_data(ttl=300)
def get_sector_allocation(portfolio_id):
    return conn.query("""
        SELECT i.GICS_SECTOR, SUM(p.WEIGHT) AS SECTOR_WEIGHT, COUNT(*) AS NUM_HOLDINGS
        FROM ORBIT_DEMO.CURATED.FACT_POSITION_DAILY p
        JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON p.ISSUER_ID = i.ISSUER_ID
        WHERE p.PORTFOLIO_ID = :1
        GROUP BY i.GICS_SECTOR
        ORDER BY SECTOR_WEIGHT DESC
    """, params=[portfolio_id])


@st.cache_data(ttl=300)
def get_holding_prices(portfolio_id):
    """Get recent price history for top holdings to show performance."""
    return conn.query("""
        SELECT sp.TICKER, sp.PRICE_DATE, sp.PRICE_CLOSE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES sp
        WHERE sp.TICKER IN (
            SELECT p.TICKER
            FROM ORBIT_DEMO.CURATED.FACT_POSITION_DAILY p
            WHERE p.PORTFOLIO_ID = :1
            ORDER BY p.WEIGHT DESC
            LIMIT 5
        )
        AND sp.PRICE_DATE >= DATEADD('month', -3, CURRENT_DATE())
        ORDER BY sp.TICKER, sp.PRICE_DATE
    """, params=[portfolio_id])


portfolios = get_portfolios()
selected_name = st.selectbox("Portfolio", portfolios['PORTFOLIO_NAME'].tolist())

if selected_name:
    portfolio_row = portfolios[portfolios['PORTFOLIO_NAME'] == selected_name].iloc[0]
    portfolio_id = int(portfolio_row['PORTFOLIO_ID'])
    aum = portfolio_row['AUM_USD']

    with st.container(horizontal=True):
        st.metric("Strategy", portfolio_row['STRATEGY'], border=True)
        st.metric("Benchmark", portfolio_row['BENCHMARK_NAME'], border=True)
        st.metric("AUM", f"${aum/1e9:.1f}B", border=True)

    tab_holdings, tab_sectors, tab_perf = st.tabs(["Holdings", "Sector allocation", "Top holdings performance"])

    with tab_holdings:
        with st.container(border=True):
            try:
                holdings = get_holdings(portfolio_id)
                if not holdings.empty:
                    st.metric("Positions", len(holdings), border=True)
                    st.dataframe(
                        holdings,
                        column_config={
                            "TICKER": "Ticker",
                            "COMPANY_NAME": "Company",
                            "GICS_SECTOR": "Sector",
                            "WEIGHT": st.column_config.ProgressColumn("Weight", min_value=0, max_value=holdings['WEIGHT'].max() * 1.2, format="%.2f%%"),
                            "SHARES": st.column_config.NumberColumn("Shares", format="%,.0f"),
                            "CURRENT_PRICE": st.column_config.NumberColumn("Price", format="$%.2f"),
                            "POSITION_VALUE_USD": st.column_config.NumberColumn("Value", format="$%,.0f"),
                        },
                        hide_index=True,
                        use_container_width=True,
                    )
                else:
                    st.info("No holdings data")
            except Exception as e:
                st.warning(f"Error: {e}")

    with tab_sectors:
        col1, col2 = st.columns(2)
        with col1:
            with st.container(border=True):
                st.markdown("**Sector weights**")
                try:
                    sectors = get_sector_allocation(portfolio_id)
                    if not sectors.empty:
                        st.bar_chart(sectors, x="GICS_SECTOR", y="SECTOR_WEIGHT", horizontal=True)
                    else:
                        st.info("No sector data")
                except Exception as e:
                    st.warning(f"Error: {e}")
        with col2:
            with st.container(border=True):
                st.markdown("**Sector detail**")
                try:
                    sectors = get_sector_allocation(portfolio_id)
                    if not sectors.empty:
                        st.dataframe(
                            sectors,
                            column_config={
                                "GICS_SECTOR": "Sector",
                                "SECTOR_WEIGHT": st.column_config.NumberColumn("Weight %", format="%.2f%%"),
                                "NUM_HOLDINGS": st.column_config.NumberColumn("Holdings"),
                            },
                            hide_index=True,
                            use_container_width=True,
                        )
                    else:
                        st.info("No sector data")
                except Exception as e:
                    st.warning(f"Error: {e}")

    with tab_perf:
        with st.container(border=True):
            st.markdown("**Top 5 holdings — 3-month price history**")
            try:
                perf = get_holding_prices(portfolio_id)
                if not perf.empty:
                    # Pivot to show each ticker as a column
                    pivot = perf.pivot_table(index="PRICE_DATE", columns="TICKER", values="PRICE_CLOSE").reset_index()
                    tickers = [c for c in pivot.columns if c != "PRICE_DATE"]
                    st.line_chart(pivot, x="PRICE_DATE", y=tickers)
                else:
                    st.info("No recent price data for holdings")
            except Exception as e:
                st.warning(f"Error: {e}")
