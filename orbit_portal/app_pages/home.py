# ORBIT home page — executive dashboard with preview charts in navigation tiles
# Co-authored with CoCo
import streamlit as st
import altair as alt

conn = st.session_state.conn


@st.cache_data(ttl=300)
def get_kpis():
    try:
        securities = conn.query("SELECT COUNT(*) AS CNT FROM ORBIT_DEMO.CURATED.DIM_ISSUER").iloc[0, 0]
    except Exception:
        securities = 0
    try:
        latest_date = conn.query("SELECT MAX(PRICE_DATE)::VARCHAR AS DT FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES").iloc[0, 0]
    except Exception:
        latest_date = "—"
    try:
        filings = conn.query("SELECT COUNT(*) AS CNT FROM ORBIT_DEMO.RAW.SEC_FILING_TEXT").iloc[0, 0]
    except Exception:
        filings = 0
    try:
        transcripts = conn.query("SELECT COUNT(*) AS CNT FROM ORBIT_DEMO.RAW.EARNINGS_TRANSCRIPTS_CORPUS").iloc[0, 0]
    except Exception:
        transcripts = 0
    return securities, latest_date, filings, transcripts


@st.cache_data(ttl=300)
def get_yield_preview():
    return conn.query("""
        SELECT MATURITY_LABEL, YIELD_PCT, MATURITY_MONTHS
        FROM ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS
        WHERE DATE = (SELECT MAX(DATE) FROM ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS)
        ORDER BY MATURITY_MONTHS
        LIMIT 10
    """)


@st.cache_data(ttl=300)
def get_price_preview():
    return conn.query("""
        SELECT PRICE_DATE, PRICE_CLOSE
        FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES
        WHERE TICKER = 'AAPL'
        ORDER BY PRICE_DATE
        LIMIT 60
    """)


@st.cache_data(ttl=300)
def get_sector_preview():
    return conn.query("""
        SELECT i.GICS_SECTOR, SUM(p.WEIGHT) AS SECTOR_WEIGHT
        FROM ORBIT_DEMO.CURATED.FACT_POSITION_DAILY p
        JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON p.ISSUER_ID = i.ISSUER_ID
        WHERE p.PORTFOLIO_ID = 1
        GROUP BY i.GICS_SECTOR
        ORDER BY SECTOR_WEIGHT DESC
        LIMIT 6
    """)


st.image(".streamlit/orbit_logo_light_horizontal.png", width=380)

securities, latest_date, filings, transcripts = get_kpis()

with st.container(horizontal=True):
    st.metric("Securities", f"{securities:,}" if isinstance(securities, int) else securities, border=True)
    st.metric("Market date", latest_date, border=True)
    st.metric("SEC filings", f"{filings:,}" if isinstance(filings, int) else filings, border=True)
    st.metric("Transcripts", f"{transcripts:,}" if isinstance(transcripts, int) else transcripts, border=True)

st.markdown("---")

col1, col2 = st.columns(2)

with col1:
    with st.container(border=True):
        st.markdown("**Market intelligence**")
        try:
            yields = get_yield_preview()
            if not yields.empty:
                chart = alt.Chart(yields).mark_bar().encode(
                    x=alt.X('MATURITY_LABEL', sort=None, title=None),
                    y=alt.Y('YIELD_PCT', title=None, scale=alt.Scale(zero=False)),
                ).properties(height=150)
                st.altair_chart(chart, use_container_width=True)
        except Exception:
            st.caption("Preview unavailable")
        st.page_link("app_pages/market_intelligence.py", label="Open markets", icon=":material/arrow_forward:", use_container_width=True)

with col2:
    with st.container(border=True):
        st.markdown("**Research hub** — AAPL")
        try:
            prices = get_price_preview()
            if not prices.empty:
                st.line_chart(prices, x="PRICE_DATE", y="PRICE_CLOSE", height=150)
        except Exception:
            st.caption("Preview unavailable")
        st.page_link("app_pages/research_hub.py", label="Open research", icon=":material/arrow_forward:", use_container_width=True)

col3, col4 = st.columns(2)

with col3:
    with st.container(border=True):
        st.markdown("**Portfolio analytics**")
        try:
            sectors = get_sector_preview()
            if not sectors.empty:
                chart = alt.Chart(sectors).mark_bar().encode(
                    y=alt.Y('GICS_SECTOR', sort=None, title=None),
                    x=alt.X('SECTOR_WEIGHT', title=None),
                ).properties(height=150)
                st.altair_chart(chart, use_container_width=True)
        except Exception:
            st.caption("Preview unavailable")
        st.page_link("app_pages/portfolio.py", label="Open portfolio", icon=":material/arrow_forward:", use_container_width=True)

with col4:
    with st.container(border=True):
        st.markdown("**AI agents**")
        st.caption("Natural language queries powered by Cortex")
        st.markdown(
            "_What is Apple's gross margin trend?_  \n"
            "_Show the US Treasury yield curve_  \n"
            "_Compare ORBIT portfolios_"
        )
        st.page_link("app_pages/ai_agents.py", label="Open agents", icon=":material/arrow_forward:", use_container_width=True)

st.markdown("---")
st.caption("Data: Snowflake Public Data (Paid) — refreshed daily")
