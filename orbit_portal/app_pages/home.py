# ORBIT home page — executive dashboard with KPI cards and navigation
# Co-authored with CoCo
import streamlit as st

conn = st.session_state.conn


@st.cache_data(ttl=300)
def get_kpis():
    try:
        securities = conn.query(
            "SELECT COUNT(*) AS CNT FROM ORBIT_DEMO.CURATED.DIM_ISSUER"
        ).iloc[0, 0]
    except Exception:
        securities = 0
    try:
        latest_date = conn.query(
            "SELECT MAX(PRICE_DATE)::VARCHAR AS DT FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES"
        ).iloc[0, 0]
    except Exception:
        latest_date = "—"
    try:
        filings = conn.query(
            "SELECT COUNT(*) AS CNT FROM ORBIT_DEMO.RAW.SEC_FILING_TEXT"
        ).iloc[0, 0]
    except Exception:
        filings = 0
    try:
        transcripts = conn.query(
            "SELECT COUNT(*) AS CNT FROM ORBIT_DEMO.RAW.EARNINGS_TRANSCRIPTS_CORPUS"
        ).iloc[0, 0]
    except Exception:
        transcripts = 0
    return securities, latest_date, filings, transcripts


st.image(".streamlit/orbit_logo_light_horizontal.png", width=400)
st.caption("Omniscient Reasoning Barclays Intelligence Tool")

securities, latest_date, filings, transcripts = get_kpis()

# KPI cards with borders in a horizontal container
with st.container(horizontal=True):
    st.metric("Securities tracked", f"{securities:,}" if isinstance(securities, int) else securities, border=True)
    st.metric("Latest market date", latest_date, border=True)
    st.metric("SEC filings", f"{filings:,}" if isinstance(filings, int) else filings, border=True)
    st.metric("Earnings transcripts", f"{transcripts:,}" if isinstance(transcripts, int) else transcripts, border=True)

st.markdown("---")
st.markdown("#### Navigate")

col1, col2 = st.columns(2)

with col1:
    with st.container(border=True):
        st.markdown("**Market intelligence**")
        st.caption("Yields, FX, economic indicators, central bank rates")
        st.page_link("app_pages/market_intelligence.py", label="Go to markets", icon=":material/arrow_forward:", use_container_width=True)

with col2:
    with st.container(border=True):
        st.markdown("**Research hub**")
        st.caption("Company financials, SEC filings, insider trades, ownership")
        st.page_link("app_pages/research_hub.py", label="Go to research", icon=":material/arrow_forward:", use_container_width=True)

col3, col4 = st.columns(2)

with col3:
    with st.container(border=True):
        st.markdown("**Portfolio analytics**")
        st.caption("Holdings, sector allocation, performance, benchmarks")
        st.page_link("app_pages/portfolio.py", label="Go to portfolio", icon=":material/arrow_forward:", use_container_width=True)

with col4:
    with st.container(border=True):
        st.markdown("**AI agents**")
        st.caption("Natural language research, portfolio, and market queries")
        st.page_link("app_pages/ai_agents.py", label="Go to agents", icon=":material/arrow_forward:", use_container_width=True)

st.markdown("---")
st.caption("Data: Snowflake Public Data (Paid) — refreshed daily")
