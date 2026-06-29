# ORBIT Research Hub — company deep-dive with searchable lookup and period comparisons
# Co-authored with CoCo
import streamlit as st
import pandas as pd

conn = st.session_state.conn


@st.cache_data(ttl=300)
def get_companies():
    return conn.query(
        "SELECT TICKER, COMPANY_NAME, GICS_SECTOR FROM ORBIT_DEMO.CURATED.DIM_ISSUER ORDER BY COMPANY_NAME"
    )


@st.cache_data(ttl=300)
def get_financials(ticker):
    return conn.query("""
        SELECT PERIOD_END_DATE, REVENUE, NET_INCOME, OPERATING_INCOME,
               EPS_BASIC, GROSS_MARGIN_PCT, OPERATING_MARGIN_PCT, NET_MARGIN_PCT,
               ROE_PCT, FREE_CASH_FLOW, DEBT_TO_EQUITY
        FROM ORBIT_DEMO.MARKET_DATA.FACT_SEC_FINANCIALS
        WHERE TICKER = :1 AND FISCAL_PERIOD = 'Q'
        ORDER BY PERIOD_END_DATE
        LIMIT 16
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
        LIMIT 25
    """, params=[ticker])


@st.cache_data(ttl=300)
def get_holders(ticker):
    return conn.query("""
        SELECT INSTITUTION_NAME, SHARES_HELD, MARKET_VALUE_USD, FILING_DATE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_INSTITUTIONAL_HOLDINGS
        WHERE TICKER = :1
        ORDER BY MARKET_VALUE_USD DESC
        LIMIT 20
    """, params=[ticker])


companies = get_companies()
search_options = [f"{row['TICKER']} — {row['COMPANY_NAME']}" for _, row in companies.iterrows()]

selected_option = st.selectbox(
    "Search company (name or ticker)",
    options=search_options,
    index=None,
    placeholder="Type to search...",
)

if selected_option:
    ticker = selected_option.split(" — ")[0]
    company_row = companies[companies['TICKER'] == ticker].iloc[0]

    with st.container(horizontal=True):
        st.metric("Company", company_row['COMPANY_NAME'], border=True)
        st.metric("Ticker", ticker, border=True)
        st.metric("Sector", company_row['GICS_SECTOR'], border=True)

    tab_price, tab_earnings, tab_margins, tab_insiders, tab_holders = st.tabs([
        "Stock price", "Earnings", "Margins", "Insider trades", "Top holders"
    ])

    with tab_price:
        try:
            prices = get_price_history(ticker)
            if not prices.empty:
                latest = prices.iloc[-1]['PRICE_CLOSE']
                first = prices.iloc[0]['PRICE_CLOSE']
                change_pct = ((latest - first) / first) * 100

                # Find QoQ and YoY price comparisons
                latest_date = pd.to_datetime(prices.iloc[-1]['PRICE_DATE'])
                q_ago_date = latest_date - pd.DateOffset(months=3)
                y_ago_date = latest_date - pd.DateOffset(years=1)

                prices_dt = prices.copy()
                prices_dt['PRICE_DATE'] = pd.to_datetime(prices_dt['PRICE_DATE'])

                q_ago_row = prices_dt[prices_dt['PRICE_DATE'] <= q_ago_date]
                y_ago_row = prices_dt[prices_dt['PRICE_DATE'] <= y_ago_date]
                price_q_ago = q_ago_row.iloc[-1]['PRICE_CLOSE'] if not q_ago_row.empty else None
                price_y_ago = y_ago_row.iloc[-1]['PRICE_CLOSE'] if not y_ago_row.empty else None

                qoq_pct = ((latest - price_q_ago) / price_q_ago * 100) if price_q_ago else None
                yoy_pct = ((latest - price_y_ago) / price_y_ago * 100) if price_y_ago else None

                with st.container(horizontal=True):
                    st.metric("Latest close", f"${latest:.2f}", f"{change_pct:+.1f}% (all)", border=True)
                    st.metric(
                        "3-month return",
                        f"${latest:.2f}",
                        f"{qoq_pct:+.1f}%" if qoq_pct is not None else "N/A",
                        border=True,
                    )
                    st.metric(
                        "1-year return",
                        f"${latest:.2f}",
                        f"{yoy_pct:+.1f}%" if yoy_pct is not None else "N/A",
                        border=True,
                    )

                with st.container(border=True):
                    st.markdown("**Price history**")
                    st.line_chart(prices, x="PRICE_DATE", y="PRICE_CLOSE")

                with st.container(border=True):
                    st.markdown("**Volume**")
                    st.bar_chart(prices, x="PRICE_DATE", y="VOLUME", height=200)
            else:
                st.info("No price data for this ticker")
        except Exception as e:
            st.warning(f"Error: {e}")

    with tab_earnings:
        try:
            fin = get_financials(ticker)
            if not fin.empty:
                # Comparison metrics: latest Q vs prior Q and same Q last year
                if len(fin) >= 2:
                    latest_q = fin.iloc[-1]
                    prev_q = fin.iloc[-2]
                    yoy_q = fin.iloc[-5] if len(fin) >= 5 else None

                    def pct_change(new, old):
                        if old and old != 0:
                            return ((new - old) / abs(old)) * 100
                        return None

                    rev_qoq = pct_change(latest_q['REVENUE'], prev_q['REVENUE'])
                    rev_yoy = pct_change(latest_q['REVENUE'], yoy_q['REVENUE']) if yoy_q is not None else None
                    ni_qoq = pct_change(latest_q['NET_INCOME'], prev_q['NET_INCOME'])
                    ni_yoy = pct_change(latest_q['NET_INCOME'], yoy_q['NET_INCOME']) if yoy_q is not None else None
                    eps_qoq = pct_change(latest_q['EPS_BASIC'], prev_q['EPS_BASIC'])
                    eps_yoy = pct_change(latest_q['EPS_BASIC'], yoy_q['EPS_BASIC']) if yoy_q is not None else None

                    st.markdown("**Quarter comparisons**")
                    comp_mode = st.radio(
                        "Compare", ["vs Last Quarter (QoQ)", "vs Same Quarter Last Year (YoY)"],
                        horizontal=True, key="earnings_comp"
                    )
                    is_yoy = "YoY" in comp_mode

                    with st.container(horizontal=True):
                        rev_delta = rev_yoy if is_yoy else rev_qoq
                        st.metric(
                            "Revenue", f"${latest_q['REVENUE']:,.0f}",
                            f"{rev_delta:+.1f}%" if rev_delta is not None else "N/A",
                            border=True,
                        )
                        ni_delta = ni_yoy if is_yoy else ni_qoq
                        st.metric(
                            "Net income", f"${latest_q['NET_INCOME']:,.0f}",
                            f"{ni_delta:+.1f}%" if ni_delta is not None else "N/A",
                            border=True,
                        )
                        eps_delta = eps_yoy if is_yoy else eps_qoq
                        st.metric(
                            "EPS", f"${latest_q['EPS_BASIC']:.2f}",
                            f"{eps_delta:+.1f}%" if eps_delta is not None else "N/A",
                            border=True,
                        )

                with st.container(border=True):
                    st.markdown("**Revenue and net income**")
                    st.line_chart(fin, x="PERIOD_END_DATE", y=["REVENUE", "NET_INCOME"])

                with st.container(border=True):
                    st.markdown("**EPS (basic)**")
                    st.bar_chart(fin, x="PERIOD_END_DATE", y="EPS_BASIC")

                with st.container(border=True):
                    st.markdown("**Detail**")
                    st.dataframe(
                        fin,
                        column_config={
                            "PERIOD_END_DATE": st.column_config.DateColumn("Quarter"),
                            "REVENUE": st.column_config.NumberColumn("Revenue", format="$%,.0f"),
                            "NET_INCOME": st.column_config.NumberColumn("Net income", format="$%,.0f"),
                            "EPS_BASIC": st.column_config.NumberColumn("EPS", format="$%.2f"),
                            "FREE_CASH_FLOW": st.column_config.NumberColumn("FCF", format="$%,.0f"),
                        },
                        hide_index=True,
                        use_container_width=True,
                    )
            else:
                st.info("No earnings data")
        except Exception as e:
            st.warning(f"Error: {e}")

    with tab_margins:
        try:
            fin = get_financials(ticker)
            if not fin.empty:
                # Margin comparisons
                if len(fin) >= 2:
                    latest_q = fin.iloc[-1]
                    prev_q = fin.iloc[-2]
                    yoy_q = fin.iloc[-5] if len(fin) >= 5 else None

                    st.markdown("**Margin comparisons**")
                    margin_comp = st.radio(
                        "Compare", ["vs Last Quarter (QoQ)", "vs Same Quarter Last Year (YoY)"],
                        horizontal=True, key="margin_comp"
                    )
                    compare_q = yoy_q if "YoY" in margin_comp else prev_q

                    if compare_q is not None:
                        gross_delta = latest_q['GROSS_MARGIN_PCT'] - compare_q['GROSS_MARGIN_PCT']
                        op_delta = latest_q['OPERATING_MARGIN_PCT'] - compare_q['OPERATING_MARGIN_PCT']
                        net_delta = latest_q['NET_MARGIN_PCT'] - compare_q['NET_MARGIN_PCT']
                        roe_delta = latest_q['ROE_PCT'] - compare_q['ROE_PCT']

                        with st.container(horizontal=True):
                            st.metric("Gross", f"{latest_q['GROSS_MARGIN_PCT']:.1f}%", f"{gross_delta:+.1f}pp", border=True)
                            st.metric("Operating", f"{latest_q['OPERATING_MARGIN_PCT']:.1f}%", f"{op_delta:+.1f}pp", border=True)
                            st.metric("Net", f"{latest_q['NET_MARGIN_PCT']:.1f}%", f"{net_delta:+.1f}pp", border=True)
                            st.metric("ROE", f"{latest_q['ROE_PCT']:.1f}%", f"{roe_delta:+.1f}pp", border=True)
                    else:
                        with st.container(horizontal=True):
                            st.metric("Gross", f"{latest_q['GROSS_MARGIN_PCT']:.1f}%", border=True)
                            st.metric("Operating", f"{latest_q['OPERATING_MARGIN_PCT']:.1f}%", border=True)
                            st.metric("Net", f"{latest_q['NET_MARGIN_PCT']:.1f}%", border=True)
                            st.metric("ROE", f"{latest_q['ROE_PCT']:.1f}%", border=True)

                col1, col2 = st.columns(2)
                with col1:
                    with st.container(border=True):
                        st.markdown("**Profit margins (%)**")
                        st.line_chart(fin, x="PERIOD_END_DATE", y=["GROSS_MARGIN_PCT", "OPERATING_MARGIN_PCT", "NET_MARGIN_PCT"])
                with col2:
                    with st.container(border=True):
                        st.markdown("**Return on equity (%)**")
                        st.line_chart(fin, x="PERIOD_END_DATE", y="ROE_PCT")
            else:
                st.info("No margin data")
        except Exception as e:
            st.warning(f"Error: {e}")

    with tab_insiders:
        try:
            insiders = get_insider_trades(ticker)
            if not insiders.empty:
                buys = insiders[insiders['TRANSACTION_TYPE'].str.contains('Purchase|Buy|Acquisition', case=False, na=False)]
                sells = insiders[insiders['TRANSACTION_TYPE'].str.contains('Sale|Sell|Disposition', case=False, na=False)]
                with st.container(horizontal=True):
                    st.metric("Buy transactions", len(buys), border=True)
                    st.metric("Sell transactions", len(sells), border=True)
                    buy_shares = int(buys['TRANSACTION_SHARES'].sum()) if not buys.empty else 0
                    sell_shares = int(sells['TRANSACTION_SHARES'].sum()) if not sells.empty else 0
                    st.metric("Net shares", f"{buy_shares - sell_shares:+,.0f}", border=True)

                st.dataframe(
                    insiders,
                    column_config={
                        "TRANSACTION_DATE": st.column_config.DateColumn("Date"),
                        "ISSUER_NAME": "Name",
                        "TRANSACTION_TYPE": "Type",
                        "TRANSACTION_SHARES": st.column_config.NumberColumn("Shares", format="%,.0f"),
                        "TRANSACTION_PRICE_PER_SHARE": st.column_config.NumberColumn("Price", format="$%.2f"),
                        "OWNERSHIP": "Ownership",
                    },
                    hide_index=True,
                    use_container_width=True,
                )
            else:
                st.info("No insider trading data")
        except Exception as e:
            st.warning(f"Error: {e}")

    with tab_holders:
        try:
            holders = get_holders(ticker)
            if not holders.empty:
                total_value = holders['MARKET_VALUE_USD'].sum()
                st.metric("Total institutional value", f"${total_value/1e9:.1f}B", border=True)
                st.dataframe(
                    holders,
                    column_config={
                        "INSTITUTION_NAME": "Institution",
                        "SHARES_HELD": st.column_config.NumberColumn("Shares", format="%,.0f"),
                        "MARKET_VALUE_USD": st.column_config.NumberColumn("Market value", format="$%,.0f"),
                        "FILING_DATE": st.column_config.DateColumn("Filed"),
                    },
                    hide_index=True,
                    use_container_width=True,
                )
            else:
                st.info("No holdings data")
        except Exception as e:
            st.warning(f"Error: {e}")
else:
    st.info("Search for a company above to begin your deep-dive analysis.")
