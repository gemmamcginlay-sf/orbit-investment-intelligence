# ORBIT AI Agents — connect to Snowflake CoWork with direct agent links
# Co-authored with CoCo
import urllib.parse
import streamlit as st

conn = st.session_state.conn

st.caption("Chat with ORBIT agents in Snowflake CoWork (Intelligence).")


@st.cache_data(ttl=600)
def get_account_info():
    result = conn.query(
        "SELECT LOWER(CURRENT_ORGANIZATION_NAME()) AS ORG, LOWER(CURRENT_ACCOUNT_NAME()) AS ACCT"
    )
    return result.iloc[0]['ORG'], result.iloc[0]['ACCT']


try:
    org, acct = get_account_info()
except Exception:
    org, acct = None, None

agents = [
    {
        "name": "Research Agent",
        "db": "ORBIT_DEMO",
        "schema": "AI",
        "agent": "ORBIT_RESEARCH_AGENT",
        "description": "Company research using SEC filings, earnings transcripts, and financial data.",
        "questions": [
            "What is Apple's quarterly revenue trend over the last 2 years?",
            "Compare gross margins for GOOGL vs META over the last 8 quarters",
            "Who are the largest institutional holders of Microsoft?",
            "Show NVIDIA's insider trading activity",
            "What is Meta's EPS trend by quarter?",
            "Compare net income: Apple vs Microsoft quarterly",
        ],
    },
    {
        "name": "Portfolio Agent",
        "db": "ORBIT_DEMO",
        "schema": "AI",
        "agent": "ORBIT_PORTFOLIO_AGENT",
        "description": "Portfolio analytics — holdings, allocation, sector exposure, and performance.",
        "questions": [
            "What are the top 10 holdings in ORBIT Technology & Infrastructure?",
            "Show sector allocation for ORBIT US Core Equity",
            "What is the total AUM across all ORBIT portfolios?",
            "Compare sector weights: ORBIT ESG Leaders vs ORBIT US Value",
            "Which portfolio has the highest concentration in Technology?",
            "Show me all holdings in the Renewable & Climate Solutions fund",
        ],
    },
    {
        "name": "Market Intelligence Agent",
        "db": "ORBIT_DEMO",
        "schema": "AI",
        "agent": "ORBIT_MARKET_AGENT",
        "description": "Macro strategy — yields, FX, economic indicators, stock prices, and policy rates.",
        "questions": [
            "Show the current US Treasury yield curve",
            "What are the latest central bank policy rates by country?",
            "How has GBP/USD moved over the last 3 months?",
            "Show AAPL and MSFT stock price performance over 1 year",
            "What are the latest economic indicators for inflation?",
            "Compare all FX rates against USD",
        ],
    },
]


def build_agent_url(agent_info, question=None):
    if org and acct:
        base = f"https://ai.snowflake.com/{org}/{acct}/#/ai/chat/new"
        params = {
            "db": agent_info["db"],
            "schema": agent_info["schema"],
            "agent": agent_info["agent"],
        }
        if question:
            params["question"] = question
        return f"{base}?{urllib.parse.urlencode(params)}"
    return "https://ai.snowflake.com"


for agent in agents:
    with st.container(border=True):
        col1, col2 = st.columns([4, 1])
        with col1:
            st.markdown(f"**{agent['name']}**")
            st.write(agent["description"])
        with col2:
            url = build_agent_url(agent)
            st.link_button("Open in CoWork", url, use_container_width=True)

        st.markdown("**Suggested questions:**")
        q_cols = st.columns(2)
        for i, question in enumerate(agent["questions"]):
            with q_cols[i % 2]:
                q_url = build_agent_url(agent, question)
                st.link_button(f"💬 {question}", q_url, use_container_width=True)
