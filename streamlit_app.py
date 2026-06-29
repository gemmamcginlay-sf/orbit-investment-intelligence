# ORBIT Investment Intelligence Portal — polished landing page with portal-style navigation
# Co-authored with CoCo
import os
import streamlit as st

st.set_page_config(
    page_title="ORBIT | Investment Intelligence",
    page_icon=":material/public:",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Branding: sidebar logo + main logo
st.logo(
    ".streamlit/orbit_logo_dark_horizontal.png",
    icon_image=".streamlit/orbit_logo_dark_square.png",
)

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))


@st.cache_data(ttl=300)
def get_kpis():
    try:
        securities = conn.query(
            "SELECT COUNT(*) AS CNT FROM ORBIT_DEMO.CURATED.DIM_ISSUER"
        ).iloc[0, 0]
    except Exception:
        securities = "N/A"
    try:
        latest_date = conn.query(
            "SELECT MAX(PRICE_DATE)::VARCHAR AS DT FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES"
        ).iloc[0, 0]
    except Exception:
        latest_date = "N/A"
    try:
        filings = conn.query(
            "SELECT COUNT(*) AS CNT FROM ORBIT_DEMO.RAW.SEC_FILING_TEXT"
        ).iloc[0, 0]
    except Exception:
        filings = "N/A"
    try:
        transcripts = conn.query(
            "SELECT COUNT(*) AS CNT FROM ORBIT_DEMO.RAW.EARNINGS_TRANSCRIPTS_CORPUS"
        ).iloc[0, 0]
    except Exception:
        transcripts = "N/A"
    return securities, latest_date, filings, transcripts


# --- Portal header ---
st.image(".streamlit/orbit_logo_dark_horizontal.png", width=280)
st.markdown(
    "##### Omniscient Reasoning Barclays Intelligence Tool"
)
st.caption("Your unified gateway to market data, research, portfolio analytics, and AI-powered insights.")

st.space("medium")

# --- KPI row ---
securities, latest_date, filings, transcripts = get_kpis()

c1, c2, c3, c4 = st.columns(4)
with c1:
    st.metric(
        "Securities tracked",
        f"{securities:,}" if isinstance(securities, int) else securities,
    )
with c2:
    st.metric("Latest market date", latest_date)
with c3:
    st.metric(
        "SEC filings loaded",
        f"{filings:,}" if isinstance(filings, int) else filings,
    )
with c4:
    st.metric(
        "Earnings transcripts",
        f"{transcripts:,}" if isinstance(transcripts, int) else transcripts,
    )

st.space("large")

# --- Navigation portal cards ---
st.markdown("##### Explore the platform")

col1, col2 = st.columns(2)

with col1:
    with st.container(border=True):
        st.subheader(":material/trending_up: Market intelligence")
        st.markdown(
            "Treasury yields, FX rates, economic indicators, and central bank policy rates. "
            "Stay on top of macro conditions."
        )
        st.page_link(
            "pages/1_Market_Intelligence.py",
            label="Open market intelligence",
            icon=":material/arrow_forward:",
            use_container_width=True,
        )

with col2:
    with st.container(border=True):
        st.subheader(":material/search: Research hub")
        st.markdown(
            "Company financials, SEC filings, insider trades, and institutional ownership. "
            "Deep-dive into any issuer."
        )
        st.page_link(
            "pages/2_Research_Hub.py",
            label="Open research hub",
            icon=":material/arrow_forward:",
            use_container_width=True,
        )

col3, col4 = st.columns(2)

with col3:
    with st.container(border=True):
        st.subheader(":material/account_balance: Portfolio")
        st.markdown(
            "Holdings, allocation, performance, and benchmark comparison across "
            "ORBIT model portfolios."
        )
        st.page_link(
            "pages/3_Portfolio.py",
            label="Open portfolio",
            icon=":material/arrow_forward:",
            use_container_width=True,
        )

with col4:
    with st.container(border=True):
        st.subheader(":material/smart_toy: AI agents")
        st.markdown(
            "Chat with ORBIT's Cortex agents for research, portfolio analysis, "
            "and market intelligence via natural language."
        )
        st.page_link(
            "pages/4_AI_Agents.py",
            label="Open AI agents",
            icon=":material/arrow_forward:",
            use_container_width=True,
        )

st.space("large")

# --- Footer ---
st.caption(
    "Data sourced from Snowflake Public Data (Paid) — near-real-time market data, "
    "SEC filings, and earnings transcripts. Refreshed daily."
)
