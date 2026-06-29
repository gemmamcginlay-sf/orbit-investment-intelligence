# ORBIT Research Hub — company deep-dive with financials, price, insiders, holders
# Co-authored with CoCo
import streamlit as st

conn = st.session_state.conn


@st.cache_data(ttl=300)
def get_companies():
    return conn.query(
        "SELECT TICKER, COMPANY_NAME, GICS_SECTOR FROM ORBIT_DEMO.CURATED.DIM_ISSUER ORDER BY COMPANY_NAME"
    )


@st.cache_data(ttl=300)
def get_financials(ticker):
    return conn.query("""
        SELECT PERIOD_END_DATE, REVENUE, NET_INCOME, EPS_BASIC,
               GROSS_MARGIN_PCT, OPERATING_MARGIN_PCT, NET_MARGIN_PCT,
               ROE_PCT, FREE_CASH_FLOW, DEBT_TO_EQUITY
        FROM ORBIT_DEMO.MARKET_DATA.FACT_SEC_FINANCIALS
        WHERE TICKER = :1 AND FISCAL_PERIOD = 'Q'
        ORDER BY PERIOD_END_DATE DESC
        LIMIT 12
    """, params=[ticker])


@st.cache_data(ttl=300)
def get_price_history(ticker):
    return conn.query("""
        SELECT PRICE_DATE, PRICE_CLOSE, VOLUME
        FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES
        WHERE TICKER = :1
        ORDER BY PRICE_DATE
    """, params=[ticker])


@st.cache_data(ttl=300)
def get_insider_trades(ticker):
    return conn.query("""
        SELECT TRANSACTION_DATE, ISSUER_NAME, TRANSACTION_TYPE,
               TRANSACTION_SHARES, TRANSACTION_PRICE_PER_SHARE, OWNERSHIP
        FROM ORBIT_DEMO.MARKET_DATA.FACT_INSIDER_TRANSACTIONS
        WHERE TICKER = :1
        ORDER BY TRANSACTION_DATE DESC
        LIMIT 20
    """, params=[ticker])


@st.cache_data(ttl=300)
def get_holders(ticker):
    return conn.query("""
        SELECT INSTITUTION_NAME, SHARES_HELD, MARKET_VALUE_USD, FILING_DATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_INSTITUTIONAL_HOLDINGS
        WHERE TICKER = :1
        ORDER BY MARKET_VALUE_USD DESC
        LIMIT 15
    """, params=[ticker])


companies = get_companies()
selected = st.selectbox(
    "Company",
    companies['TICKER'].tolist(),
    format_func=lambda t: f"{t} — {companies[companies['TICKER']==t]['COMPANY_NAME'].values[0]}"
)

if selected:
    company_name = companies[companies['TICKER'] == selected]['COMPANY_NAME'].values[0]
    sector = companies[companies['TICKER'] == selected]['GICS_SECTOR'].values[0]

    with st.container(horizontal=True):
        st.metric("Company", company_name, border=True)
        st.metric("Sector", sector, border=True)
        st.metric("Ticker", selected, border=True)

    tab1, tab2, tab3, tab4 = st.tabs(["Price history", "Quarterly financials", "Insider trades", "Top holders"])

    with tab1:
        try:
            prices = get_price_history(selected)
            if not prices.empty:
                with st.container(border=True):
                    st.markdown("**Closing price**")
                    st.area_chart(prices, x="PRICE_DATE", y="PRICE_CLOSE")
                with st.container(border=True):
                    st.markdown("**Volume**")
                    st.bar_chart(prices, x="PRICE_DATE", y="VOLUME")
            else:
                st.info("No price data available")
        except Exception as e:
            st.warning(f"Error loading prices: {e}")

    with tab2:
        try:
            fin = get_financials(selected)
            if not fin.empty:
                col1, col2 = st.columns(2)
                with col1:
                    with st.container(border=True):
                        st.markdown("**Revenue vs Net income**")
                        st.line_chart(fin, x="PERIOD_END_DATE", y=["REVENUE", "NET_INCOME"])
                with col2:
                    with st.container(border=True):
                        st.markdown("**Margins (%)**")
                        st.line_chart(fin, x="PERIOD_END_DATE", y=["GROSS_MARGIN_PCT", "OPERATING_MARGIN_PCT", "NET_MARGIN_PCT"])
                with st.container(border=True):
                    st.markdown("**Detail**")
                    st.dataframe(
                        fin,
                        column_config={
                            "PERIOD_END_DATE": st.column_config.DateColumn("Quarter end"),
                            "REVENUE": st.column_config.NumberColumn("Revenue", format="$%,.0f"),
                            "NET_INCOME": st.column_config.NumberColumn("Net income", format="$%,.0f"),
                            "EPS_BASIC": st.column_config.NumberColumn("EPS", format="$%.2f"),
                            "FREE_CASH_FLOW": st.column_config.NumberColumn("FCF", format="$%,.0f"),
                            "DEBT_TO_EQUITY": st.column_config.NumberColumn("D/E", format="%.2f"),
                        },
                        hide_index=True,
                        use_container_width=True,
                    )
            else:
                st.info("No financial data available")
        except Exception as e:
            st.warning(f"Error loading financials: {e}")

    with tab3:
        try:
            insiders = get_insider_trades(selected)
            if not insiders.empty:
                st.dataframe(
                    insiders,
                    column_config={
                        "TRANSACTION_DATE": st.column_config.DateColumn("Date"),
                        "TRANSACTION_TYPE": st.column_config.TextColumn("Type"),
                        "TRANSACTION_SHARES": st.column_config.NumberColumn("Shares", format="%,.0f"),
                        "TRANSACTION_PRICE_PER_SHARE": st.column_config.NumberColumn("Price", format="$%.2f"),
                        "OWNERSHIP": st.column_config.TextColumn("Ownership"),
                    },
                    hide_index=True,
                    use_container_width=True,
                )
            else:
                st.info("No insider trading data")
        except Exception as e:
            st.warning(f"Error loading insider data: {e}")

    with tab4:
        try:
            holders = get_holders(selected)
            if not holders.empty:
                st.dataframe(
                    holders,
                    column_config={
                        "INSTITUTION_NAME": st.column_config.TextColumn("Institution"),
                        "SHARES_HELD": st.column_config.NumberColumn("Shares", format="%,.0f"),
                        "MARKET_VALUE_USD": st.column_config.NumberColumn("Market value", format="$%,.0f"),
                        "FILING_DATE": st.column_config.DateColumn("Filing date"),
                    },
                    hide_index=True,
                    use_container_width=True,
                )
            else:
                st.info("No institutional holdings data")
        except Exception as e:
            st.warning(f"Error loading holders: {e}")
