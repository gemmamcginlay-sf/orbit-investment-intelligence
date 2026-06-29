# ORBIT Investment Intelligence Portal — main entry with st.navigation
# Co-authored with CoCo
import os
import streamlit as st

st.set_page_config(
    page_title="ORBIT | Investment Intelligence",
    page_icon=":material/public:",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Logo above navigation — use sidebar image at top
with st.sidebar:
    st.image(".streamlit/orbit_logo_light_horizontal.png", use_container_width=True)
    st.markdown("---")

# Shared connection
conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))
st.session_state.conn = conn

# Navigation (renders below the sidebar content above)
page = st.navigation([
    st.Page("app_pages/home.py", title="Home", icon=":material/home:", default=True),
    st.Page("app_pages/market_intelligence.py", title="Market Intelligence", icon=":material/trending_up:"),
    st.Page("app_pages/research_hub.py", title="Research Hub", icon=":material/search:"),
    st.Page("app_pages/portfolio.py", title="Portfolio", icon=":material/account_balance:"),
    st.Page("app_pages/ai_agents.py", title="AI Agents", icon=":material/smart_toy:"),
])

page.run()
