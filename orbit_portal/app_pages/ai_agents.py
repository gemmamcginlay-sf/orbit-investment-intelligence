# ORBIT AI Agents — connect to Snowflake Intelligence
# Co-authored with CoCo
import streamlit as st

conn = st.session_state.conn
account_name = conn.query("SELECT CURRENT_ACCOUNT_NAME() AS ACCT").iloc[0, 0]
account_url = f"https://{account_name}.snowflakecomputing.com"

st.caption("Open a conversation with an ORBIT agent in Snowflake Intelligence.")

agents = [
    {
        "name": "Research Agent",
        "fqn": "ORBIT_DEMO.AI.ORBIT_RESEARCH_AGENT",
        "description": "Company research using SEC filings, earnings transcripts, and financial data.",
        "examples": [
            "Apple's quarterly revenue trend over 2 years",
            "What did NVIDIA's CEO say about AI on the last call?",
            "Largest institutional holders of Microsoft",
            "Compare gross margins: Google vs Meta",
        ],
    },
    {
        "name": "Portfolio Agent",
        "fqn": "ORBIT_DEMO.AI.ORBIT_PORTFOLIO_AGENT",
        "description": "Portfolio analytics — holdings, allocation, sector exposure, and performance.",
        "examples": [
            "Top 10 holdings in ORBIT Technology portfolio",
            "Sector allocation for ORBIT US Core Equity",
            "Total AUM across all ORBIT portfolios",
            "Compare ORBIT ESG and ORBIT Growth",
        ],
    },
    {
        "name": "Market Intelligence Agent",
        "fqn": "ORBIT_DEMO.AI.ORBIT_MARKET_AGENT",
        "description": "Macro strategy — yields, FX, economic indicators, stock prices, policy rates.",
        "examples": [
            "Current US Treasury yield curve",
            "Latest federal funds rate",
            "GBP/USD movement in the last month",
            "Central bank policy rates comparison",
        ],
    },
]

for agent in agents:
    with st.container(border=True):
        col1, col2 = st.columns([4, 1])
        with col1:
            st.markdown(f"**{agent['name']}**")
            st.caption(agent["description"])
            st.markdown(" | ".join(f"_{ex}_" for ex in agent["examples"][:3]))
        with col2:
            cowork_url = f"{account_url}/intelligence/cowork?agent={agent['fqn']}"
            st.link_button("Open chat", cowork_url, use_container_width=True)
