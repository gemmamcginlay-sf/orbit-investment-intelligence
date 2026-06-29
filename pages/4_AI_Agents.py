"""ORBIT — AI Agents Page"""
import streamlit as st

st.set_page_config(page_title="ORBIT | AI Agents", layout="wide")
st.title("AI Agents")
st.markdown("Chat with ORBIT agents in Snowflake Intelligence (CoWork). Click a button below to open a conversation.")

from snowflake.snowpark.context import get_active_session
session = get_active_session()

account_url = f"https://{session.get_current_account()}.snowflakecomputing.com"

agents = {
    "Research Agent": {
        "fqn": "ORBIT_DEMO.AI.ORBIT_RESEARCH_AGENT",
        "description": "Deep-dive company research using real SEC filings, earnings transcripts, and financial data.",
        "examples": [
            "Show me Apple's quarterly revenue trend over the last 2 years",
            "What did NVIDIA's CEO say about AI on the last earnings call?",
            "Who are the largest institutional holders of Microsoft?",
            "Show me insider trading activity for Tesla in the last 90 days",
            "Compare gross margins between Google and Meta",
        ]
    },
    "Portfolio Agent": {
        "fqn": "ORBIT_DEMO.AI.ORBIT_PORTFOLIO_AGENT",
        "description": "Portfolio analytics — holdings, allocation, sector exposure, and performance across ORBIT model portfolios.",
        "examples": [
            "What are the top 10 holdings in the ORBIT Technology portfolio?",
            "Show me sector allocation for ORBIT US Core Equity",
            "Which portfolio has the highest concentration in tech?",
            "What is the total AUM across all ORBIT portfolios?",
            "Compare the ORBIT ESG and ORBIT Growth portfolios",
        ]
    },
    "Market Intelligence Agent": {
        "fqn": "ORBIT_DEMO.AI.ORBIT_MARKET_AGENT",
        "description": "Macro strategy and market analysis — yields, FX, economic indicators, stock prices, and policy rates.",
        "examples": [
            "Show me the current US Treasury yield curve",
            "What is the latest federal funds rate?",
            "How has GBP/USD moved in the last month?",
            "Compare central bank policy rates across major economies",
            "What are the latest US CPI and unemployment numbers?",
        ]
    },
}

for name, agent in agents.items():
    with st.container(border=True):
        col1, col2 = st.columns([3, 1])
        with col1:
            st.subheader(name)
            st.write(agent["description"])
            st.caption("Example questions:")
            for ex in agent["examples"]:
                st.markdown(f"- _{ex}_")
        with col2:
            st.write("")
            st.write("")
            cowork_url = f"{account_url}/intelligence/cowork?agent={agent['fqn']}"
            st.link_button(f"Chat with {name}", cowork_url, use_container_width=True)
