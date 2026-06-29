"""
ORBIT Investment Intelligence Portal
Streamlit multi-page app — landing page with KPIs and navigation.
"""
import streamlit as st
import os
import base64

st.set_page_config(
    page_title="ORBIT",
    page_icon="🔵",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Load logo as base64 for inline display
def get_logo_base64(filename):
    """Load a logo file and return base64 string for HTML embedding."""
    # Try relative paths that work in Streamlit-in-Snowflake
    for base_path in ['.', '/app', os.path.dirname(__file__) if '__file__' in dir() else '.']:
        path = os.path.join(base_path, 'assets', 'logos', filename)
        if os.path.exists(path):
            with open(path, 'rb') as f:
                return base64.b64encode(f.read()).decode()
    return None

logo_b64 = get_logo_base64('orbit_logo_dark_horizontal.png')

# ORBIT brand CSS
st.markdown("""
<style>
    .orbit-header {
        text-align: center;
        padding: 1rem 0;
    }
    .orbit-title {
        color: #1B6B93;
        font-size: 2.5rem;
        font-weight: 700;
        margin-bottom: 0;
    }
    .orbit-subtitle {
        color: #5DADE2;
        font-size: 1.1rem;
        font-weight: 400;
    }
    .metric-card {
        background: linear-gradient(135deg, #1B6B93 0%, #2E8BC0 100%);
        border-radius: 12px;
        padding: 1.5rem;
        color: white;
        text-align: center;
    }
    .metric-value {
        font-size: 2rem;
        font-weight: 700;
    }
    .metric-label {
        font-size: 0.85rem;
        opacity: 0.9;
    }
</style>
""", unsafe_allow_html=True)

from snowflake.snowpark.context import get_active_session
session = get_active_session()


@st.cache_data(ttl=300)
def get_kpis():
    """Fetch dashboard KPIs."""
    try:
        securities = session.sql("SELECT COUNT(*) FROM ORBIT_DEMO.CURATED.DIM_ISSUER").collect()[0][0]
    except Exception:
        securities = "N/A"
    try:
        latest_date = session.sql(
            "SELECT MAX(PRICE_DATE)::VARCHAR FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES"
        ).collect()[0][0]
    except Exception:
        latest_date = "N/A"
    try:
        filings = session.sql("SELECT COUNT(*) FROM ORBIT_DEMO.RAW.SEC_FILING_TEXT").collect()[0][0]
    except Exception:
        filings = "N/A"
    try:
        transcripts = session.sql(
            "SELECT COUNT(*) FROM ORBIT_DEMO.RAW.EARNINGS_TRANSCRIPTS_CORPUS"
        ).collect()[0][0]
    except Exception:
        transcripts = "N/A"
    return securities, latest_date, filings, transcripts


# Header
if logo_b64:
    st.markdown(
        f'<div class="orbit-header"><img src="data:image/png;base64,{logo_b64}" style="max-height:80px;"></div>',
        unsafe_allow_html=True
    )
else:
    st.markdown('<div class="orbit-header">', unsafe_allow_html=True)
    st.markdown('<p class="orbit-title">ORBIT</p>', unsafe_allow_html=True)
    st.markdown('<p class="orbit-subtitle">Omnicient Reasoning Barclays Intelligence Tool</p>', unsafe_allow_html=True)
    st.markdown('</div>', unsafe_allow_html=True)

st.divider()

# KPI Cards
securities, latest_date, filings, transcripts = get_kpis()

col1, col2, col3, col4 = st.columns(4)
with col1:
    st.metric("Securities Tracked", f"{securities:,}" if isinstance(securities, int) else securities)
with col2:
    st.metric("Latest Market Date", latest_date)
with col3:
    st.metric("SEC Filings Loaded", f"{filings:,}" if isinstance(filings, int) else filings)
with col4:
    st.metric("Earnings Transcripts", f"{transcripts:,}" if isinstance(transcripts, int) else transcripts)

st.divider()

# Navigation Grid
st.subheader("Explore")

col1, col2, col3, col4 = st.columns(4)

with col1:
    st.markdown("### Market Intelligence")
    st.write("Treasury yields, FX rates, economic indicators, policy rates")
    st.page_link("pages/1_Market_Intelligence.py", label="Open", icon="📊")

with col2:
    st.markdown("### Research Hub")
    st.write("Company financials, SEC filings, insider trades, ownership")
    st.page_link("pages/2_Research_Hub.py", label="Open", icon="🔬")

with col3:
    st.markdown("### Portfolio")
    st.write("Holdings, allocation, performance, benchmark comparison")
    st.page_link("pages/3_Portfolio.py", label="Open", icon="💼")

with col4:
    st.markdown("### AI Agents")
    st.write("Chat with ORBIT agents via Snowflake Intelligence")
    st.page_link("pages/4_AI_Agents.py", label="Open", icon="🤖")

st.divider()

# Data source info
st.caption(
    "Data sourced from Snowflake Public Data (Paid) — near-real-time market data, "
    "SEC filings, and earnings transcripts. Refreshed daily."
)
