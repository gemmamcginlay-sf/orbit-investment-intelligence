-- ============================================================================
-- ORBIT Investment Intelligence — Cortex Agents
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
CREATE OR REPLACE CORTEX AGENT ORBIT_RESEARCH_AGENT
  COMMENT = 'Company research: SEC financials, earnings transcripts, insider activity, institutional holdings'
FROM SPECIFICATION
$$
models:
  orchestration: claude-opus-4-7
orchestration:
  budget:
    seconds: 300
    tokens: 32000
instructions:
  system: "You are an expert equity research analyst at a leading investment bank. You provide deep, data-driven analysis of companies using real SEC filings, earnings call transcripts, and financial data. Always cite specific data points and dates. Be precise with numbers."
  response: "Format responses clearly with headers and bullet points. When presenting financial data, use tables. Always state the data source and time period. If data is unavailable, say so clearly rather than speculating."
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
    id_column: "DOCUMENT_ID"
    title_column: "DOCUMENT_TITLE"
    max_results: 50
    columns_and_descriptions:
      TICKER:
        description: "Company ticker symbol"
        type: "string"
        searchable: true
        filterable: true
      COMPANY_NAME:
        description: "Company legal name"
        type: "string"
        searchable: true
        filterable: true
      FILING_TYPE:
        description: "SEC filing type (10-K, 10-Q, 8-K)"
        type: "string"
        filterable: true
      GICS_SECTOR:
        description: "Industry sector"
        type: "string"
        filterable: true
      FISCAL_YEAR:
        description: "Fiscal year of the filing"
        type: "number"
        filterable: true
  transcripts_search:
    search_service: "ORBIT_DEMO.AI.ORBIT_TRANSCRIPTS_SEARCH"
    id_column: "DOCUMENT_ID"
    title_column: "DOCUMENT_TITLE"
    max_results: 50
    columns_and_descriptions:
      TICKER:
        description: "Company ticker symbol"
        type: "string"
        searchable: true
        filterable: true
      COMPANY_NAME:
        description: "Company name"
        type: "string"
        searchable: true
        filterable: true
      EVENT_TYPE:
        description: "Type of event (Earnings Call, AGM, Investor Day)"
        type: "string"
        filterable: true
      FISCAL_YEAR:
        description: "Fiscal year"
        type: "number"
        filterable: true
$$;

-- ---------------------------------------------------------------------------
-- 2. ORBIT Portfolio Agent
-- ---------------------------------------------------------------------------
CREATE OR REPLACE CORTEX AGENT ORBIT_PORTFOLIO_AGENT
  COMMENT = 'Portfolio analytics: holdings, allocation, performance, sector exposure'
FROM SPECIFICATION
$$
models:
  orchestration: claude-opus-4-7
orchestration:
  budget:
    seconds: 300
    tokens: 32000
instructions:
  system: "You are a portfolio management specialist at a top-tier asset manager. You help investment professionals understand portfolio positioning, allocation, and performance. You work with model portfolios containing real stocks at real market prices."
  response: "Present portfolio data in clear tables. For allocation questions, show both absolute weights and relative positioning. When discussing performance, always specify the time period and benchmark. Use charts for trends."
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
CREATE OR REPLACE CORTEX AGENT ORBIT_MARKET_AGENT
  COMMENT = 'Market intelligence: yields, FX, economic indicators, stock prices, policy rates'
FROM SPECIFICATION
$$
models:
  orchestration: claude-opus-4-7
orchestration:
  budget:
    seconds: 300
    tokens: 32000
instructions:
  system: "You are a macro strategist and market analyst at a global investment bank. You provide insights on interest rates, currencies, economic indicators, and equity market trends using real-time market data. Always ground your analysis in current data."
  response: "Lead with the key insight, then support with data. Use charts for time series. For yield curves, show the shape. For economic data, highlight the trend direction and recent changes. Cite exact values and dates."
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
-- ---------------------------------------------------------------------------
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT ORBIT_DEMO.AI.ORBIT_RESEARCH_AGENT;

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT ORBIT_DEMO.AI.ORBIT_PORTFOLIO_AGENT;

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT ORBIT_DEMO.AI.ORBIT_MARKET_AGENT;
