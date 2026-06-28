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
-- 1.1 DIM_ISSUER — Company reference from Cybersyn + SEC
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_ISSUER AS
WITH demo_companies AS (
    SELECT COLUMN1 AS TICKER, COLUMN2 AS COMPANY_NAME, COLUMN3 AS GICS_SECTOR,
           COLUMN4 AS CIK, COLUMN5 AS PROVIDER_COMPANY_ID
    FROM VALUES
        ('AAPL','Apple Inc.','Information Technology','0000320193','sp_zgtw35'),
        ('MSFT','Microsoft Corporation','Information Technology','0000789019','sp_dkh3g1'),
        ('GOOGL','Alphabet Inc.','Communication Services','0001652044','sp_7p55dh'),
        ('AMZN','Amazon.com Inc.','Consumer Discretionary','0001018724','sp_x14sbl'),
        ('NVDA','NVIDIA Corporation','Information Technology','0001045810','sp_w3mdwp'),
        ('META','Meta Platforms Inc.','Communication Services','0001326801','sp_h8d2dy'),
        ('TSLA','Tesla Inc.','Consumer Discretionary','0001318605','sp_fmrkdj'),
        ('BRK.B','Berkshire Hathaway Inc.','Financials','0001067983','sp_txm35g'),
        ('JPM','JPMorgan Chase & Co.','Financials','0000019617','sp_l3yt5g'),
        ('V','Visa Inc.','Financials','0001403161','sp_pgbnl8'),
        ('JNJ','Johnson & Johnson','Health Care','0000200406','sp_mbxfls'),
        ('UNH','UnitedHealth Group','Health Care','0000731766','sp_k2g0td'),
        ('HD','Home Depot Inc.','Consumer Discretionary','0000354950','sp_gmy685'),
        ('PG','Procter & Gamble Co.','Consumer Staples','0000080424','sp_7xjjjf'),
        ('MA','Mastercard Inc.','Financials','0001141391','sp_kxwzhk'),
        ('XOM','Exxon Mobil Corporation','Energy','0000034088','sp_x24s3b'),
        ('LLY','Eli Lilly and Company','Health Care','0000059478','sp_2b4hck'),
        ('ABBV','AbbVie Inc.','Health Care','0001551152','sp_szh0gg'),
        ('MRK','Merck & Co. Inc.','Health Care','0000310158','sp_39k0p5'),
        ('AVGO','Broadcom Inc.','Information Technology','0001730168','sp_v7wgzh'),
        ('PEP','PepsiCo Inc.','Consumer Staples','0000077476','sp_ht5fh3'),
        ('KO','Coca-Cola Company','Consumer Staples','0000021344','sp_p40xgf'),
        ('COST','Costco Wholesale','Consumer Staples','0000909832','sp_kj5fhx'),
        ('TMO','Thermo Fisher Scientific','Health Care','0000097745','sp_0z7plp'),
        ('ADBE','Adobe Inc.','Information Technology','0000796343','sp_gk2wz8'),
        ('CRM','Salesforce Inc.','Information Technology','0001108524','sp_brcqfp'),
        ('CSCO','Cisco Systems Inc.','Information Technology','0000858877','sp_gf2xm4'),
        ('NFLX','Netflix Inc.','Communication Services','0001065280','sp_q4t4j5'),
        ('AMD','Advanced Micro Devices','Information Technology','0000002488','sp_c6h5mz'),
        ('INTC','Intel Corporation','Information Technology','0000050863','sp_dcgjp4'),
        ('IBM','IBM Corporation','Information Technology','0000051143','sp_gmwryc'),
        ('ORCL','Oracle Corporation','Information Technology','0001341439','sp_dhn5wd'),
        ('ACN','Accenture plc','Information Technology','0001281761','sp_nk5vn2'),
        ('TXN','Texas Instruments','Information Technology','0000097476','sp_xscnj8'),
        ('QCOM','Qualcomm Inc.','Information Technology','0000804328','sp_vrlvkx'),
        ('NOW','ServiceNow Inc.','Information Technology','0001373715','sp_d3bftw'),
        ('INTU','Intuit Inc.','Information Technology','0000896878','sp_0cjx2d'),
        ('AMAT','Applied Materials','Information Technology','0000006951','sp_wk5xhz'),
        ('GS','Goldman Sachs Group','Financials','0000886982','sp_0yxsml'),
        ('MS','Morgan Stanley','Financials','0000895421','sp_2xg6m7'),
        ('BAC','Bank of America','Financials','0000070858','sp_4mfbp8'),
        ('WFC','Wells Fargo & Co.','Financials','0000072971','sp_ysxhz5'),
        ('C','Citigroup Inc.','Financials','0000831001','sp_fq8rk3'),
        ('BLK','BlackRock Inc.','Financials','0001364742','sp_c9t8g4'),
        ('SCHW','Charles Schwab','Financials','0000316709','sp_bfhs2d'),
        ('PFE','Pfizer Inc.','Health Care','0000078003','sp_8t3fwc'),
        ('NKE','Nike Inc.','Consumer Discretionary','0000320187','sp_x7zsd4'),
        ('DIS','Walt Disney Co.','Communication Services','0001744489','sp_yt3bd5'),
        ('BA','Boeing Company','Industrials','0000012927','sp_bcv5dx'),
        ('CAT','Caterpillar Inc.','Industrials','0000018230','sp_rl5gpw'),
        ('GE','GE Aerospace','Industrials','0000040554','sp_4zxjnf'),
        ('HON','Honeywell International','Industrials','0000773840','sp_fwl2jp'),
        ('UPS','United Parcel Service','Industrials','0001090727','sp_hjcm5k'),
        ('RTX','RTX Corporation','Industrials','0000101829','sp_qnlg3y'),
        ('DE','Deere & Company','Industrials','0000315189','sp_kvzn5p'),
        ('MMM','3M Company','Industrials','0000066740','sp_wjl7km'),
        ('CVX','Chevron Corporation','Energy','0000093410','sp_b6n3fh'),
        ('COP','ConocoPhillips','Energy','0001163165','sp_gfnbp2'),
        ('SLB','Schlumberger NV','Energy','0000087347','sp_jkf5m4'),
        ('NEE','NextEra Energy','Utilities','0000753308','sp_tqfm8j'),
        ('DUK','Duke Energy','Utilities','0001326160','sp_hx3ybf'),
        ('SO','Southern Company','Utilities','0000092122','sp_kl4dxp'),
        ('WMT','Walmart Inc.','Consumer Staples','0000104169','sp_gh7xcm'),
        ('MCD','McDonalds Corporation','Consumer Discretionary','0000063908','sp_vmk3hq'),
        ('SBUX','Starbucks Corporation','Consumer Discretionary','0000829224','sp_k8fjt2'),
        ('LOW','Lowes Companies','Consumer Discretionary','0000060667','sp_dl3n9v'),
        ('TGT','Target Corporation','Consumer Discretionary','0000027419','sp_hj5vkf')
),
enriched AS (
    SELECT
        dc.TICKER, dc.COMPANY_NAME, dc.GICS_SECTOR, dc.CIK, dc.PROVIDER_COMPANY_ID,
        ci.LEI
    FROM demo_companies dc
    LEFT JOIN SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_INDEX ci
        ON dc.PROVIDER_COMPANY_ID = ci.COMPANY_ID
)
SELECT
    ROW_NUMBER() OVER (ORDER BY COMPANY_NAME) AS ISSUER_ID,
    TICKER, COMPANY_NAME, GICS_SECTOR, CIK, PROVIDER_COMPANY_ID, LEI,
    'US' AS COUNTRY,
    'SNOWFLAKE_PUBLIC_DATA_PAID' AS DATA_SOURCE,
    CURRENT_TIMESTAMP() AS LOADED_AT
FROM enriched;

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
-- 3.1 FACT_POSITION_DAILY — Model portfolio holdings (weights x real prices)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_POSITION_DAILY AS
WITH portfolio_weights AS (
    SELECT 1 AS PORTFOLIO_ID, i.ISSUER_ID, i.TICKER,
           CASE
               WHEN i.TICKER IN ('AAPL','MSFT','NVDA','GOOGL','AMZN') THEN 0.08
               WHEN i.TICKER IN ('META','TSLA','AVGO','AMD','CRM') THEN 0.05
               WHEN i.GICS_SECTOR = 'Information Technology' THEN 0.025
               ELSE 0.015
           END AS TARGET_WEIGHT
    FROM DIM_ISSUER i
    WHERE i.GICS_SECTOR IN ('Information Technology','Communication Services','Consumer Discretionary')
    UNION ALL
    SELECT 4, i.ISSUER_ID, i.TICKER, 1.0 / COUNT(*) OVER () FROM DIM_ISSUER i
    UNION ALL
    SELECT 3, i.ISSUER_ID, i.TICKER, 1.0 / COUNT(*) OVER () FROM DIM_ISSUER i WHERE i.GICS_SECTOR != 'Energy'
    UNION ALL
    SELECT 2, i.ISSUER_ID, i.TICKER, 1.0 / COUNT(*) OVER () FROM DIM_ISSUER i
),
latest_prices AS (
    SELECT TICKER, PRICE_CLOSE
    FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TICKER ORDER BY PRICE_DATE DESC) = 1
),
valued AS (
    SELECT pw.PORTFOLIO_ID, pw.ISSUER_ID, pw.TICKER, pw.TARGET_WEIGHT,
           lp.PRICE_CLOSE AS CURRENT_PRICE,
           p.AUM_USD * pw.TARGET_WEIGHT AS POSITION_VALUE_USD,
           ROUND(p.AUM_USD * pw.TARGET_WEIGHT / NULLIF(lp.PRICE_CLOSE, 0)) AS SHARES,
           CURRENT_DATE() AS AS_OF_DATE
    FROM portfolio_weights pw
    JOIN DIM_PORTFOLIO p ON pw.PORTFOLIO_ID = p.PORTFOLIO_ID
    LEFT JOIN latest_prices lp ON pw.TICKER = lp.TICKER
    WHERE pw.TARGET_WEIGHT > 0
)
SELECT
    ROW_NUMBER() OVER (ORDER BY PORTFOLIO_ID, TARGET_WEIGHT DESC) AS POSITION_ID,
    PORTFOLIO_ID, ISSUER_ID, TICKER, TARGET_WEIGHT AS WEIGHT,
    CURRENT_PRICE, SHARES, POSITION_VALUE_USD, AS_OF_DATE,
    CURRENT_TIMESTAMP() AS LOADED_AT
FROM valued WHERE CURRENT_PRICE IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3.2 V_SECURITY_RETURNS — Daily returns from prices
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW V_SECURITY_RETURNS AS
SELECT
    TICKER, ISSUER_ID, COMPANY_NAME, GICS_SECTOR, PRICE_DATE, PRICE_CLOSE,
    LAG(PRICE_CLOSE) OVER (PARTITION BY TICKER ORDER BY PRICE_DATE) AS PREV_CLOSE,
    ROUND((PRICE_CLOSE / NULLIF(LAG(PRICE_CLOSE) OVER (PARTITION BY TICKER ORDER BY PRICE_DATE), 0)) - 1, 6) AS DAILY_RETURN
FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES;
