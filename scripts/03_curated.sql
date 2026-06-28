-- ============================================================================
-- ORBIT Investment Intelligence — Curated Layer (Dimensions + Model Portfolios)
-- ============================================================================
-- Creates dimension tables, model portfolios, and derived analytics views.
-- DIM_ISSUER must be created FIRST as market data tables depend on it.
-- ============================================================================

USE ROLE ORBIT_DEMO_ROLE;
USE DATABASE ORBIT_DEMO;
USE SCHEMA CURATED;
USE WAREHOUSE ORBIT_DEMO_WH;

-- ---------------------------------------------------------------------------
-- 1. DIM_ISSUER — Company reference from Cybersyn + SEC
-- ---------------------------------------------------------------------------
-- NOTE: This must run BEFORE 02_market_data.sql
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
    TICKER,
    COMPANY_NAME,
    GICS_SECTOR,
    CIK,
    PROVIDER_COMPANY_ID,
    LEI,
    'US' AS COUNTRY,
    'SNOWFLAKE_PUBLIC_DATA_PAID' AS DATA_SOURCE,
    CURRENT_TIMESTAMP() AS LOADED_AT
FROM enriched;

-- ---------------------------------------------------------------------------
-- 2. DIM_SECURITY — One equity per issuer
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_SECURITY AS
SELECT
    ISSUER_ID AS SECURITY_ID,
    ISSUER_ID,
    TICKER,
    COMPANY_NAME || ' Common Stock' AS SECURITY_NAME,
    'Equity' AS ASSET_CLASS,
    'Common Stock' AS SECURITY_TYPE,
    'USD' AS CURRENCY,
    CURRENT_TIMESTAMP() AS LOADED_AT
FROM DIM_ISSUER;

-- ---------------------------------------------------------------------------
-- 3. DIM_PORTFOLIO — 10 ORBIT model portfolios
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
-- 4. DIM_BENCHMARK — Benchmark reference
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_BENCHMARK AS
SELECT COLUMN1 AS BENCHMARK_ID, COLUMN2 AS BENCHMARK_CODE,
       COLUMN3 AS BENCHMARK_NAME, COLUMN4 AS ETF_PROXY
FROM VALUES
    (1, 'SPX', 'S&P 500', 'SPY'),
    (2, 'ACWI', 'MSCI ACWI', 'ACWI'),
    (3, 'RUT', 'Russell 2000', 'IWM'),
    (4, 'NDX', 'Nasdaq 100', 'QQQ'),
    (5, 'AGG', 'Bloomberg US Agg', 'AGG'),
    (6, 'HYG', 'US High Yield', 'HYG'),
    (7, 'LQD', 'US Investment Grade', 'LQD'),
    (8, 'TLT', 'US 20+ Year Treasury', 'TLT'),
    (9, 'GLD', 'Gold', 'GLD'),
    (10, 'EEM', 'MSCI Emerging Markets', 'EEM');

-- ---------------------------------------------------------------------------
-- 5. FACT_POSITION_DAILY — Model portfolio holdings (weights x real prices)
-- ---------------------------------------------------------------------------
-- Assigns securities to portfolios with model weights, then values at real prices
CREATE OR REPLACE TABLE FACT_POSITION_DAILY AS
WITH portfolio_weights AS (
    -- Tech & Infrastructure portfolio (45 holdings, tech-heavy)
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

    -- US Core Equity (broad market)
    SELECT 4, i.ISSUER_ID, i.TICKER,
           1.0 / COUNT(*) OVER () AS TARGET_WEIGHT
    FROM DIM_ISSUER i

    UNION ALL

    -- ESG Leaders (exclude energy)
    SELECT 3, i.ISSUER_ID, i.TICKER,
           1.0 / COUNT(*) OVER () AS TARGET_WEIGHT
    FROM DIM_ISSUER i
    WHERE i.GICS_SECTOR != 'Energy'

    UNION ALL

    -- Global Flagship Multi-Asset
    SELECT 2, i.ISSUER_ID, i.TICKER,
           1.0 / COUNT(*) OVER () AS TARGET_WEIGHT
    FROM DIM_ISSUER i
),
-- Get latest prices for valuation
latest_prices AS (
    SELECT TICKER, PRICE_CLOSE
    FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TICKER ORDER BY PRICE_DATE DESC) = 1
),
valued AS (
    SELECT
        pw.PORTFOLIO_ID,
        pw.ISSUER_ID,
        pw.TICKER,
        pw.TARGET_WEIGHT,
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
    PORTFOLIO_ID, ISSUER_ID, TICKER,
    TARGET_WEIGHT AS WEIGHT,
    CURRENT_PRICE,
    SHARES,
    POSITION_VALUE_USD,
    AS_OF_DATE,
    CURRENT_TIMESTAMP() AS LOADED_AT
FROM valued
WHERE CURRENT_PRICE IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6. V_SECURITY_RETURNS — Daily returns calculated from prices
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW V_SECURITY_RETURNS AS
SELECT
    TICKER,
    ISSUER_ID,
    COMPANY_NAME,
    GICS_SECTOR,
    PRICE_DATE,
    PRICE_CLOSE,
    LAG(PRICE_CLOSE) OVER (PARTITION BY TICKER ORDER BY PRICE_DATE) AS PREV_CLOSE,
    ROUND((PRICE_CLOSE / NULLIF(LAG(PRICE_CLOSE) OVER (PARTITION BY TICKER ORDER BY PRICE_DATE), 0)) - 1, 6) AS DAILY_RETURN
FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES;
