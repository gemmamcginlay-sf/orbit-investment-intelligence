-- ============================================================================
-- ORBIT Investment Intelligence — Data Layer (Dimensions + Market Data + Derived)
-- ============================================================================
-- Single script for ALL data objects. Ordered by dependency:
--   1. Dimensions (DIM_ISSUER, DIM_SECURITY, DIM_PORTFOLIO, DIM_BENCHMARK)
--   2. Market Data (FACT tables from Snowflake Public Data Paid)
--   3. Derived tables and views (positions, returns)
--
-- Fully idempotent — safe to re-run at any time.
-- ============================================================================

USE ROLE ORBIT_DEMO_ROLE;
USE DATABASE ORBIT_DEMO;
USE WAREHOUSE ORBIT_DEMO_WH;

-- ═══════════════════════════════════════════════════════════════════════════════
-- PART 1: DIMENSION TABLES (no external dependencies beyond Paid share)
-- ═══════════════════════════════════════════════════════════════════════════════
USE SCHEMA CURATED;

-- ---------------------------------------------------------------------------
-- 1.1 DIM_ISSUER — Dynamic from Snowflake Public Data (Paid)
--     Pulls all NYSE/NASDAQ companies with recent price activity and SEC data.
--     Maps SIC descriptions to GICS-like sectors for portfolio construction.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_ISSUER AS
WITH active_tickers AS (
    -- Companies with price data in the last 30 days
    SELECT DISTINCT TICKER
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.STOCK_PRICE_TIMESERIES
    WHERE DATE >= DATEADD(DAY, -30, CURRENT_DATE())
      AND VARIABLE = 'post-market_close'
      AND VALUE IS NOT NULL
),
listed_companies AS (
    SELECT
        ci.COMPANY_ID,
        ci.PRIMARY_TICKER AS TICKER,
        ci.COMPANY_NAME,
        ci.CIK,
        ci.PRIMARY_EXCHANGE_CODE,
        ci.LEI
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_INDEX ci
    WHERE ci.PRIMARY_TICKER IS NOT NULL
      AND ci.CIK IS NOT NULL
      AND ci.PRIMARY_EXCHANGE_CODE IN ('NYS', 'NAS', 'NSM', 'NMS')
      AND ci.PRIMARY_TICKER IN (SELECT TICKER FROM active_tickers)
),
sector_data AS (
    SELECT COMPANY_ID, VALUE AS SIC_DESCRIPTION
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_CHARACTERISTICS
    WHERE RELATIONSHIP_TYPE = 'sic_description'
      AND RELATIONSHIP_END_DATE IS NULL
),
country_data AS (
    SELECT COMPANY_ID, VALUE AS COUNTRY
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_CHARACTERISTICS
    WHERE RELATIONSHIP_TYPE = 'business_address_country'
      AND RELATIONSHIP_END_DATE IS NULL
),
with_sector AS (
    SELECT
        lc.COMPANY_ID,
        lc.TICKER,
        lc.COMPANY_NAME,
        lc.CIK,
        lc.PRIMARY_EXCHANGE_CODE,
        lc.LEI,
        sd.SIC_DESCRIPTION,
        COALESCE(cd.COUNTRY, 'US') AS COUNTRY,
        -- Map SIC descriptions to GICS-like sectors
        CASE
            WHEN LOWER(sd.SIC_DESCRIPTION) LIKE ANY ('%software%','%computer%','%semiconductor%','%data processing%','%electronic%') THEN 'Information Technology'
            WHEN LOWER(sd.SIC_DESCRIPTION) LIKE ANY ('%pharmaceutical%','%biological%','%medical%','%surgical%','%health%','%drug%') THEN 'Health Care'
            WHEN LOWER(sd.SIC_DESCRIPTION) LIKE ANY ('%bank%','%insurance%','%investment%','%securities%','%finance%','%credit%') THEN 'Financials'
            WHEN LOWER(sd.SIC_DESCRIPTION) LIKE ANY ('%retail%','%automobile%','%apparel%','%restaurant%','%eating%','%hotel%','%entertainment%') THEN 'Consumer Discretionary'
            WHEN LOWER(sd.SIC_DESCRIPTION) LIKE ANY ('%food%','%beverage%','%tobacco%','%household%','%grocery%') THEN 'Consumer Staples'
            WHEN LOWER(sd.SIC_DESCRIPTION) LIKE ANY ('%oil%','%gas%','%petroleum%','%crude%','%coal%','%drilling%','%refin%') THEN 'Energy'
            WHEN LOWER(sd.SIC_DESCRIPTION) LIKE ANY ('%aerospace%','%defense%','%construction%','%machinery%','%transportation%','%freight%','%trucking%') THEN 'Industrials'
            WHEN LOWER(sd.SIC_DESCRIPTION) LIKE ANY ('%telecom%','%wireless%','%broadcast%','%cable%','%communication%') THEN 'Communication Services'
            WHEN LOWER(sd.SIC_DESCRIPTION) LIKE ANY ('%electric service%','%water%','%natural gas%','%power%','%utility%') THEN 'Utilities'
            WHEN LOWER(sd.SIC_DESCRIPTION) LIKE ANY ('%chemical%','%metal%','%mining%','%paper%','%steel%','%gold%') THEN 'Materials'
            WHEN LOWER(sd.SIC_DESCRIPTION) LIKE ANY ('%real estate%','%reit%') THEN 'Real Estate'
            ELSE 'Other'
        END AS GICS_SECTOR
    FROM listed_companies lc
    LEFT JOIN sector_data sd ON lc.COMPANY_ID = sd.COMPANY_ID
    LEFT JOIN country_data cd ON lc.COMPANY_ID = cd.COMPANY_ID
)
SELECT
    ROW_NUMBER() OVER (ORDER BY COMPANY_NAME) AS ISSUER_ID,
    TICKER,
    COMPANY_NAME,
    GICS_SECTOR,
    SIC_DESCRIPTION,
    CIK,
    COMPANY_ID AS PROVIDER_COMPANY_ID,
    LEI,
    COUNTRY,
    PRIMARY_EXCHANGE_CODE AS EXCHANGE,
    'SNOWFLAKE_PUBLIC_DATA_PAID' AS DATA_SOURCE,
    CURRENT_TIMESTAMP() AS LOADED_AT
FROM with_sector
WHERE GICS_SECTOR != 'Other';

-- ---------------------------------------------------------------------------
-- 1.2 DIM_SECURITY — One equity per issuer
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_SECURITY AS
SELECT
    ISSUER_ID AS SECURITY_ID, ISSUER_ID, TICKER,
    COMPANY_NAME || ' Common Stock' AS SECURITY_NAME,
    'Equity' AS ASSET_CLASS, 'Common Stock' AS SECURITY_TYPE, 'USD' AS CURRENCY,
    CURRENT_TIMESTAMP() AS LOADED_AT
FROM DIM_ISSUER;

-- ---------------------------------------------------------------------------
-- 1.3 DIM_PORTFOLIO — 11 ORBIT model portfolios
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_PORTFOLIO AS
SELECT COLUMN1 AS PORTFOLIO_ID, COLUMN2 AS PORTFOLIO_NAME,
       COLUMN3 AS BENCHMARK_NAME, COLUMN4 AS STRATEGY,
       COLUMN5 AS AUM_USD, COLUMN6 AS BASE_CURRENCY,
       COLUMN7 AS INCEPTION_DATE
FROM VALUES
    (1, 'ORBIT Technology & Infrastructure', 'Nasdaq 100', 'Growth', 1500000000, 'USD', '2019-01-01'::DATE),
    (2, 'ORBIT Global Flagship Multi-Asset', 'MSCI ACWI', 'Multi-Asset', 2500000000, 'USD', '2019-01-01'::DATE),
    (3, 'ORBIT ESG Leaders Global Equity', 'MSCI ACWI', 'ESG', 1800000000, 'USD', '2019-01-01'::DATE),
    (4, 'ORBIT US Core Equity', 'S&P 500', 'Core', 1200000000, 'USD', '2019-01-01'::DATE),
    (5, 'ORBIT Renewable & Climate Solutions', 'Nasdaq 100', 'ESG', 1000000000, 'USD', '2019-01-01'::DATE),
    (6, 'ORBIT Sustainable Global Equity', 'MSCI ACWI', 'ESG', 1100000000, 'USD', '2019-01-01'::DATE),
    (7, 'ORBIT AI & Digital Innovation', 'Nasdaq 100', 'Growth', 900000000, 'USD', '2019-01-01'::DATE),
    (8, 'ORBIT Global Balanced 60/40', 'MSCI ACWI', 'Multi-Asset', 800000000, 'USD', '2019-01-01'::DATE),
    (9, 'ORBIT Tech Disruptors Equity', 'Nasdaq 100', 'Growth', 700000000, 'USD', '2019-01-01'::DATE),
    (10, 'ORBIT US Value Equity', 'S&P 500', 'Value', 600000000, 'USD', '2019-01-01'::DATE),
    (11, 'ORBIT Multi-Asset Income', 'S&P 500', 'Income', 500000000, 'USD', '2019-01-01'::DATE);

-- ---------------------------------------------------------------------------
-- 1.4 DIM_BENCHMARK — Benchmark reference
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_BENCHMARK AS
SELECT COLUMN1 AS BENCHMARK_ID, COLUMN2 AS BENCHMARK_CODE,
       COLUMN3 AS BENCHMARK_NAME, COLUMN4 AS ETF_PROXY
FROM VALUES
    (1, 'SPX', 'S&P 500', 'SPY'), (2, 'ACWI', 'MSCI ACWI', 'ACWI'),
    (3, 'RUT', 'Russell 2000', 'IWM'), (4, 'NDX', 'Nasdaq 100', 'QQQ'),
    (5, 'AGG', 'Bloomberg US Agg', 'AGG'), (6, 'HYG', 'US High Yield', 'HYG'),
    (7, 'LQD', 'US Investment Grade', 'LQD'), (8, 'TLT', 'US 20+ Year Treasury', 'TLT'),
    (9, 'GLD', 'Gold', 'GLD'), (10, 'EEM', 'MSCI Emerging Markets', 'EEM');

-- ═══════════════════════════════════════════════════════════════════════════════
-- PART 2: MARKET DATA TABLES (depend on DIM_ISSUER)
-- ═══════════════════════════════════════════════════════════════════════════════
USE SCHEMA MARKET_DATA;

-- ---------------------------------------------------------------------------
-- 2.1 FACT_STOCK_PRICES — Daily OHLCV
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_STOCK_PRICES AS
WITH price_data AS (
    SELECT TICKER, DATE AS PRICE_DATE, VARIABLE, VALUE
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.STOCK_PRICE_TIMESERIES
    WHERE DATE >= DATEADD(YEAR, -3, CURRENT_DATE())
      AND TICKER IN (SELECT TICKER FROM ORBIT_DEMO.CURATED.DIM_ISSUER)
),
pivoted AS (
    SELECT TICKER, PRICE_DATE,
        MAX(CASE WHEN VARIABLE = 'pre-market_open' THEN VALUE END) AS PRICE_OPEN,
        MAX(CASE WHEN VARIABLE = 'post-market_close' THEN VALUE END) AS PRICE_CLOSE,
        MAX(CASE WHEN VARIABLE = 'all-day_high' THEN VALUE END) AS PRICE_HIGH,
        MAX(CASE WHEN VARIABLE = 'all-day_low' THEN VALUE END) AS PRICE_LOW,
        MAX(CASE WHEN VARIABLE = 'nasdaq_volume' THEN VALUE END) AS VOLUME
    FROM price_data GROUP BY TICKER, PRICE_DATE
)
SELECT
    ROW_NUMBER() OVER (ORDER BY i.ISSUER_ID, p.PRICE_DATE) AS PRICE_ID,
    i.ISSUER_ID, i.TICKER, i.COMPANY_NAME, i.GICS_SECTOR,
    p.PRICE_DATE, p.PRICE_OPEN, p.PRICE_HIGH, p.PRICE_LOW, p.PRICE_CLOSE,
    p.VOLUME::BIGINT AS VOLUME,
    'SNOWFLAKE_PUBLIC_DATA_PAID' AS DATA_SOURCE, CURRENT_TIMESTAMP() AS LOADED_AT
FROM pivoted p
JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON p.TICKER = i.TICKER
WHERE p.PRICE_CLOSE IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2.2 FACT_SEC_FINANCIALS — Income statement, balance sheet, cash flow
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_SEC_FINANCIALS AS
WITH our_companies AS (
    SELECT ISSUER_ID, CIK, TICKER, COMPANY_NAME, GICS_SECTOR
    FROM ORBIT_DEMO.CURATED.DIM_ISSUER WHERE CIK IS NOT NULL
),
sec_raw AS (
    SELECT CIK, ADSH, TAG, PERIOD_END_DATE, COVERED_QTRS,
           TRY_CAST(VALUE AS FLOAT) AS VALUE_NUM
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_ATTRIBUTES
    WHERE CIK IN (SELECT CIK FROM our_companies)
      AND PERIOD_END_DATE >= DATEADD(YEAR, -3, CURRENT_DATE())
      AND VALUE IS NOT NULL AND TRY_CAST(VALUE AS FLOAT) IS NOT NULL
      AND TAG IN (
          'Revenues','RevenueFromContractWithCustomerExcludingAssessedTax',
          'NetIncomeLoss','GrossProfit','OperatingIncomeLoss',
          'EarningsPerShareBasic','EarningsPerShareDiluted',
          'ResearchAndDevelopmentExpense','InterestExpense',
          'Assets','Liabilities','StockholdersEquity',
          'CashAndCashEquivalentsAtCarryingValue','LongTermDebt',
          'NetCashProvidedByUsedInOperatingActivities',
          'NetCashProvidedByUsedInFinancingActivities',
          'PaymentsToAcquirePropertyPlantAndEquipment',
          'DepreciationDepletionAndAmortization',
          'EntityCommonStockSharesOutstanding',
          'WeightedAverageNumberOfSharesOutstandingBasic'
      )
),
pivoted AS (
    SELECT CIK, ADSH, PERIOD_END_DATE, COVERED_QTRS,
        CASE WHEN COVERED_QTRS=1 THEN 'Q' WHEN COVERED_QTRS=4 THEN 'FY' ELSE 'OTHER' END AS FISCAL_PERIOD,
        MAX(CASE WHEN TAG IN ('Revenues','RevenueFromContractWithCustomerExcludingAssessedTax') THEN VALUE_NUM END) AS REVENUE,
        MAX(CASE WHEN TAG='NetIncomeLoss' THEN VALUE_NUM END) AS NET_INCOME,
        MAX(CASE WHEN TAG='GrossProfit' THEN VALUE_NUM END) AS GROSS_PROFIT,
        MAX(CASE WHEN TAG='OperatingIncomeLoss' THEN VALUE_NUM END) AS OPERATING_INCOME,
        MAX(CASE WHEN TAG='EarningsPerShareBasic' THEN VALUE_NUM END) AS EPS_BASIC,
        MAX(CASE WHEN TAG='EarningsPerShareDiluted' THEN VALUE_NUM END) AS EPS_DILUTED,
        MAX(CASE WHEN TAG='ResearchAndDevelopmentExpense' THEN VALUE_NUM END) AS RD_EXPENSE,
        MAX(CASE WHEN TAG='InterestExpense' THEN VALUE_NUM END) AS INTEREST_EXPENSE,
        MAX(CASE WHEN TAG='Assets' THEN VALUE_NUM END) AS TOTAL_ASSETS,
        MAX(CASE WHEN TAG='Liabilities' THEN VALUE_NUM END) AS TOTAL_LIABILITIES,
        MAX(CASE WHEN TAG='StockholdersEquity' THEN VALUE_NUM END) AS TOTAL_EQUITY,
        MAX(CASE WHEN TAG='CashAndCashEquivalentsAtCarryingValue' THEN VALUE_NUM END) AS CASH_AND_EQUIVALENTS,
        MAX(CASE WHEN TAG='LongTermDebt' THEN VALUE_NUM END) AS LONG_TERM_DEBT,
        MAX(CASE WHEN TAG='NetCashProvidedByUsedInOperatingActivities' THEN VALUE_NUM END) AS OPERATING_CASH_FLOW,
        MAX(CASE WHEN TAG='NetCashProvidedByUsedInFinancingActivities' THEN VALUE_NUM END) AS FINANCING_CASH_FLOW,
        MAX(CASE WHEN TAG='PaymentsToAcquirePropertyPlantAndEquipment' THEN VALUE_NUM END) AS CAPEX,
        MAX(CASE WHEN TAG='DepreciationDepletionAndAmortization' THEN VALUE_NUM END) AS DEPRECIATION,
        MAX(CASE WHEN TAG IN ('EntityCommonStockSharesOutstanding','WeightedAverageNumberOfSharesOutstandingBasic') THEN VALUE_NUM END) AS SHARES_OUTSTANDING
    FROM sec_raw GROUP BY CIK, ADSH, PERIOD_END_DATE, COVERED_QTRS
),
deduped AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY CIK, PERIOD_END_DATE, FISCAL_PERIOD
        ORDER BY (CASE WHEN REVENUE IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN NET_INCOME IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN TOTAL_ASSETS IS NOT NULL THEN 1 ELSE 0 END) DESC
    ) AS RN
    FROM pivoted
    WHERE REVENUE IS NOT NULL OR TOTAL_ASSETS IS NOT NULL OR OPERATING_CASH_FLOW IS NOT NULL
)
SELECT
    ROW_NUMBER() OVER (ORDER BY oc.ISSUER_ID, d.PERIOD_END_DATE DESC) AS FINANCIAL_ID,
    oc.ISSUER_ID, oc.TICKER, oc.COMPANY_NAME, oc.GICS_SECTOR,
    d.PERIOD_END_DATE, d.FISCAL_PERIOD,
    d.REVENUE, d.NET_INCOME, d.GROSS_PROFIT, d.OPERATING_INCOME,
    d.EPS_BASIC, d.EPS_DILUTED, d.RD_EXPENSE, d.INTEREST_EXPENSE,
    d.TOTAL_ASSETS, d.TOTAL_LIABILITIES, d.TOTAL_EQUITY,
    d.CASH_AND_EQUIVALENTS, d.LONG_TERM_DEBT,
    d.OPERATING_CASH_FLOW, d.FINANCING_CASH_FLOW, d.CAPEX, d.DEPRECIATION, d.SHARES_OUTSTANDING,
    CASE WHEN d.REVENUE > 0 THEN ROUND(d.GROSS_PROFIT / d.REVENUE * 100, 2) END AS GROSS_MARGIN_PCT,
    CASE WHEN d.REVENUE > 0 THEN ROUND(d.OPERATING_INCOME / d.REVENUE * 100, 2) END AS OPERATING_MARGIN_PCT,
    CASE WHEN d.REVENUE > 0 THEN ROUND(d.NET_INCOME / d.REVENUE * 100, 2) END AS NET_MARGIN_PCT,
    CASE WHEN d.TOTAL_EQUITY > 0 THEN ROUND(d.NET_INCOME / d.TOTAL_EQUITY * 100, 2) END AS ROE_PCT,
    CASE WHEN d.TOTAL_EQUITY > 0 THEN ROUND(d.LONG_TERM_DEBT / d.TOTAL_EQUITY, 3) END AS DEBT_TO_EQUITY,
    d.OPERATING_CASH_FLOW - ABS(COALESCE(d.CAPEX, 0)) AS FREE_CASH_FLOW,
    'SNOWFLAKE_PUBLIC_DATA_PAID' AS DATA_SOURCE, CURRENT_TIMESTAMP() AS LOADED_AT
FROM deduped d
JOIN our_companies oc ON d.CIK = oc.CIK
WHERE d.RN = 1;

-- ---------------------------------------------------------------------------
-- 2.3 FACT_SEC_SEGMENTS — Revenue by segment
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_SEC_SEGMENTS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY i.ISSUER_ID, s.PERIOD_END_DATE DESC) AS SEGMENT_ID,
    i.ISSUER_ID, i.TICKER, i.COMPANY_NAME, i.GICS_SECTOR,
    s.PERIOD_END_DATE, s.VARIABLE_NAME AS SEGMENT_NAME,
    s.VALUE AS SEGMENT_REVENUE,
    'SNOWFLAKE_PUBLIC_DATA_PAID' AS DATA_SOURCE, CURRENT_TIMESTAMP() AS LOADED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_METRICS_TIMESERIES s
JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON s.COMPANY_ID = i.PROVIDER_COMPANY_ID
WHERE s.PERIOD_END_DATE >= DATEADD(YEAR, -3, CURRENT_DATE()) AND s.VALUE IS NOT NULL AND s.VALUE > 0;

-- ---------------------------------------------------------------------------
-- 2.4 FACT_TREASURY_YIELDS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_TREASURY_YIELDS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY t.DATE, a.VARIABLE_NAME) AS YIELD_ID,
    t.DATE, a.VARIABLE_NAME AS MATURITY_LABEL,
    CASE
        WHEN a.VARIABLE_NAME LIKE '%1 Mo%' THEN '1M' WHEN a.VARIABLE_NAME LIKE '%3 Mo%' THEN '3M'
        WHEN a.VARIABLE_NAME LIKE '%6 Mo%' THEN '6M' WHEN a.VARIABLE_NAME LIKE '%1 Yr%' THEN '1Y'
        WHEN a.VARIABLE_NAME LIKE '%2 Yr%' THEN '2Y' WHEN a.VARIABLE_NAME LIKE '%5 Yr%' THEN '5Y'
        WHEN a.VARIABLE_NAME LIKE '%7 Yr%' THEN '7Y' WHEN a.VARIABLE_NAME LIKE '%10 Yr%' THEN '10Y'
        WHEN a.VARIABLE_NAME LIKE '%20 Yr%' THEN '20Y' WHEN a.VARIABLE_NAME LIKE '%30 Yr%' THEN '30Y'
        ELSE 'OTHER'
    END AS MATURITY_CODE,
    t.VALUE AS YIELD_PCT, 'US_TREASURY' AS DATA_SOURCE, CURRENT_TIMESTAMP() AS LOADED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.US_TREASURY_TIMESERIES t
JOIN SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.US_TREASURY_ATTRIBUTES a ON t.VARIABLE = a.VARIABLE
WHERE a.VARIABLE_NAME LIKE 'Treasury Par Yield Curve Rate%'
  AND t.DATE >= DATEADD(YEAR, -3, CURRENT_DATE()) AND t.VALUE IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2.5 FACT_ECONOMIC_INDICATORS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_ECONOMIC_INDICATORS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY t.DATE, a.VARIABLE_NAME) AS INDICATOR_ID,
    t.DATE, 'US' AS COUNTRY, a.VARIABLE_NAME AS INDICATOR_NAME, a.MEASURE, a.UNIT, t.VALUE,
    a.SEASONALLY_ADJUSTED,
    CASE
        WHEN UPPER(a.VARIABLE_NAME) LIKE '%GDP%' OR UPPER(a.MEASURE) LIKE '%GROSS DOMESTIC%' THEN 'GDP'
        WHEN UPPER(a.VARIABLE_NAME) LIKE '%CPI%' OR UPPER(a.MEASURE) LIKE '%CONSUMER PRICE%' THEN 'INFLATION'
        WHEN UPPER(a.VARIABLE_NAME) LIKE '%UNEMPLOYMENT%' THEN 'UNEMPLOYMENT'
        WHEN UPPER(a.VARIABLE_NAME) LIKE '%FED FUND%' THEN 'INTEREST_RATE'
        ELSE 'OTHER'
    END AS INDICATOR_CATEGORY,
    'FRED' AS DATA_SOURCE, CURRENT_TIMESTAMP() AS LOADED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.FINANCIAL_ECONOMIC_INDICATORS_TIMESERIES t
JOIN SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.FINANCIAL_ECONOMIC_INDICATORS_ATTRIBUTES a ON t.VARIABLE = a.VARIABLE
WHERE t.DATE >= DATEADD(YEAR, -3, CURRENT_DATE()) AND t.VALUE IS NOT NULL
  AND (UPPER(a.VARIABLE_NAME) LIKE '%GDP%' OR UPPER(a.VARIABLE_NAME) LIKE '%CPI%'
       OR UPPER(a.VARIABLE_NAME) LIKE '%UNEMPLOYMENT%' OR UPPER(a.VARIABLE_NAME) LIKE '%FED FUND%'
       OR UPPER(a.MEASURE) LIKE '%CONSUMER PRICE%' OR UPPER(a.MEASURE) LIKE '%GROSS DOMESTIC PRODUCT%');

-- ---------------------------------------------------------------------------
-- 2.6 FACT_POLICY_RATES
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_POLICY_RATES AS
SELECT
    ROW_NUMBER() OVER (ORDER BY t.DATE DESC, a.VARIABLE_NAME) AS RATE_ID,
    t.DATE, a.VARIABLE_NAME AS RATE_NAME, a.GEO_NAME AS COUNTRY, t.VALUE AS RATE_PCT,
    a.UNIT, a.FREQUENCY, 'BIS' AS DATA_SOURCE, CURRENT_TIMESTAMP() AS LOADED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.BANK_FOR_INTERNATIONAL_SETTLEMENTS_TIMESERIES t
JOIN SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.BANK_FOR_INTERNATIONAL_SETTLEMENTS_ATTRIBUTES a ON t.VARIABLE = a.VARIABLE
WHERE UPPER(a.VARIABLE_NAME) LIKE '%POLICY%RATE%'
  AND t.DATE >= DATEADD(YEAR, -3, CURRENT_DATE()) AND t.VALUE IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2.7 FACT_FX_RATES
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_FX_RATES AS
SELECT
    ROW_NUMBER() OVER (ORDER BY DATE DESC, VARIABLE_NAME) AS FX_ID,
    DATE, VARIABLE_NAME AS CURRENCY_PAIR, QUOTE_CURRENCY_ID AS QUOTE_CURRENCY,
    BASE_CURRENCY_ID AS BASE_CURRENCY, VALUE AS EXCHANGE_RATE,
    'CYBERSYN' AS DATA_SOURCE, CURRENT_TIMESTAMP() AS LOADED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.FX_RATES_TIMESERIES
WHERE BASE_CURRENCY_ID = 'USD' AND DATE >= DATEADD(YEAR, -3, CURRENT_DATE()) AND VALUE IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2.8 FACT_INSIDER_TRANSACTIONS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_INSIDER_TRANSACTIONS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY sit.TRANSACTION_DATE DESC) AS INSIDER_TX_ID,
    i.ISSUER_ID, i.TICKER, i.COMPANY_NAME, sit.ISSUER_NAME, sit.FORM_TYPE,
    sit.TRANSACTION_DATE, sit.SECURITY_TITLE, sit.TRANSACTION_TYPE,
    sit.TRANSACTION_SHARES, sit.TRANSACTION_PRICE_PER_SHARE,
    sit.POST_TRANSACTION_SHARES_OWNED, sit.OWNERSHIP,
    'SEC_FORM4' AS DATA_SOURCE, CURRENT_TIMESTAMP() AS LOADED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_INSIDER_TRADING_SECURITIES_INDEX sit
JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON sit.ISSUER_CIK = i.CIK
WHERE sit.TRANSACTION_DATE >= DATEADD(YEAR, -3, CURRENT_DATE()) AND sit.TRANSACTION_DATE IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2.9 FACT_INSTITUTIONAL_HOLDINGS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_INSTITUTIONAL_HOLDINGS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY idx.FILING_DATE DESC, att.PRIMARY_TICKER) AS HOLDING_ID,
    i.ISSUER_ID, i.TICKER, i.COMPANY_NAME,
    idx.FILING_MANAGER_NAME AS INSTITUTION_NAME, idx.FILING_DATE,
    att.MARKET_VALUE AS MARKET_VALUE_USD, att.NUMBER_OF_SHARES AS SHARES_HELD,
    att.INVESTMENT_DISCRETION,
    'SEC_13F' AS DATA_SOURCE, CURRENT_TIMESTAMP() AS LOADED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_HOLDING_FILING_INDEX idx
JOIN SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_HOLDING_FILING_ATTRIBUTES att ON idx.ADSH = att.ADSH
JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON att.PRIMARY_TICKER = i.TICKER
WHERE idx.FILING_DATE >= DATEADD(YEAR, -2, CURRENT_DATE());

-- ---------------------------------------------------------------------------
-- 2.10 FACT_COUNTRY_EMISSIONS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_COUNTRY_EMISSIONS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY t.DATE DESC, a.VARIABLE_NAME) AS EMISSION_ID,
    t.DATE AS YEAR_DATE, a.VARIABLE_NAME AS INDICATOR_NAME, t.GEO_ID AS COUNTRY,
    a.SECTOR, t.VALUE AS EMISSION_VALUE, a.UNIT,
    'CLIMATE_WATCH' AS DATA_SOURCE, CURRENT_TIMESTAMP() AS LOADED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.CLIMATE_WATCH_TIMESERIES t
JOIN SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.CLIMATE_WATCH_ATTRIBUTES a ON t.VARIABLE = a.VARIABLE
WHERE t.VALUE IS NOT NULL AND t.DATE >= DATEADD(YEAR, -10, CURRENT_DATE());

-- ═══════════════════════════════════════════════════════════════════════════════
-- PART 3: DERIVED TABLES & VIEWS (depend on both dimensions AND market data)
-- ═══════════════════════════════════════════════════════════════════════════════
USE SCHEMA CURATED;

-- ---------------------------------------------------------------------------
-- 3.1 FACT_POSITION_DAILY — Dynamic portfolio holdings
--     Uses market-cap proxy (price × avg volume) to rank companies.
--     Each portfolio selects top N by sector filter, weights by relative size.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_POSITION_DAILY AS
WITH size_rank AS (
    -- Rank all issuers by liquidity proxy (latest price × 30-day avg volume)
    SELECT
        i.ISSUER_ID, i.TICKER, i.GICS_SECTOR,
        sp.PRICE_CLOSE,
        sp.AVG_VOLUME,
        sp.PRICE_CLOSE * sp.AVG_VOLUME AS SIZE_PROXY,
        ROW_NUMBER() OVER (ORDER BY sp.PRICE_CLOSE * sp.AVG_VOLUME DESC) AS OVERALL_RANK,
        ROW_NUMBER() OVER (PARTITION BY i.GICS_SECTOR ORDER BY sp.PRICE_CLOSE * sp.AVG_VOLUME DESC) AS SECTOR_RANK
    FROM DIM_ISSUER i
    JOIN (
        SELECT TICKER,
               MAX(CASE WHEN RN = 1 THEN PRICE_CLOSE END) AS PRICE_CLOSE,
               AVG(VOLUME) AS AVG_VOLUME
        FROM (
            SELECT TICKER, PRICE_CLOSE, VOLUME,
                   ROW_NUMBER() OVER (PARTITION BY TICKER ORDER BY PRICE_DATE DESC) AS RN
            FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES
            WHERE PRICE_DATE >= DATEADD(DAY, -30, CURRENT_DATE())
        )
        GROUP BY TICKER
        HAVING AVG_VOLUME > 0
    ) sp ON i.TICKER = sp.TICKER
),
portfolio_assignments AS (
    -- Portfolio 1: ORBIT Technology & Infrastructure — top 40 tech/comms by size
    SELECT 1 AS PORTFOLIO_ID, ISSUER_ID, TICKER, SIZE_PROXY, PRICE_CLOSE
    FROM size_rank
    WHERE GICS_SECTOR IN ('Information Technology', 'Communication Services')
      AND SECTOR_RANK <= 40

    UNION ALL

    -- Portfolio 2: ORBIT Global Flagship Multi-Asset — top 100 overall
    SELECT 2, ISSUER_ID, TICKER, SIZE_PROXY, PRICE_CLOSE
    FROM size_rank WHERE OVERALL_RANK <= 100

    UNION ALL

    -- Portfolio 3: ORBIT ESG Leaders — top 60 excluding Energy
    SELECT 3, ISSUER_ID, TICKER, SIZE_PROXY, PRICE_CLOSE
    FROM size_rank
    WHERE GICS_SECTOR != 'Energy' AND OVERALL_RANK <= 60

    UNION ALL

    -- Portfolio 4: ORBIT US Core Equity — top 50 overall (broad)
    SELECT 4, ISSUER_ID, TICKER, SIZE_PROXY, PRICE_CLOSE
    FROM size_rank WHERE OVERALL_RANK <= 50

    UNION ALL

    -- Portfolio 5: ORBIT Renewable & Climate — top 20 Utilities + top 10 Industrials
    SELECT 5, ISSUER_ID, TICKER, SIZE_PROXY, PRICE_CLOSE
    FROM size_rank
    WHERE (GICS_SECTOR = 'Utilities' AND SECTOR_RANK <= 20)
       OR (GICS_SECTOR = 'Industrials' AND SECTOR_RANK <= 10)

    UNION ALL

    -- Portfolio 6: ORBIT Sustainable Global — top 50 ex-Energy
    SELECT 6, ISSUER_ID, TICKER, SIZE_PROXY, PRICE_CLOSE
    FROM size_rank WHERE GICS_SECTOR != 'Energy' AND OVERALL_RANK <= 50

    UNION ALL

    -- Portfolio 7: ORBIT AI & Digital Innovation — top 30 IT only
    SELECT 7, ISSUER_ID, TICKER, SIZE_PROXY, PRICE_CLOSE
    FROM size_rank
    WHERE GICS_SECTOR = 'Information Technology' AND SECTOR_RANK <= 30

    UNION ALL

    -- Portfolio 8: ORBIT Global Balanced 60/40 — top 40 overall (equity portion)
    SELECT 8, ISSUER_ID, TICKER, SIZE_PROXY, PRICE_CLOSE
    FROM size_rank WHERE OVERALL_RANK <= 40

    UNION ALL

    -- Portfolio 9: ORBIT Tech Disruptors — ranks 10-40 in IT (mid-large tech)
    SELECT 9, ISSUER_ID, TICKER, SIZE_PROXY, PRICE_CLOSE
    FROM size_rank
    WHERE GICS_SECTOR = 'Information Technology' AND SECTOR_RANK BETWEEN 5 AND 35

    UNION ALL

    -- Portfolio 10: ORBIT US Value — top Financials + Energy + Industrials + Staples
    SELECT 10, ISSUER_ID, TICKER, SIZE_PROXY, PRICE_CLOSE
    FROM size_rank
    WHERE GICS_SECTOR IN ('Financials', 'Energy', 'Industrials', 'Consumer Staples')
      AND SECTOR_RANK <= 12

    UNION ALL

    -- Portfolio 11: ORBIT Multi-Asset Income — top Utilities + Financials + Staples
    SELECT 11, ISSUER_ID, TICKER, SIZE_PROXY, PRICE_CLOSE
    FROM size_rank
    WHERE GICS_SECTOR IN ('Utilities', 'Financials', 'Consumer Staples', 'Real Estate')
      AND SECTOR_RANK <= 10
),
weighted AS (
    -- Market-cap-weight within each portfolio
    SELECT
        pa.PORTFOLIO_ID, pa.ISSUER_ID, pa.TICKER, pa.PRICE_CLOSE,
        pa.SIZE_PROXY / SUM(pa.SIZE_PROXY) OVER (PARTITION BY pa.PORTFOLIO_ID) AS WEIGHT,
        p.AUM_USD
    FROM portfolio_assignments pa
    JOIN DIM_PORTFOLIO p ON pa.PORTFOLIO_ID = p.PORTFOLIO_ID
)
SELECT
    ROW_NUMBER() OVER (ORDER BY PORTFOLIO_ID, WEIGHT DESC) AS POSITION_ID,
    PORTFOLIO_ID, ISSUER_ID, TICKER, WEIGHT,
    PRICE_CLOSE AS CURRENT_PRICE,
    ROUND(AUM_USD * WEIGHT / NULLIF(PRICE_CLOSE, 0)) AS SHARES,
    AUM_USD * WEIGHT AS POSITION_VALUE_USD,
    CURRENT_DATE() AS AS_OF_DATE,
    CURRENT_TIMESTAMP() AS LOADED_AT
FROM weighted
WHERE WEIGHT > 0;

-- ---------------------------------------------------------------------------
-- 3.2 V_SECURITY_RETURNS — Daily returns from prices
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW V_SECURITY_RETURNS AS
SELECT
    TICKER, ISSUER_ID, COMPANY_NAME, GICS_SECTOR, PRICE_DATE, PRICE_CLOSE,
    LAG(PRICE_CLOSE) OVER (PARTITION BY TICKER ORDER BY PRICE_DATE) AS PREV_CLOSE,
    ROUND((PRICE_CLOSE / NULLIF(LAG(PRICE_CLOSE) OVER (PARTITION BY TICKER ORDER BY PRICE_DATE), 0)) - 1, 6) AS DAILY_RETURN
FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES;
