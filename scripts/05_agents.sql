-- ORBIT Investment Intelligence — Cortex Agents
-- Co-authored with CoCo
-- ============================================================================
-- Creates 3 focused Cortex Agents and registers them with Snowflake Intelligence.
-- ============================================================================

USE ROLE ORBIT_DEMO_ROLE;
USE DATABASE ORBIT_DEMO;
USE SCHEMA AI;
USE WAREHOUSE ORBIT_DEMO_WH;

-- ---------------------------------------------------------------------------
-- 1. ORBIT Research Agent
-- ---------------------------------------------------------------------------
CREATE OR REPLACE AGENT ORBIT_RESEARCH_AGENT
  COMMENT = 'Company research: SEC financials, earnings transcripts, insider activity, institutional holdings'
FROM SPECIFICATION
$$
models:
  orchestration: auto
orchestration:
  budget:
    seconds: 300
    tokens: 32000
instructions:
  response: "You are an expert equity research analyst at a leading investment bank. You provide deep, data-driven analysis of companies using real SEC filings, earnings call transcripts, and financial data. Always cite specific data points and dates. Be precise with numbers. Format responses clearly with headers and bullet points. When presenting financial data, use tables. Always state the data source and time period. If data is unavailable, say so clearly rather than speculating."
  orchestration: |
    TOOL ROUTING:
    - For financial metrics (revenue, margins, EPS, cash flow): use research_analyst
    - For insider trading activity: use research_analyst
    - For institutional ownership (13F data): use research_analyst
    - For qualitative information from SEC filings (10-K, 10-Q, 8-K text): use sec_filings_search
    - For what executives said on earnings calls: use transcripts_search
    - For visualizations of financial trends: use data_to_chart after getting data

    RULES:
    - Always identify the company by ticker before querying
    - When comparing companies, query each separately then synthesize
    - Use SEC filings search for qualitative risk factors, MD&A, strategy discussion
    - Use transcripts search for management commentary, guidance, Q&A insights
  sample_questions:
    - question: "What is Apple's quarterly revenue trend over the last 2 years?"
    - question: "Compare gross margins for GOOGL vs META over the last 8 quarters"
    - question: "Who are the largest institutional holders of Microsoft?"
    - question: "Show NVIDIA's insider trading activity"
    - question: "What is Meta's EPS trend by quarter?"
    - question: "Compare net income: Apple vs Microsoft quarterly"
tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "research_analyst"
      description: "Query SEC financials, revenue segments, insider trades, and institutional holdings for any company. Use for quantitative financial analysis."
  - tool_spec:
      type: "cortex_search"
      name: "sec_filings_search"
      description: "Search full text of SEC 10-K, 10-Q, and 8-K filings. Use for qualitative analysis — risk factors, strategy, MD&A discussion, forward-looking statements."
  - tool_spec:
      type: "cortex_search"
      name: "transcripts_search"
      description: "Search earnings call transcripts. Use to find what executives said about specific topics, guidance, or strategic direction."
  - tool_spec:
      type: "data_to_chart"
      name: "data_to_chart"
      description: "Generate charts and visualizations from query results."
tool_resources:
  research_analyst:
    execution_environment:
      query_timeout: 30
      type: "warehouse"
      warehouse: "ORBIT_DEMO_WH"
    semantic_view: "ORBIT_DEMO.AI.ORBIT_RESEARCH_VIEW"
  sec_filings_search:
    search_service: "ORBIT_DEMO.AI.ORBIT_SEC_FILINGS_SEARCH"
    max_results: 10
  transcripts_search:
    search_service: "ORBIT_DEMO.AI.ORBIT_TRANSCRIPTS_SEARCH"
    max_results: 10
$$;

-- ---------------------------------------------------------------------------
-- 2. ORBIT Portfolio Agent
-- ---------------------------------------------------------------------------
CREATE OR REPLACE AGENT ORBIT_PORTFOLIO_AGENT
  COMMENT = 'Portfolio analytics: holdings, allocation, performance, sector exposure'
FROM SPECIFICATION
$$
models:
  orchestration: auto
orchestration:
  budget:
    seconds: 300
    tokens: 32000
instructions:
  response: "You are a portfolio management specialist at a top-tier asset manager. You help investment professionals understand portfolio positioning, allocation, and performance. Present portfolio data in clear tables. For allocation questions, show both absolute weights and relative positioning. When discussing performance, always specify the time period and benchmark. Use charts for trends."
  orchestration: |
    TOOL ROUTING:
    - For portfolio holdings, weights, sector allocation: use portfolio_analyst
    - For performance and returns: use portfolio_analyst
    - For benchmark comparison: use portfolio_analyst
    - For visualizations (pie charts, bar charts): use data_to_chart after getting data

    AVAILABLE PORTFOLIOS:
    - ORBIT Technology & Infrastructure (Nasdaq 100 benchmark, Growth)
    - ORBIT Global Flagship Multi-Asset (MSCI ACWI benchmark)
    - ORBIT ESG Leaders Global Equity (MSCI ACWI benchmark)
    - ORBIT US Core Equity (S&P 500 benchmark)
    - ORBIT Renewable & Climate Solutions (Nasdaq 100 benchmark, ESG)
    - ORBIT Sustainable Global Equity (MSCI ACWI, ESG)
    - ORBIT AI & Digital Innovation (Nasdaq 100, Growth)
    - ORBIT Global Balanced 60/40 (MSCI ACWI)
    - ORBIT Tech Disruptors Equity (Nasdaq 100, Growth)
    - ORBIT US Value Equity (S&P 500, Value)
    - ORBIT Multi-Asset Income (S&P 500, Income)
  sample_questions:
    - question: "What are the top 10 holdings in ORBIT Technology & Infrastructure?"
    - question: "Show sector allocation for ORBIT US Core Equity"
    - question: "What is the total AUM across all ORBIT portfolios?"
    - question: "Compare sector weights between ORBIT ESG Leaders and ORBIT US Value"
    - question: "Which portfolio has the highest concentration in Technology?"
    - question: "Show all holdings in the Renewable & Climate Solutions fund"
tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "portfolio_analyst"
      description: "Query portfolio holdings, weights, sector allocation, and performance metrics. Covers all ORBIT model portfolios."
  - tool_spec:
      type: "data_to_chart"
      name: "data_to_chart"
      description: "Generate charts and visualizations from query results."
tool_resources:
  portfolio_analyst:
    execution_environment:
      query_timeout: 30
      type: "warehouse"
      warehouse: "ORBIT_DEMO_WH"
    semantic_view: "ORBIT_DEMO.AI.ORBIT_PORTFOLIO_VIEW"
$$;

-- ---------------------------------------------------------------------------
-- 3. ORBIT Market Intelligence Agent
-- ---------------------------------------------------------------------------
CREATE OR REPLACE AGENT ORBIT_MARKET_AGENT
  COMMENT = 'Market intelligence: yields, FX, economic indicators, stock prices, policy rates'
FROM SPECIFICATION
$$
models:
  orchestration: auto
orchestration:
  budget:
    seconds: 300
    tokens: 32000
instructions:
  response: "You are a macro strategist and market analyst at a global investment bank. You provide insights on interest rates, currencies, economic indicators, and equity market trends using real-time market data. Lead with the key insight, then support with data. Use charts for time series. For yield curves, show the shape. For economic data, highlight the trend direction and recent changes. Cite exact values and dates."
  orchestration: |
    TOOL ROUTING:
    - For yield curves and interest rates: use market_analyst (treasury_yields table)
    - For FX rates and currency movements: use market_analyst (fx_rates table)
    - For economic data (GDP, CPI, unemployment): use market_analyst (economic_indicators table)
    - For central bank policy rates: use market_analyst (policy_rates table)
    - For stock prices and equity market data: use market_analyst (stock_prices table)
    - For charts and visualizations: use data_to_chart

    RULES:
    - For yield curves, always show all maturities on the latest date
    - For FX, show the rate and recent trend
    - For economic indicators, filter by INDICATOR_CATEGORY for clean results
    - Stock prices use post-market close (PRICE_CLOSE) as the reference
  sample_questions:
    - question: "Show the current US Treasury yield curve"
    - question: "What are the latest central bank policy rates by country?"
    - question: "How has GBP/USD moved over the last 3 months?"
    - question: "Show AAPL and MSFT stock price performance over 1 year"
    - question: "What are the latest economic indicators for inflation?"
    - question: "Compare all FX rates against USD"
tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "market_analyst"
      description: "Query market data: Treasury yields, FX rates, economic indicators, policy rates, and stock prices. All data is near-real-time from Snowflake Public Data."
  - tool_spec:
      type: "data_to_chart"
      name: "data_to_chart"
      description: "Generate charts and visualizations from query results."
tool_resources:
  market_analyst:
    execution_environment:
      query_timeout: 30
      type: "warehouse"
      warehouse: "ORBIT_DEMO_WH"
    semantic_view: "ORBIT_DEMO.AI.ORBIT_MARKET_VIEW"
$$;

-- ---------------------------------------------------------------------------
-- Register agents with Snowflake Intelligence
-- (DROP first to make idempotent — ignore errors if not yet registered)
-- ---------------------------------------------------------------------------

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  DROP AGENT ORBIT_DEMO.AI.ORBIT_RESEARCH_AGENT;
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  DROP AGENT ORBIT_DEMO.AI.ORBIT_PORTFOLIO_AGENT;
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  DROP AGENT ORBIT_DEMO.AI.ORBIT_MARKET_AGENT;


ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT ORBIT_DEMO.AI.ORBIT_RESEARCH_AGENT;
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT ORBIT_DEMO.AI.ORBIT_PORTFOLIO_AGENT;
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT ORBIT_DEMO.AI.ORBIT_MARKET_AGENT;
