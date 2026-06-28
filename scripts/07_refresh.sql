-- ============================================================================
-- ORBIT Investment Intelligence — Daily Refresh Pipeline
-- ============================================================================
-- Dynamic Tables for auto-refreshing derived data, plus a scheduled Task
-- for full market data rebuild.
-- ============================================================================

USE ROLE ORBIT_DEMO_ROLE;
USE DATABASE ORBIT_DEMO;
USE WAREHOUSE ORBIT_DEMO_WH;

-- ---------------------------------------------------------------------------
-- 1. Dynamic Table: FACT_BENCHMARK_RETURNS
-- Auto-refreshes daily from real ETF prices
-- ---------------------------------------------------------------------------
USE SCHEMA CURATED;

CREATE OR REPLACE DYNAMIC TABLE FACT_BENCHMARK_RETURNS
    TARGET_LAG = '1 day'
    WAREHOUSE = ORBIT_DEMO_WH
AS
WITH etf_mapping AS (
    SELECT COLUMN1 AS BENCHMARK_ID, COLUMN2 AS BENCHMARK_CODE, COLUMN3 AS ETF_TICKER
    FROM VALUES
        (1, 'SPX', 'SPY'), (2, 'ACWI', 'ACWI'), (3, 'RUT', 'IWM'),
        (4, 'NDX', 'QQQ'), (5, 'AGG', 'AGG'), (6, 'HYG', 'HYG'),
        (7, 'LQD', 'LQD'), (8, 'TLT', 'TLT'), (9, 'GLD', 'GLD'),
        (10, 'EEM', 'EEM')
),
etf_closes AS (
    SELECT TICKER, DATE, VALUE AS CLOSE_PRICE
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.STOCK_PRICE_TIMESERIES
    WHERE TICKER IN ('SPY','ACWI','IWM','QQQ','AGG','HYG','LQD','TLT','GLD','EEM')
      AND VARIABLE = 'post-market_close'
      AND DATE >= DATEADD('year', -3, CURRENT_DATE())
),
with_returns AS (
    SELECT TICKER, DATE, CLOSE_PRICE,
           (CLOSE_PRICE / LAG(CLOSE_PRICE) OVER (PARTITION BY TICKER ORDER BY DATE)) - 1 AS DAILY_RETURN
    FROM etf_closes
)
SELECT
    r.DATE,
    m.BENCHMARK_ID,
    m.BENCHMARK_CODE,
    ROUND(r.DAILY_RETURN, 6) AS DAILY_RETURN,
    r.CLOSE_PRICE AS ETF_CLOSE_PRICE
FROM with_returns r
JOIN etf_mapping m ON r.TICKER = m.ETF_TICKER
WHERE r.DAILY_RETURN IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. Dynamic Table: FACT_SECTOR_RETURNS
-- Auto-refreshes daily from sector ETF prices
-- ---------------------------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE FACT_SECTOR_RETURNS
    TARGET_LAG = '1 day'
    WAREHOUSE = ORBIT_DEMO_WH
AS
WITH sector_etfs AS (
    SELECT COLUMN1 AS SECTOR_NAME, COLUMN2 AS ETF_TICKER
    FROM VALUES
        ('Information Technology', 'XLK'), ('Health Care', 'XLV'),
        ('Financials', 'XLF'), ('Consumer Discretionary', 'XLY'),
        ('Communication Services', 'XLC'), ('Industrials', 'XLI'),
        ('Consumer Staples', 'XLP'), ('Energy', 'XLE'),
        ('Utilities', 'XLU'), ('Real Estate', 'XLRE'),
        ('Materials', 'XLB')
),
etf_closes AS (
    SELECT TICKER, DATE, VALUE AS CLOSE_PRICE
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.STOCK_PRICE_TIMESERIES
    WHERE TICKER IN ('XLK','XLV','XLF','XLY','XLC','XLI','XLP','XLE','XLU','XLRE','XLB')
      AND VARIABLE = 'post-market_close'
      AND DATE >= DATEADD('year', -3, CURRENT_DATE())
),
with_returns AS (
    SELECT TICKER, DATE, CLOSE_PRICE,
           (CLOSE_PRICE / LAG(CLOSE_PRICE) OVER (PARTITION BY TICKER ORDER BY DATE)) - 1 AS DAILY_RETURN
    FROM etf_closes
)
SELECT
    r.DATE,
    s.SECTOR_NAME,
    s.ETF_TICKER,
    ROUND(r.DAILY_RETURN, 6) AS DAILY_RETURN,
    r.CLOSE_PRICE AS ETF_CLOSE_PRICE
FROM with_returns r
JOIN sector_etfs s ON r.TICKER = s.ETF_TICKER
WHERE r.DAILY_RETURN IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. Scheduled Task: Full market data refresh (daily 06:00 UTC)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TASK ORBIT_DEMO.CURATED.DAILY_MARKET_DATA_REFRESH
    WAREHOUSE = ORBIT_DEMO_WH
    SCHEDULE = 'USING CRON 0 6 * * * UTC'
    COMMENT = 'Daily refresh of market data tables from Snowflake Public Data (Paid)'
AS
BEGIN
    -- Refresh stock prices (last 3 years rolling window)
    CREATE OR REPLACE TABLE ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES AS
    SELECT * FROM (
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
            FROM price_data
            GROUP BY TICKER, PRICE_DATE
        )
        SELECT
            ROW_NUMBER() OVER (ORDER BY i.ISSUER_ID, p.PRICE_DATE) AS PRICE_ID,
            i.ISSUER_ID, i.TICKER, i.COMPANY_NAME, i.GICS_SECTOR,
            p.PRICE_DATE, p.PRICE_OPEN, p.PRICE_HIGH, p.PRICE_LOW, p.PRICE_CLOSE,
            p.VOLUME::BIGINT AS VOLUME,
            'SNOWFLAKE_PUBLIC_DATA_PAID' AS DATA_SOURCE,
            CURRENT_TIMESTAMP() AS LOADED_AT
        FROM pivoted p
        JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON p.TICKER = i.TICKER
        WHERE p.PRICE_CLOSE IS NOT NULL
    );

    -- Refresh treasury yields
    CREATE OR REPLACE TABLE ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS AS
    SELECT
        ROW_NUMBER() OVER (ORDER BY t.DATE, a.VARIABLE_NAME) AS YIELD_ID,
        t.DATE, a.VARIABLE_NAME AS MATURITY_LABEL,
        CASE
            WHEN a.VARIABLE_NAME LIKE '%1 Mo%' THEN '1M'
            WHEN a.VARIABLE_NAME LIKE '%3 Mo%' THEN '3M'
            WHEN a.VARIABLE_NAME LIKE '%6 Mo%' THEN '6M'
            WHEN a.VARIABLE_NAME LIKE '%1 Yr%' THEN '1Y'
            WHEN a.VARIABLE_NAME LIKE '%2 Yr%' THEN '2Y'
            WHEN a.VARIABLE_NAME LIKE '%5 Yr%' THEN '5Y'
            WHEN a.VARIABLE_NAME LIKE '%10 Yr%' THEN '10Y'
            WHEN a.VARIABLE_NAME LIKE '%30 Yr%' THEN '30Y'
            ELSE 'OTHER'
        END AS MATURITY_CODE,
        t.VALUE AS YIELD_PCT,
        'US_TREASURY' AS DATA_SOURCE,
        CURRENT_TIMESTAMP() AS LOADED_AT
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.US_TREASURY_TIMESERIES t
    JOIN SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.US_TREASURY_ATTRIBUTES a ON t.VARIABLE = a.VARIABLE
    WHERE a.VARIABLE_NAME LIKE 'Treasury Par Yield Curve Rate%'
      AND t.DATE >= DATEADD(YEAR, -3, CURRENT_DATE())
      AND t.VALUE IS NOT NULL;
END;

-- Resume the task (starts scheduled execution)
ALTER TASK ORBIT_DEMO.CURATED.DAILY_MARKET_DATA_REFRESH RESUME;
