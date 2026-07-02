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
def get_annual_financials(ticker):
    return conn.query("""
        SELECT PERIOD_END_DATE, REVENUE, NET_INCOME, OPERATING_INCOME,
               EPS_BASIC, GROSS_MARGIN_PCT, OPERATING_MARGIN_PCT, NET_MARGIN_PCT,
               ROE_PCT, FREE_CASH_FLOW, DEBT_TO_EQUITY
        FROM ORBIT_DEMO.MARKET_DATA.FACT_SEC_FINANCIALS
        WHERE TICKER = :1 AND FISCAL_PERIOD = 'FY'
        ORDER BY PERIOD_END_DATE
        LIMIT 5
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


@st.cache_data(ttl=600)
def get_transcript_sentiment(ticker):
    return conn.query("""
        SELECT EVENT_DATE, EVENT_TYPE, FISCAL_YEAR, FISCAL_PERIOD,
               SNOWFLAKE.CORTEX.SENTIMENT(LEFT(DOCUMENT_TEXT, 10000)) AS SENTIMENT_SCORE,
               TEXT_LENGTH
        FROM ORBIT_DEMO.RAW.EARNINGS_TRANSCRIPTS_CORPUS
        WHERE TICKER = :1
        ORDER BY EVENT_DATE DESC
        LIMIT 12
    """, params=[ticker])


@st.cache_data(ttl=600)
def get_earnings_transcripts(ticker):
    return conn.query("""
        SELECT EVENT_TITLE, EVENT_TYPE, EVENT_TIMESTAMP, FISCAL_PERIOD, FISCAL_YEAR,
               TRANSCRIPT, TRANSCRIPT_TYPE
        FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_EVENT_TRANSCRIPT_ATTRIBUTES
        WHERE UPPER(PRIMARY_TICKER) = UPPER(:1)
          AND TRANSCRIPT_TYPE = 'SPEAKERS_ANNOTATED'
        ORDER BY EVENT_TIMESTAMP DESC
        LIMIT 12
    """, params=[ticker])


@st.cache_data(ttl=300)
def resolve_cik(ticker):
    result = conn.query("""
        SELECT CIK FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_INDEX
        WHERE UPPER(PRIMARY_TICKER) = UPPER(:1) LIMIT 1
    """, params=[ticker])
    if not result.empty:
        return result.iloc[0]["CIK"]
    return None


@st.cache_data(ttl=300)
def get_filing_summary(cik):
    return conn.query("""
        SELECT FORM_TYPE, COUNT(*) AS CNT
        FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_REPORT_INDEX
        WHERE CIK = :1 GROUP BY FORM_TYPE ORDER BY CNT DESC LIMIT 8
    """, params=[cik])


@st.cache_data(ttl=300)
def get_sec_segments(cik):
    return conn.query("""
        SELECT PERIOD_END_DATE, VARIABLE_NAME, VALUE, BUSINESS_SEGMENT, UNIT
        FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_METRICS_TIMESERIES
        WHERE CIK = :1 AND VALUE IS NOT NULL ORDER BY PERIOD_END_DATE DESC LIMIT 500
    """, params=[cik])


@st.cache_data(ttl=300)
def get_sec_xbrl(cik):
    return conn.query("""
        SELECT TAG, VALUE, UNIT_OF_MEASURE, PERIOD_END_DATE, STATEMENT, MEASURE_DESCRIPTION
        FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_REPORT_ATTRIBUTES
        WHERE CIK = :1 AND STATEMENT IN ('BS','IS','CF')
        ORDER BY PERIOD_END_DATE DESC LIMIT 500
    """, params=[cik])


@st.cache_data(ttl=300)
def get_sec_sections(cik):
    return conn.query("""
        SELECT ITEM_TITLE, FORM_TYPE, FILED_DATE, LEFT(PLAINTEXT_CONTENT, 1500) AS PREVIEW
        FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_ITEM_ATTRIBUTES
        WHERE CIK = :1 ORDER BY FILED_DATE DESC LIMIT 20
    """, params=[cik])


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

    tab_price, tab_earnings, tab_margins, tab_insiders, tab_holders, tab_transcripts, tab_filings = st.tabs([
        "Stock price", "Earnings", "Margins", "Insider trades", "Top holders", "Earnings transcripts", "SEC filings"
    ])

    with tab_price:
        try:
            prices = get_price_history(ticker)
            if not prices.empty:
                prices_dt = prices.copy()
                prices_dt['PRICE_DATE'] = pd.to_datetime(prices_dt['PRICE_DATE'])

                latest = prices_dt.iloc[-1]['PRICE_CLOSE']
                latest_date = prices_dt.iloc[-1]['PRICE_DATE']

                # Daily change (last two trading days)
                if len(prices_dt) >= 2:
                    prev_close = prices_dt.iloc[-2]['PRICE_CLOSE']
                    daily_chg = latest - prev_close
                    daily_pct = (daily_chg / prev_close) * 100
                else:
                    daily_chg = None
                    daily_pct = None

                # Period returns
                w_ago = latest_date - pd.DateOffset(weeks=1)
                m_ago = latest_date - pd.DateOffset(months=1)
                q_ago = latest_date - pd.DateOffset(months=3)
                y_ago = latest_date - pd.DateOffset(years=1)

                def get_price_at(target_date):
                    rows = prices_dt[prices_dt['PRICE_DATE'] <= target_date]
                    return rows.iloc[-1]['PRICE_CLOSE'] if not rows.empty else None

                price_1w = get_price_at(w_ago)
                price_1m = get_price_at(m_ago)
                price_3m = get_price_at(q_ago)
                price_1y = get_price_at(y_ago)

                def calc_return(current, past):
                    if past and past != 0:
                        return ((current - past) / past) * 100
                    return None

                ret_1w = calc_return(latest, price_1w)
                ret_1m = calc_return(latest, price_1m)
                ret_3m = calc_return(latest, price_3m)
                ret_1y = calc_return(latest, price_1y)

                # 52-week high/low
                one_year_prices = prices_dt[prices_dt['PRICE_DATE'] > y_ago]
                if not one_year_prices.empty:
                    high_52w = one_year_prices['PRICE_CLOSE'].max()
                    low_52w = one_year_prices['PRICE_CLOSE'].min()
                    pct_from_high = ((latest - high_52w) / high_52w) * 100
                else:
                    high_52w = low_52w = pct_from_high = None

                # Header: Latest price with daily change
                with st.container(horizontal=True):
                    st.metric(
                        "Latest close",
                        f"${latest:.2f}",
                        f"{daily_chg:+.2f} ({daily_pct:+.1f}%) today" if daily_pct is not None else None,
                        border=True,
                    )
                    if high_52w is not None:
                        st.metric("52-week high", f"${high_52w:.2f}", f"{pct_from_high:+.1f}% from high", border=True)
                        st.metric("52-week low", f"${low_52w:.2f}", border=True)

                # Returns across time periods
                st.markdown("**Performance**")
                with st.container(horizontal=True):
                    st.metric("1 week", f"{ret_1w:+.1f}%" if ret_1w is not None else "N/A", border=True)
                    st.metric("1 month", f"{ret_1m:+.1f}%" if ret_1m is not None else "N/A", border=True)
                    st.metric("3 months", f"{ret_3m:+.1f}%" if ret_3m is not None else "N/A", border=True)
                    st.metric("1 year", f"{ret_1y:+.1f}%" if ret_1y is not None else "N/A", border=True)

                # Volume summary
                avg_vol_30d = prices_dt.tail(22)['VOLUME'].mean() if len(prices_dt) >= 22 else prices_dt['VOLUME'].mean()
                latest_vol = prices_dt.iloc[-1]['VOLUME']
                vol_vs_avg = ((latest_vol - avg_vol_30d) / avg_vol_30d) * 100 if avg_vol_30d else None

                with st.container(horizontal=True):
                    st.metric("Latest volume", f"{latest_vol:,.0f}", f"{vol_vs_avg:+.0f}% vs 30d avg" if vol_vs_avg is not None else None, border=True)
                    st.metric("30-day avg volume", f"{avg_vol_30d:,.0f}", border=True)

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
            annual = get_annual_financials(ticker)

            period_view = st.radio(
                "Period", ["Quarterly", "YTD", "Annual"],
                horizontal=True, key="earnings_period"
            )

            if period_view == "Annual":
                data = annual
                period_label = "Year"
            elif period_view == "YTD":
                if not fin.empty:
                    fin_copy = fin.copy()
                    fin_copy['PERIOD_END_DATE'] = pd.to_datetime(fin_copy['PERIOD_END_DATE'])
                    fin_copy['YEAR'] = fin_copy['PERIOD_END_DATE'].dt.year
                    ytd = fin_copy.groupby('YEAR').agg(
                        PERIOD_END_DATE=('PERIOD_END_DATE', 'max'),
                        REVENUE=('REVENUE', 'sum'),
                        NET_INCOME=('NET_INCOME', 'sum'),
                        OPERATING_INCOME=('OPERATING_INCOME', 'sum'),
                        EPS_BASIC=('EPS_BASIC', 'sum'),
                        FREE_CASH_FLOW=('FREE_CASH_FLOW', 'sum'),
                        GROSS_MARGIN_PCT=('GROSS_MARGIN_PCT', 'mean'),
                        OPERATING_MARGIN_PCT=('OPERATING_MARGIN_PCT', 'mean'),
                        NET_MARGIN_PCT=('NET_MARGIN_PCT', 'mean'),
                        ROE_PCT=('ROE_PCT', 'mean'),
                    ).reset_index(drop=True).sort_values('PERIOD_END_DATE')
                    data = ytd
                else:
                    data = pd.DataFrame()
                period_label = "YTD"
            else:
                data = fin
                period_label = "Quarter"

            if not data.empty:
                # Comparison metrics
                if len(data) >= 2:
                    latest_q = data.iloc[-1]
                    prev_q = data.iloc[-2]

                    # For YoY: find same quarter from prior year by matching month
                    yoy_q = None
                    if period_view == "Quarterly" and len(data) >= 3:
                        latest_date = pd.to_datetime(latest_q['PERIOD_END_DATE'])
                        target_year = latest_date.year - 1
                        target_month = latest_date.month
                        data_dt = data.copy()
                        data_dt['_DATE'] = pd.to_datetime(data_dt['PERIOD_END_DATE'])
                        # Find closest quarter in the prior year (within 45 days of same month)
                        prior_year = data_dt[data_dt['_DATE'].dt.year == target_year]
                        if not prior_year.empty:
                            # Match closest month
                            prior_year = prior_year.copy()
                            prior_year['_month_diff'] = abs(prior_year['_DATE'].dt.month - target_month)
                            best_match = prior_year.loc[prior_year['_month_diff'].idxmin()]
                            yoy_q = best_match
                        data_dt.drop(columns=['_DATE'], inplace=True)

                    def pct_change(new_val, old_val):
                        try:
                            new_f = float(new_val)
                            old_f = float(old_val)
                            if pd.isna(new_f) or pd.isna(old_f) or old_f == 0:
                                return None
                            return ((new_f - old_f) / abs(old_f)) * 100
                        except (TypeError, ValueError):
                            return None

                    if period_view == "Quarterly":
                        comp_mode = st.radio(
                            "Compare", ["vs Last Quarter (QoQ)", "vs Same Quarter Last Year (YoY)"],
                            horizontal=True, key="earnings_comp"
                        )
                        compare_to = yoy_q if "YoY" in comp_mode else prev_q
                        comp_label = "YoY" if "YoY" in comp_mode else "QoQ"
                    else:
                        compare_to = prev_q
                        comp_label = "vs Prior Year"

                    if compare_to is not None:
                        rev_delta = pct_change(latest_q['REVENUE'], compare_to['REVENUE'])
                        ni_delta = pct_change(latest_q['NET_INCOME'], compare_to['NET_INCOME'])
                        eps_delta = pct_change(latest_q['EPS_BASIC'], compare_to['EPS_BASIC'])

                        def fmt_dollar(val, decimals=0):
                            try:
                                f = float(val)
                                if pd.isna(f):
                                    return "N/A"
                                if decimals == 0:
                                    return f"${f:,.0f}"
                                return f"${f:.{decimals}f}"
                            except (TypeError, ValueError):
                                return "N/A"

                        with st.container(horizontal=True):
                            st.metric(
                                "Revenue", fmt_dollar(latest_q['REVENUE']),
                                f"{rev_delta:+.1f}% {comp_label}" if rev_delta is not None else None,
                                border=True,
                            )
                            st.metric(
                                "Net income", fmt_dollar(latest_q['NET_INCOME']),
                                f"{ni_delta:+.1f}% {comp_label}" if ni_delta is not None else None,
                                border=True,
                            )
                            st.metric(
                                "EPS", fmt_dollar(latest_q['EPS_BASIC'], 2),
                                f"{eps_delta:+.1f}% {comp_label}" if eps_delta is not None else None,
                                border=True,
                            )

                with st.container(border=True):
                    st.markdown(f"**Revenue and net income ({period_label})**")
                    st.line_chart(data, x="PERIOD_END_DATE", y=["REVENUE", "NET_INCOME"])

                with st.container(border=True):
                    st.markdown(f"**EPS ({period_label})**")
                    st.bar_chart(data, x="PERIOD_END_DATE", y="EPS_BASIC")

                with st.container(border=True):
                    st.markdown(f"**Detail ({period_label})**")
                    st.dataframe(
                        data,
                        column_config={
                            "PERIOD_END_DATE": st.column_config.DateColumn(period_label),
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
            annual = get_annual_financials(ticker)

            margin_period = st.radio(
                "Period", ["Quarterly", "YTD", "Annual"],
                horizontal=True, key="margin_period"
            )

            if margin_period == "Annual":
                mdata = annual
            elif margin_period == "YTD":
                if not fin.empty:
                    fin_copy = fin.copy()
                    fin_copy['PERIOD_END_DATE'] = pd.to_datetime(fin_copy['PERIOD_END_DATE'])
                    fin_copy['YEAR'] = fin_copy['PERIOD_END_DATE'].dt.year
                    mdata = fin_copy.groupby('YEAR').agg(
                        PERIOD_END_DATE=('PERIOD_END_DATE', 'max'),
                        GROSS_MARGIN_PCT=('GROSS_MARGIN_PCT', 'mean'),
                        OPERATING_MARGIN_PCT=('OPERATING_MARGIN_PCT', 'mean'),
                        NET_MARGIN_PCT=('NET_MARGIN_PCT', 'mean'),
                        ROE_PCT=('ROE_PCT', 'mean'),
                    ).reset_index(drop=True).sort_values('PERIOD_END_DATE')
                else:
                    mdata = pd.DataFrame()
            else:
                mdata = fin

            if not mdata.empty:
                if len(mdata) >= 2:
                    latest_q = mdata.iloc[-1]
                    prev_q = mdata.iloc[-2]

                    # For YoY: find same quarter from prior year by matching month
                    yoy_q = None
                    if margin_period == "Quarterly" and len(mdata) >= 3:
                        latest_date = pd.to_datetime(latest_q['PERIOD_END_DATE'])
                        target_year = latest_date.year - 1
                        target_month = latest_date.month
                        mdata_dt = mdata.copy()
                        mdata_dt['_DATE'] = pd.to_datetime(mdata_dt['PERIOD_END_DATE'])
                        prior_year = mdata_dt[mdata_dt['_DATE'].dt.year == target_year]
                        if not prior_year.empty:
                            prior_year = prior_year.copy()
                            prior_year['_month_diff'] = abs(prior_year['_DATE'].dt.month - target_month)
                            best_match = prior_year.loc[prior_year['_month_diff'].idxmin()]
                            yoy_q = best_match

                    if margin_period == "Quarterly":
                        margin_comp = st.radio(
                            "Compare", ["vs Last Quarter (QoQ)", "vs Same Quarter Last Year (YoY)"],
                            horizontal=True, key="margin_comp"
                        )
                        compare_q = yoy_q if "YoY" in margin_comp else prev_q
                    else:
                        compare_q = prev_q

                    if compare_q is not None:
                        def safe_delta(a, b):
                            try:
                                fa, fb = float(a), float(b)
                                if pd.isna(fa) or pd.isna(fb):
                                    return None
                                return fa - fb
                            except (TypeError, ValueError):
                                return None

                        gross_delta = safe_delta(latest_q['GROSS_MARGIN_PCT'], compare_q['GROSS_MARGIN_PCT'])
                        op_delta = safe_delta(latest_q['OPERATING_MARGIN_PCT'], compare_q['OPERATING_MARGIN_PCT'])
                        net_delta = safe_delta(latest_q['NET_MARGIN_PCT'], compare_q['NET_MARGIN_PCT'])
                        roe_delta = safe_delta(latest_q['ROE_PCT'], compare_q['ROE_PCT'])

                        with st.container(horizontal=True):
                            st.metric("Gross", f"{float(latest_q['GROSS_MARGIN_PCT']):.1f}%", f"{gross_delta:+.1f}pp" if gross_delta is not None else None, border=True)
                            st.metric("Operating", f"{float(latest_q['OPERATING_MARGIN_PCT']):.1f}%", f"{op_delta:+.1f}pp" if op_delta is not None else None, border=True)
                            st.metric("Net", f"{float(latest_q['NET_MARGIN_PCT']):.1f}%", f"{net_delta:+.1f}pp" if net_delta is not None else None, border=True)
                            st.metric("ROE", f"{float(latest_q['ROE_PCT']):.1f}%", f"{roe_delta:+.1f}pp" if roe_delta is not None else None, border=True)
                    else:
                        with st.container(horizontal=True):
                            st.metric("Gross", f"{float(latest_q['GROSS_MARGIN_PCT']):.1f}%", border=True)
                            st.metric("Operating", f"{float(latest_q['OPERATING_MARGIN_PCT']):.1f}%", border=True)
                            st.metric("Net", f"{float(latest_q['NET_MARGIN_PCT']):.1f}%", border=True)
                            st.metric("ROE", f"{float(latest_q['ROE_PCT']):.1f}%", border=True)

                col1, col2 = st.columns(2)
                with col1:
                    with st.container(border=True):
                        st.markdown("**Profit margins (%)**")
                        st.line_chart(mdata, x="PERIOD_END_DATE", y=["GROSS_MARGIN_PCT", "OPERATING_MARGIN_PCT", "NET_MARGIN_PCT"])
                with col2:
                    with st.container(border=True):
                        st.markdown("**Return on equity (%)**")
                        st.line_chart(mdata, x="PERIOD_END_DATE", y="ROE_PCT")
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

    with tab_transcripts:
        try:
            transcripts = get_earnings_transcripts(ticker)
            if not transcripts.empty:
                # Event selector
                event_options = []
                for i, row in transcripts.iterrows():
                    label = f"{row['EVENT_TYPE']} — {row['FISCAL_PERIOD']} {row['FISCAL_YEAR']} ({str(row['EVENT_TIMESTAMP'])[:10]})"
                    event_options.append(label)

                selected_idx = st.selectbox(
                    "Earnings call", range(len(event_options)),
                    format_func=lambda i: event_options[i],
                    label_visibility="collapsed",
                )

                if selected_idx is not None:
                    selected_row = transcripts.iloc[selected_idx]
                    transcript_json = selected_row["TRANSCRIPT"]

                    # Parse the VARIANT/JSON transcript
                    import json
                    if isinstance(transcript_json, str):
                        transcript_data = json.loads(transcript_json)
                    else:
                        transcript_data = transcript_json

                    # Extract speakers and their text
                    # Structure: {paragraphs: [{speaker: int, text: str}], speaker_mapping: [{speaker: int, speaker_data: {name, role, company}}]}
                    speakers = []
                    speaker_map = {}

                    if isinstance(transcript_data, dict):
                        # Build speaker lookup from speaker_mapping
                        raw_mapping = transcript_data.get("speaker_mapping", [])
                        if isinstance(raw_mapping, list):
                            for entry in raw_mapping:
                                sid = entry.get("speaker")
                                sdata = entry.get("speaker_data", {})
                                speaker_map[sid] = {
                                    "name": sdata.get("name", f"Speaker {sid}"),
                                    "role": sdata.get("role", ""),
                                    "company": sdata.get("company", ""),
                                }

                        # Extract paragraphs
                        paragraphs = transcript_data.get("paragraphs", [])
                        if isinstance(paragraphs, list):
                            for para in paragraphs:
                                sid = para.get("speaker")
                                text = para.get("text", "")
                                if text:
                                    info = speaker_map.get(sid, {"name": f"Speaker {sid}", "role": "", "company": ""})
                                    title = info["role"]
                                    if info["company"]:
                                        title = f"{info['company']} — {title}" if title else info["company"]
                                    speakers.append({"speaker": info["name"], "title": title, "text": text})

                    elif isinstance(transcript_data, list):
                        # Fallback: flat list of segments
                        for segment in transcript_data:
                            speaker = segment.get("speaker", segment.get("name", "Unknown"))
                            text = segment.get("text", segment.get("content", ""))
                            title = segment.get("title", segment.get("role", ""))
                            if text:
                                speakers.append({"speaker": str(speaker), "title": title, "text": text})

                    if speakers:
                        # Summary metrics
                        unique_speakers = list({s["speaker"] for s in speakers})
                        with st.container(horizontal=True):
                            st.metric("Speakers", len(unique_speakers), border=True)
                            st.metric("Segments", len(speakers), border=True)
                            st.metric("Event", selected_row["EVENT_TYPE"], border=True)

                        # Speaker sentiment analysis
                        st.markdown("**Speaker sentiment**")
                        speaker_texts = {}
                        for s in speakers:
                            if s["speaker"] not in speaker_texts:
                                speaker_texts[s["speaker"]] = ""
                            speaker_texts[s["speaker"]] += " " + s["text"]

                        # Score top speakers (limit to first 5 unique speakers for performance)
                        scored_speakers = []
                        for speaker_name in unique_speakers[:5]:
                            combined_text = speaker_texts[speaker_name][:10000]
                            try:
                                score_result = conn.query(
                                    "SELECT SNOWFLAKE.CORTEX.SENTIMENT(:1) AS SCORE",
                                    params=[combined_text]
                                )
                                score = float(score_result.iloc[0]["SCORE"])
                            except Exception:
                                score = None
                            scored_speakers.append({
                                "Speaker": speaker_name,
                                "Sentiment": score,
                                "Segments": sum(1 for s in speakers if s["speaker"] == speaker_name),
                            })

                        if scored_speakers:
                            import pandas as pd_local
                            score_df = pd_local.DataFrame(scored_speakers)
                            score_df = score_df.sort_values("Sentiment", ascending=False)
                            with st.container(border=True):
                                st.dataframe(
                                    score_df,
                                    column_config={
                                        "Speaker": "Speaker",
                                        "Sentiment": st.column_config.NumberColumn("Sentiment", format="%.3f"),
                                        "Segments": st.column_config.NumberColumn("Segments"),
                                    },
                                    hide_index=True,
                                    use_container_width=True,
                                )

                        # Full transcript with speaker annotations
                        st.markdown("**Transcript**")
                        speaker_filter = st.selectbox(
                            "Filter by speaker", ["All"] + unique_speakers,
                            label_visibility="collapsed", key="speaker_filter"
                        )

                        with st.container(border=True, height=500):
                            for segment in speakers:
                                if speaker_filter != "All" and segment["speaker"] != speaker_filter:
                                    continue
                                title_str = f" ({segment['title']})" if segment["title"] else ""
                                st.markdown(f"**{segment['speaker']}{title_str}**")
                                st.text(segment["text"][:2000])
                                st.markdown("---")
                    else:
                        st.warning("Could not parse transcript structure.")
            else:
                # Fallback: use corpus-based sentiment if no speaker-annotated transcripts available
                sentiment = get_transcript_sentiment(ticker)
                if not sentiment.empty:
                    st.caption("Speaker-annotated transcripts not available. Showing sentiment trend from corpus.")
                    latest_score = sentiment.iloc[0]['SENTIMENT_SCORE']
                    avg_score = sentiment['SENTIMENT_SCORE'].mean()

                    def sentiment_label(score):
                        if score >= 0.3:
                            return "Positive"
                        elif score >= 0.1:
                            return "Slightly positive"
                        elif score >= -0.1:
                            return "Neutral"
                        elif score >= -0.3:
                            return "Slightly negative"
                        else:
                            return "Negative"

                    with st.container(horizontal=True):
                        st.metric("Latest call sentiment", sentiment_label(latest_score), f"{latest_score:+.3f}", border=True)
                        st.metric("Average sentiment", sentiment_label(avg_score), f"{avg_score:+.3f}", border=True)
                        st.metric("Transcripts analysed", len(sentiment), border=True)

                    with st.container(border=True):
                        st.markdown("**Earnings call sentiment trend**")
                        chart_data = sentiment.sort_values('EVENT_DATE')
                        st.line_chart(chart_data, x="EVENT_DATE", y="SENTIMENT_SCORE")
                else:
                    st.info("No earnings transcripts available for this company.")
        except Exception as e:
            st.warning(f"Transcript analysis unavailable: {e}")

    with tab_filings:
        try:
            cik = resolve_cik(ticker)
            if not cik:
                st.warning("Could not resolve CIK for this ticker. SEC filings require a CIK mapping.")
                st.stop()

            summary = get_filing_summary(cik)
            if not summary.empty:
                with st.expander("Filing types available"):
                    st.dataframe(summary, use_container_width=True, hide_index=True, height=180)

            sub1, sub2, sub3 = st.tabs(["Segments", "XBRL", "Sections"])

            with sub1:
                rev_df = get_sec_segments(cik)
                if not rev_df.empty:
                    variables = rev_df["VARIABLE_NAME"].dropna().unique().tolist()
                    selected_var = st.selectbox("Metric", variables, label_visibility="collapsed", key="seg_var")
                    filtered = rev_df[rev_df["VARIABLE_NAME"] == selected_var] if selected_var else rev_df

                    if not filtered.empty:
                        segments = filtered["BUSINESS_SEGMENT"].dropna().unique().tolist()
                        with st.container(border=True):
                            if segments:
                                chart = filtered[filtered["BUSINESS_SEGMENT"].notna()].pivot_table(
                                    index="PERIOD_END_DATE", columns="BUSINESS_SEGMENT", values="VALUE", aggfunc="sum")
                                st.line_chart(chart, height=300)
                            else:
                                st.line_chart(filtered.set_index("PERIOD_END_DATE")["VALUE"], height=300)
                        with st.expander("Data"):
                            st.dataframe(filtered, use_container_width=True, hide_index=True)
                else:
                    st.warning("No segment data. Foreign issuers may lack structured XBRL.")

            with sub2:
                xbrl_df = get_sec_xbrl(cik)
                if not xbrl_df.empty:
                    stmt_filter = st.selectbox("Statement", ["All", "BS", "IS", "CF"], label_visibility="collapsed", key="xbrl_stmt")
                    if stmt_filter != "All":
                        xbrl_df = xbrl_df[xbrl_df["STATEMENT"] == stmt_filter]

                    with st.container(border=True):
                        st.caption("TOP TAGS")
                        tags = xbrl_df["TAG"].value_counts().head(10).reset_index()
                        tags.columns = ["TAG", "COUNT"]
                        st.bar_chart(tags, x="TAG", y="COUNT", height=200)

                    with st.expander("Full table"):
                        st.dataframe(xbrl_df, use_container_width=True, hide_index=True)
                else:
                    st.warning("No XBRL data. Try Sections tab.")

            with sub3:
                items_df = get_sec_sections(cik)
                if not items_df.empty:
                    sel_item = st.selectbox("Section", items_df.index.tolist(),
                        format_func=lambda i: f"{items_df.iloc[i]['FORM_TYPE']} — {items_df.iloc[i]['ITEM_TITLE']}  ({items_df.iloc[i]['FILED_DATE']})",
                        label_visibility="collapsed", key="sec_section")
                    if sel_item is not None:
                        row = items_df.iloc[sel_item]
                        with st.container(border=True):
                            st.caption(f"{row['FORM_TYPE']} • {row['FILED_DATE']}")
                            st.markdown(f"**{row['ITEM_TITLE']}**")
                            st.text_area("", value=row["PREVIEW"] or "—", height=350, disabled=True, label_visibility="collapsed")
                else:
                    st.info("No parsed sections available.")
        except Exception as e:
            st.warning(f"SEC filings unavailable: {e}")
else:
    st.info("Search for a company above to begin your deep-dive analysis.")
