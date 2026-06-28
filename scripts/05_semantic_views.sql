-- ============================================================================
-- ORBIT Investment Intelligence — Semantic Views
-- ============================================================================
-- Creates semantic views from YAML definitions.
-- Uses FILE_PATH references to the YAML files in the repo.
-- ============================================================================

USE ROLE ORBIT_DEMO_ROLE;
USE DATABASE ORBIT_DEMO;
USE SCHEMA AI;
USE WAREHOUSE ORBIT_DEMO_WH;

-- ---------------------------------------------------------------------------
-- Note: Semantic Views are created from YAML definitions.
-- In Snowsight workspace, use the UI or run:
--   CREATE OR REPLACE SEMANTIC VIEW <name> FROM YAML ...
-- The YAML files are in the semantic_views/ directory of this repo.
-- ---------------------------------------------------------------------------

-- Market View — yields, FX, economic indicators, policy rates, stock prices
CREATE OR REPLACE SEMANTIC VIEW ORBIT_MARKET_VIEW
  COMMENT = 'Market intelligence: yields, FX, economic indicators, policy rates, stock prices'
  DISTRIBUTION = 'PUBLIC'
  AS '
name: ORBIT_MARKET_VIEW
description: "Market intelligence data covering US Treasury yields, economic indicators, foreign exchange rates, central bank policy rates, and stock prices."
tables:
  - name: treasury_yields
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_TREASURY_YIELDS
    primary_key:
      columns: [YIELD_ID]
    time_dimensions:
      - name: date
        expr: DATE
        data_type: DATE
    dimensions:
      - name: maturity_code
        expr: MATURITY_CODE
        data_type: VARCHAR
      - name: maturity_label
        expr: MATURITY_LABEL
        data_type: VARCHAR
    facts:
      - name: yield_pct
        expr: YIELD_PCT
        data_type: FLOAT
        access_modifier: public_access
  - name: economic_indicators
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_ECONOMIC_INDICATORS
    primary_key:
      columns: [INDICATOR_ID]
    time_dimensions:
      - name: date
        expr: DATE
        data_type: DATE
    dimensions:
      - name: indicator_name
        expr: INDICATOR_NAME
        data_type: VARCHAR
      - name: indicator_category
        expr: INDICATOR_CATEGORY
        data_type: VARCHAR
      - name: unit
        expr: UNIT
        data_type: VARCHAR
    facts:
      - name: value
        expr: VALUE
        data_type: FLOAT
        access_modifier: public_access
  - name: fx_rates
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_FX_RATES
    primary_key:
      columns: [FX_ID]
    time_dimensions:
      - name: date
        expr: DATE
        data_type: DATE
    dimensions:
      - name: currency_pair
        expr: CURRENCY_PAIR
        data_type: VARCHAR
      - name: quote_currency
        expr: QUOTE_CURRENCY
        data_type: VARCHAR
    facts:
      - name: exchange_rate
        expr: EXCHANGE_RATE
        data_type: FLOAT
        access_modifier: public_access
  - name: policy_rates
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_POLICY_RATES
    primary_key:
      columns: [RATE_ID]
    time_dimensions:
      - name: date
        expr: DATE
        data_type: DATE
    dimensions:
      - name: rate_name
        expr: RATE_NAME
        data_type: VARCHAR
      - name: country
        expr: COUNTRY
        data_type: VARCHAR
    facts:
      - name: rate_pct
        expr: RATE_PCT
        data_type: FLOAT
        access_modifier: public_access
  - name: stock_prices
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_STOCK_PRICES
    primary_key:
      columns: [PRICE_ID]
    time_dimensions:
      - name: price_date
        expr: PRICE_DATE
        data_type: DATE
    dimensions:
      - name: ticker
        expr: TICKER
        data_type: VARCHAR
      - name: company_name
        expr: COMPANY_NAME
        data_type: VARCHAR
      - name: gics_sector
        expr: GICS_SECTOR
        data_type: VARCHAR
    facts:
      - name: price_open
        expr: PRICE_OPEN
        data_type: FLOAT
        access_modifier: public_access
      - name: price_close
        expr: PRICE_CLOSE
        data_type: FLOAT
        access_modifier: public_access
      - name: price_high
        expr: PRICE_HIGH
        data_type: FLOAT
        access_modifier: public_access
      - name: price_low
        expr: PRICE_LOW
        data_type: FLOAT
        access_modifier: public_access
      - name: volume
        expr: VOLUME
        data_type: NUMBER
        access_modifier: public_access
verified_queries:
  - name: latest_yield_curve
    question: "Show me the current US Treasury yield curve"
    sql: "SELECT MATURITY_CODE, YIELD_PCT FROM __treasury_yields WHERE DATE = (SELECT MAX(DATE) FROM __treasury_yields) ORDER BY YIELD_PCT"
    use_as_onboarding_question: true
  - name: fed_funds
    question: "What is the current federal funds rate?"
    sql: "SELECT DATE, VALUE FROM __economic_indicators WHERE INDICATOR_CATEGORY = ''INTEREST_RATE'' ORDER BY DATE DESC LIMIT 5"
    use_as_onboarding_question: true
';

-- Research View — SEC financials, segments, insiders, institutional holdings
CREATE OR REPLACE SEMANTIC VIEW ORBIT_RESEARCH_VIEW
  COMMENT = 'Company research: SEC financials, segments, insider trading, institutional holdings'
  DISTRIBUTION = 'PUBLIC'
  AS '
name: ORBIT_RESEARCH_VIEW
description: "Company research data covering SEC financials, revenue segments, insider trading, and institutional holdings."
tables:
  - name: issuers
    base_table:
      database: ORBIT_DEMO
      schema: CURATED
      table: DIM_ISSUER
    primary_key:
      columns: [ISSUER_ID]
    dimensions:
      - name: issuer_id
        expr: ISSUER_ID
        data_type: INT
      - name: ticker
        expr: TICKER
        data_type: VARCHAR
      - name: company_name
        expr: COMPANY_NAME
        data_type: VARCHAR
      - name: gics_sector
        expr: GICS_SECTOR
        data_type: VARCHAR
  - name: financials
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_SEC_FINANCIALS
    primary_key:
      columns: [FINANCIAL_ID]
    time_dimensions:
      - name: period_end_date
        expr: PERIOD_END_DATE
        data_type: DATE
    dimensions:
      - name: f_issuer_id
        expr: ISSUER_ID
        data_type: INT
      - name: f_ticker
        expr: TICKER
        data_type: VARCHAR
      - name: fiscal_period
        expr: FISCAL_PERIOD
        data_type: VARCHAR
    facts:
      - name: revenue
        expr: REVENUE
        data_type: FLOAT
        access_modifier: public_access
      - name: net_income
        expr: NET_INCOME
        data_type: FLOAT
        access_modifier: public_access
      - name: operating_income
        expr: OPERATING_INCOME
        data_type: FLOAT
        access_modifier: public_access
      - name: eps_basic
        expr: EPS_BASIC
        data_type: FLOAT
        access_modifier: public_access
      - name: gross_margin_pct
        expr: GROSS_MARGIN_PCT
        data_type: FLOAT
        access_modifier: public_access
      - name: operating_margin_pct
        expr: OPERATING_MARGIN_PCT
        data_type: FLOAT
        access_modifier: public_access
      - name: roe_pct
        expr: ROE_PCT
        data_type: FLOAT
        access_modifier: public_access
      - name: free_cash_flow
        expr: FREE_CASH_FLOW
        data_type: FLOAT
        access_modifier: public_access
  - name: insider_transactions
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_INSIDER_TRANSACTIONS
    primary_key:
      columns: [INSIDER_TX_ID]
    time_dimensions:
      - name: transaction_date
        expr: TRANSACTION_DATE
        data_type: DATE
    dimensions:
      - name: it_issuer_id
        expr: ISSUER_ID
        data_type: INT
      - name: it_ticker
        expr: TICKER
        data_type: VARCHAR
      - name: transaction_type
        expr: TRANSACTION_TYPE
        data_type: VARCHAR
    facts:
      - name: transaction_shares
        expr: TRANSACTION_SHARES
        data_type: FLOAT
        access_modifier: public_access
      - name: transaction_price
        expr: TRANSACTION_PRICE_PER_SHARE
        data_type: FLOAT
        access_modifier: public_access
  - name: institutional_holdings
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_INSTITUTIONAL_HOLDINGS
    primary_key:
      columns: [HOLDING_ID]
    time_dimensions:
      - name: filing_date
        expr: FILING_DATE
        data_type: DATE
    dimensions:
      - name: ih_issuer_id
        expr: ISSUER_ID
        data_type: INT
      - name: ih_ticker
        expr: TICKER
        data_type: VARCHAR
      - name: institution_name
        expr: INSTITUTION_NAME
        data_type: VARCHAR
    facts:
      - name: market_value_usd
        expr: MARKET_VALUE_USD
        data_type: FLOAT
        access_modifier: public_access
      - name: shares_held
        expr: SHARES_HELD
        data_type: FLOAT
        access_modifier: public_access
relationships:
  - name: financials_to_issuers
    left_table: financials
    right_table: issuers
    relationship_columns:
      - left_column: f_issuer_id
        right_column: issuer_id
  - name: insider_to_issuers
    left_table: insider_transactions
    right_table: issuers
    relationship_columns:
      - left_column: it_issuer_id
        right_column: issuer_id
  - name: holdings_to_issuers
    left_table: institutional_holdings
    right_table: issuers
    relationship_columns:
      - left_column: ih_issuer_id
        right_column: issuer_id
verified_queries:
  - name: apple_revenue
    question: "Show Apple quarterly revenue trend"
    sql: "SELECT period_end_date, revenue, net_income, operating_margin_pct FROM __financials WHERE f_ticker = ''AAPL'' AND fiscal_period = ''Q'' ORDER BY period_end_date DESC LIMIT 8"
    use_as_onboarding_question: true
  - name: tesla_insiders
    question: "Recent insider trading for Tesla"
    sql: "SELECT transaction_date, transaction_type, transaction_shares, transaction_price FROM __insider_transactions WHERE it_ticker = ''TSLA'' ORDER BY transaction_date DESC LIMIT 20"
    use_as_onboarding_question: true
';

-- Portfolio View — holdings, allocation, performance
CREATE OR REPLACE SEMANTIC VIEW ORBIT_PORTFOLIO_VIEW
  COMMENT = 'Portfolio analytics: holdings, allocation, performance, benchmark comparison'
  DISTRIBUTION = 'PUBLIC'
  AS '
name: ORBIT_PORTFOLIO_VIEW
description: "Portfolio analytics covering holdings, weights, sector allocation, and performance."
tables:
  - name: portfolios
    base_table:
      database: ORBIT_DEMO
      schema: CURATED
      table: DIM_PORTFOLIO
    primary_key:
      columns: [PORTFOLIO_ID]
    dimensions:
      - name: portfolio_id
        expr: PORTFOLIO_ID
        data_type: INT
      - name: portfolio_name
        expr: PORTFOLIO_NAME
        data_type: VARCHAR
      - name: benchmark_name
        expr: BENCHMARK_NAME
        data_type: VARCHAR
      - name: strategy
        expr: STRATEGY
        data_type: VARCHAR
    facts:
      - name: aum_usd
        expr: AUM_USD
        data_type: FLOAT
        access_modifier: public_access
  - name: positions
    base_table:
      database: ORBIT_DEMO
      schema: CURATED
      table: FACT_POSITION_DAILY
    primary_key:
      columns: [POSITION_ID]
    time_dimensions:
      - name: as_of_date
        expr: AS_OF_DATE
        data_type: DATE
    dimensions:
      - name: pos_portfolio_id
        expr: PORTFOLIO_ID
        data_type: INT
      - name: pos_ticker
        expr: TICKER
        data_type: VARCHAR
    facts:
      - name: weight
        expr: WEIGHT
        data_type: FLOAT
        access_modifier: public_access
      - name: shares
        expr: SHARES
        data_type: NUMBER
        access_modifier: public_access
      - name: position_value_usd
        expr: POSITION_VALUE_USD
        data_type: FLOAT
        access_modifier: public_access
  - name: issuers
    base_table:
      database: ORBIT_DEMO
      schema: CURATED
      table: DIM_ISSUER
    primary_key:
      columns: [ISSUER_ID]
    dimensions:
      - name: issuer_id
        expr: ISSUER_ID
        data_type: INT
      - name: ticker
        expr: TICKER
        data_type: VARCHAR
      - name: company_name
        expr: COMPANY_NAME
        data_type: VARCHAR
      - name: gics_sector
        expr: GICS_SECTOR
        data_type: VARCHAR
relationships:
  - name: positions_to_portfolios
    left_table: positions
    right_table: portfolios
    relationship_columns:
      - left_column: pos_portfolio_id
        right_column: portfolio_id
  - name: positions_to_issuers
    left_table: positions
    right_table: issuers
    relationship_columns:
      - left_column: pos_ticker
        right_column: ticker
verified_queries:
  - name: tech_portfolio_top_10
    question: "Top 10 holdings in ORBIT Technology portfolio"
    sql: "SELECT pos_ticker, i.company_name, i.gics_sector, weight, position_value_usd FROM __positions p JOIN __issuers i ON p.pos_ticker = i.ticker JOIN __portfolios pf ON p.pos_portfolio_id = pf.portfolio_id WHERE pf.portfolio_name = ''ORBIT Technology & Infrastructure'' ORDER BY weight DESC LIMIT 10"
    use_as_onboarding_question: true
  - name: sector_allocation
    question: "Sector allocation of ORBIT US Core Equity"
    sql: "SELECT i.gics_sector, SUM(weight) AS sector_weight, COUNT(*) AS num_holdings FROM __positions p JOIN __issuers i ON p.pos_ticker = i.ticker JOIN __portfolios pf ON p.pos_portfolio_id = pf.portfolio_id WHERE pf.portfolio_name = ''ORBIT US Core Equity'' GROUP BY i.gics_sector ORDER BY sector_weight DESC"
    use_as_onboarding_question: true
';
