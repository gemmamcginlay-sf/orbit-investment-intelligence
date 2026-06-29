-- ============================================================================
-- ORBIT Investment Intelligence — Semantic Views
-- ============================================================================
-- Creates semantic views using SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML.
-- Fully idempotent — safe to re-run.
-- ============================================================================

USE ROLE ORBIT_DEMO_ROLE;
USE DATABASE ORBIT_DEMO;
USE SCHEMA AI;
USE WAREHOUSE ORBIT_DEMO_WH;

-- ---------------------------------------------------------------------------
-- 1. ORBIT_MARKET_VIEW — Yields, FX, economic indicators, policy rates, prices
-- ---------------------------------------------------------------------------
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'ORBIT_DEMO.AI',
  $$
name: ORBIT_MARKET_VIEW
description: "Market intelligence: Treasury yields, economic indicators, FX rates, policy rates, and stock prices."
tables:
  - name: TREASURY_YIELDS
    description: "US Treasury par yield curve rates across maturities"
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_TREASURY_YIELDS
    primary_key:
      columns:
        - YIELD_ID
    dimensions:
      - name: DATE
        expr: DATE
        data_type: DATE
      - name: MATURITY_CODE
        expr: MATURITY_CODE
        data_type: VARCHAR
      - name: MATURITY_LABEL
        expr: MATURITY_LABEL
        data_type: VARCHAR
    facts:
      - name: YIELD_PCT
        expr: YIELD_PCT
        data_type: FLOAT
  - name: ECONOMIC_INDICATORS
    description: "US economic indicators (GDP, CPI, unemployment, fed funds)"
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_ECONOMIC_INDICATORS
    primary_key:
      columns:
        - INDICATOR_ID
    dimensions:
      - name: DATE
        expr: DATE
        data_type: DATE
      - name: INDICATOR_NAME
        expr: INDICATOR_NAME
        data_type: VARCHAR
      - name: INDICATOR_CATEGORY
        expr: INDICATOR_CATEGORY
        data_type: VARCHAR
      - name: UNIT
        expr: UNIT
        data_type: VARCHAR
    facts:
      - name: VALUE
        expr: VALUE
        data_type: FLOAT
  - name: FX_RATES
    description: "Foreign exchange rates vs USD"
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_FX_RATES
    primary_key:
      columns:
        - FX_ID
    dimensions:
      - name: DATE
        expr: DATE
        data_type: DATE
      - name: CURRENCY_PAIR
        expr: CURRENCY_PAIR
        data_type: VARCHAR
      - name: QUOTE_CURRENCY
        expr: QUOTE_CURRENCY
        data_type: VARCHAR
    facts:
      - name: EXCHANGE_RATE
        expr: EXCHANGE_RATE
        data_type: FLOAT
  - name: POLICY_RATES
    description: "Central bank policy rates by country"
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_POLICY_RATES
    primary_key:
      columns:
        - RATE_ID
    dimensions:
      - name: DATE
        expr: DATE
        data_type: DATE
      - name: RATE_NAME
        expr: RATE_NAME
        data_type: VARCHAR
      - name: COUNTRY
        expr: COUNTRY
        data_type: VARCHAR
    facts:
      - name: RATE_PCT
        expr: RATE_PCT
        data_type: FLOAT
  - name: STOCK_PRICES
    description: "Daily stock prices (OHLCV)"
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_STOCK_PRICES
    primary_key:
      columns:
        - PRICE_ID
    dimensions:
      - name: PRICE_DATE
        expr: PRICE_DATE
        data_type: DATE
      - name: TICKER
        expr: TICKER
        data_type: VARCHAR
      - name: COMPANY_NAME
        expr: COMPANY_NAME
        data_type: VARCHAR
      - name: GICS_SECTOR
        expr: GICS_SECTOR
        data_type: VARCHAR
    facts:
      - name: PRICE_CLOSE
        expr: PRICE_CLOSE
        data_type: FLOAT
      - name: PRICE_OPEN
        expr: PRICE_OPEN
        data_type: FLOAT
      - name: PRICE_HIGH
        expr: PRICE_HIGH
        data_type: FLOAT
      - name: PRICE_LOW
        expr: PRICE_LOW
        data_type: FLOAT
      - name: VOLUME
        expr: VOLUME
        data_type: NUMBER
    metrics:
      - name: LATEST_CLOSE
        expr: MAX(PRICE_CLOSE)
      - name: AVG_VOLUME
        expr: AVG(VOLUME)
  $$
);

-- ---------------------------------------------------------------------------
-- 2. ORBIT_RESEARCH_VIEW — SEC financials, insiders, institutional holdings
-- ---------------------------------------------------------------------------
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'ORBIT_DEMO.AI',
  $$
name: ORBIT_RESEARCH_VIEW
description: "Company research: SEC financials, insider trading, and institutional holdings."
tables:
  - name: ISSUERS
    description: "Company reference data"
    base_table:
      database: ORBIT_DEMO
      schema: CURATED
      table: DIM_ISSUER
    primary_key:
      columns:
        - ISSUER_ID
    dimensions:
      - name: ISSUER_ID
        expr: ISSUER_ID
        data_type: NUMBER
      - name: TICKER
        expr: TICKER
        data_type: VARCHAR
      - name: COMPANY_NAME
        expr: COMPANY_NAME
        data_type: VARCHAR
      - name: GICS_SECTOR
        expr: GICS_SECTOR
        data_type: VARCHAR
      - name: CIK
        expr: CIK
        data_type: VARCHAR
  - name: FINANCIALS
    description: "Quarterly/annual financials from SEC XBRL filings"
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_SEC_FINANCIALS
    primary_key:
      columns:
        - FINANCIAL_ID
    dimensions:
      - name: PERIOD_END_DATE
        expr: PERIOD_END_DATE
        data_type: DATE
      - name: F_ISSUER_ID
        expr: ISSUER_ID
        data_type: NUMBER
      - name: F_TICKER
        expr: TICKER
        data_type: VARCHAR
      - name: FISCAL_PERIOD
        expr: FISCAL_PERIOD
        data_type: VARCHAR
    facts:
      - name: REVENUE
        expr: REVENUE
        data_type: FLOAT
      - name: NET_INCOME
        expr: NET_INCOME
        data_type: FLOAT
      - name: OPERATING_INCOME
        expr: OPERATING_INCOME
        data_type: FLOAT
      - name: EPS_BASIC
        expr: EPS_BASIC
        data_type: FLOAT
      - name: GROSS_MARGIN_PCT
        expr: GROSS_MARGIN_PCT
        data_type: FLOAT
      - name: OPERATING_MARGIN_PCT
        expr: OPERATING_MARGIN_PCT
        data_type: FLOAT
      - name: NET_MARGIN_PCT
        expr: NET_MARGIN_PCT
        data_type: FLOAT
      - name: ROE_PCT
        expr: ROE_PCT
        data_type: FLOAT
      - name: FREE_CASH_FLOW
        expr: FREE_CASH_FLOW
        data_type: FLOAT
      - name: DEBT_TO_EQUITY
        expr: DEBT_TO_EQUITY
        data_type: FLOAT
  - name: INSIDER_TRANSACTIONS
    description: "SEC Form 4 insider trading"
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_INSIDER_TRANSACTIONS
    primary_key:
      columns:
        - INSIDER_TX_ID
    dimensions:
      - name: TRANSACTION_DATE
        expr: TRANSACTION_DATE
        data_type: DATE
      - name: IT_ISSUER_ID
        expr: ISSUER_ID
        data_type: NUMBER
      - name: IT_TICKER
        expr: TICKER
        data_type: VARCHAR
      - name: TRANSACTION_TYPE
        expr: TRANSACTION_TYPE
        data_type: VARCHAR
    facts:
      - name: TRANSACTION_SHARES
        expr: TRANSACTION_SHARES
        data_type: FLOAT
      - name: TRANSACTION_PRICE
        expr: TRANSACTION_PRICE_PER_SHARE
        data_type: FLOAT
  - name: INSTITUTIONAL_HOLDINGS
    description: "SEC 13F institutional ownership"
    base_table:
      database: ORBIT_DEMO
      schema: MARKET_DATA
      table: FACT_INSTITUTIONAL_HOLDINGS
    primary_key:
      columns:
        - HOLDING_ID
    dimensions:
      - name: FILING_DATE
        expr: FILING_DATE
        data_type: DATE
      - name: IH_ISSUER_ID
        expr: ISSUER_ID
        data_type: NUMBER
      - name: IH_TICKER
        expr: TICKER
        data_type: VARCHAR
      - name: INSTITUTION_NAME
        expr: INSTITUTION_NAME
        data_type: VARCHAR
    facts:
      - name: MARKET_VALUE_USD
        expr: MARKET_VALUE_USD
        data_type: FLOAT
      - name: SHARES_HELD
        expr: SHARES_HELD
        data_type: FLOAT
relationships:
  - name: FINANCIALS_TO_ISSUERS
    left_table: FINANCIALS
    right_table: ISSUERS
    relationship_columns:
      - left_column: F_ISSUER_ID
        right_column: ISSUER_ID
  - name: INSIDER_TO_ISSUERS
    left_table: INSIDER_TRANSACTIONS
    right_table: ISSUERS
    relationship_columns:
      - left_column: IT_ISSUER_ID
        right_column: ISSUER_ID
  - name: HOLDINGS_TO_ISSUERS
    left_table: INSTITUTIONAL_HOLDINGS
    right_table: ISSUERS
    relationship_columns:
      - left_column: IH_ISSUER_ID
        right_column: ISSUER_ID
  $$
);

-- ---------------------------------------------------------------------------
-- 3. ORBIT_PORTFOLIO_VIEW — Holdings, allocation, performance
-- ---------------------------------------------------------------------------
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'ORBIT_DEMO.AI',
  $$
name: ORBIT_PORTFOLIO_VIEW
description: "Portfolio analytics: holdings, weights, sector allocation, and performance."
tables:
  - name: PORTFOLIOS
    description: "ORBIT model portfolio definitions"
    base_table:
      database: ORBIT_DEMO
      schema: CURATED
      table: DIM_PORTFOLIO
    primary_key:
      columns:
        - PORTFOLIO_ID
    dimensions:
      - name: PORTFOLIO_ID
        expr: PORTFOLIO_ID
        data_type: NUMBER
      - name: PORTFOLIO_NAME
        expr: PORTFOLIO_NAME
        data_type: VARCHAR
      - name: BENCHMARK_NAME
        expr: BENCHMARK_NAME
        data_type: VARCHAR
      - name: STRATEGY
        expr: STRATEGY
        data_type: VARCHAR
    facts:
      - name: AUM_USD
        expr: AUM_USD
        data_type: FLOAT
  - name: POSITIONS
    description: "Portfolio positions with weights and values"
    base_table:
      database: ORBIT_DEMO
      schema: CURATED
      table: FACT_POSITION_DAILY
    primary_key:
      columns:
        - POSITION_ID
    dimensions:
      - name: AS_OF_DATE
        expr: AS_OF_DATE
        data_type: DATE
      - name: POS_PORTFOLIO_ID
        expr: PORTFOLIO_ID
        data_type: NUMBER
      - name: POS_ISSUER_ID
        expr: ISSUER_ID
        data_type: NUMBER
      - name: POS_TICKER
        expr: TICKER
        data_type: VARCHAR
    facts:
      - name: WEIGHT
        expr: WEIGHT
        data_type: FLOAT
      - name: SHARES
        expr: SHARES
        data_type: NUMBER
      - name: CURRENT_PRICE
        expr: CURRENT_PRICE
        data_type: FLOAT
      - name: POSITION_VALUE_USD
        expr: POSITION_VALUE_USD
        data_type: FLOAT
    metrics:
      - name: TOTAL_POSITIONS
        expr: COUNT(DISTINCT TICKER)
      - name: TOTAL_MARKET_VALUE
        expr: SUM(POSITION_VALUE_USD)
  - name: ISSUERS
    description: "Company reference for enriching positions"
    base_table:
      database: ORBIT_DEMO
      schema: CURATED
      table: DIM_ISSUER
    primary_key:
      columns:
        - ISSUER_ID
    dimensions:
      - name: ISSUER_ID
        expr: ISSUER_ID
        data_type: NUMBER
      - name: TICKER
        expr: TICKER
        data_type: VARCHAR
      - name: COMPANY_NAME
        expr: COMPANY_NAME
        data_type: VARCHAR
      - name: GICS_SECTOR
        expr: GICS_SECTOR
        data_type: VARCHAR
relationships:
  - name: POSITIONS_TO_PORTFOLIOS
    left_table: POSITIONS
    right_table: PORTFOLIOS
    relationship_columns:
      - left_column: POS_PORTFOLIO_ID
        right_column: PORTFOLIO_ID
  - name: POSITIONS_TO_ISSUERS
    left_table: POSITIONS
    right_table: ISSUERS
    relationship_columns:
      - left_column: POS_ISSUER_ID
        right_column: ISSUER_ID
  $$
);
