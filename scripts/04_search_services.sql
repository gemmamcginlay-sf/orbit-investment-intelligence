-- ============================================================================
-- ORBIT Investment Intelligence — Cortex Search Services
-- ============================================================================
-- Creates corpus staging tables from real SEC filings and earnings transcripts,
-- then builds Cortex Search Services for RAG.
-- Fully idempotent — safe to re-run.
-- ============================================================================

USE ROLE ORBIT_DEMO_ROLE;
USE DATABASE ORBIT_DEMO;
USE WAREHOUSE ORBIT_DEMO_WH;

-- ---------------------------------------------------------------------------
-- 1. SEC Filing Text corpus (10-K, 10-Q, 8-K full text)
-- ---------------------------------------------------------------------------
USE SCHEMA RAW;

CREATE OR REPLACE TABLE SEC_FILING_TEXT AS
SELECT
    ROW_NUMBER() OVER (ORDER BY i.ISSUER_ID, t.DATE DESC) AS FILING_TEXT_ID,
    i.ISSUER_ID,
    i.CIK,
    i.TICKER,
    i.COMPANY_NAME,
    i.GICS_SECTOR,
    CASE
        WHEN UPPER(a.VARIABLE_NAME) LIKE '%10-K%' THEN '10-K'
        WHEN UPPER(a.VARIABLE_NAME) LIKE '%10-Q%' THEN '10-Q'
        WHEN UPPER(a.VARIABLE_NAME) LIKE '%8-K%' THEN '8-K'
        ELSE 'OTHER'
    END AS FILING_TYPE,
    YEAR(t.DATE) AS FISCAL_YEAR,
    'Q' || QUARTER(t.DATE) AS FISCAL_QUARTER,
    i.COMPANY_NAME || ' - ' || a.VARIABLE_NAME || ' (' || t.DATE || ')' AS DOCUMENT_TITLE,
    a.VARIABLE_NAME,
    t.DATE AS PERIOD_END_DATE,
    t.VALUE::VARCHAR AS FILING_TEXT,
    LENGTH(t.VALUE::VARCHAR) AS TEXT_LENGTH,
    0 AS CHUNK_INDEX,
    'SNOWFLAKE_PUBLIC_DATA_PAID' AS DATA_SOURCE,
    CURRENT_TIMESTAMP() AS LOADED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_REPORT_TEXT_TIMESERIES t
JOIN SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_REPORT_TEXT_ATTRIBUTES a
    ON t.VARIABLE = a.VARIABLE
JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i
    ON a.CIK = i.CIK
WHERE t.DATE >= DATEADD(YEAR, -2, CURRENT_DATE())
  AND t.VALUE IS NOT NULL
  AND LENGTH(t.VALUE::VARCHAR) > 100;

-- ---------------------------------------------------------------------------
-- 2. Earnings Transcripts corpus
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE EARNINGS_TRANSCRIPTS_CORPUS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY i.ISSUER_ID, t.EVENT_START_DATE DESC) AS TRANSCRIPT_ID,
    i.ISSUER_ID,
    i.TICKER,
    i.COMPANY_NAME,
    i.GICS_SECTOR,
    t.EVENT_TYPE,
    t.EVENT_START_DATE AS EVENT_DATE,
    YEAR(t.EVENT_START_DATE) AS FISCAL_YEAR,
    'Q' || QUARTER(t.EVENT_START_DATE) AS FISCAL_PERIOD,
    i.COMPANY_NAME || ' ' || t.EVENT_TYPE || ' (' || t.EVENT_START_DATE || ')' AS DOCUMENT_TITLE,
    t.VALUE::VARCHAR AS DOCUMENT_TEXT,
    ROW_NUMBER() OVER (PARTITION BY i.TICKER, t.EVENT_START_DATE ORDER BY t.VARIABLE) AS SEGMENT_INDEX,
    'SNOWFLAKE_PUBLIC_DATA_PAID' AS DATA_SOURCE,
    CURRENT_TIMESTAMP() AS LOADED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_EVENT_TRANSCRIPTS t
JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i
    ON t.COMPANY_ID = i.PROVIDER_COMPANY_ID
WHERE t.EVENT_START_DATE >= DATEADD(YEAR, -2, CURRENT_DATE())
  AND t.VALUE IS NOT NULL
  AND LENGTH(t.VALUE::VARCHAR) > 50;

-- ---------------------------------------------------------------------------
-- 3. Cortex Search Service — SEC Filings
-- ---------------------------------------------------------------------------
USE SCHEMA AI;

CREATE OR REPLACE CORTEX SEARCH SERVICE ORBIT_SEC_FILINGS_SEARCH
    TEXT INDEXES DOCUMENT_TITLE, TICKER, COMPANY_NAME, GICS_SECTOR, FILING_TYPE
    VECTOR INDEXES FILING_TEXT (model = 'snowflake-arctic-embed-m-v1.5')
    ATTRIBUTES DOCUMENT_TITLE, TICKER, COMPANY_NAME, GICS_SECTOR, FILING_TYPE, FISCAL_YEAR, CIK, PERIOD_END_DATE
    WAREHOUSE = ORBIT_DEMO_SEARCH_WH
    TARGET_LAG = '1 day'
    AS
    SELECT
        FILING_TEXT_ID AS DOCUMENT_ID,
        DOCUMENT_TITLE,
        FILING_TEXT,
        TICKER,
        COMPANY_NAME,
        GICS_SECTOR,
        FILING_TYPE,
        FISCAL_YEAR,
        CIK,
        PERIOD_END_DATE
    FROM ORBIT_DEMO.RAW.SEC_FILING_TEXT
    WHERE FILING_TEXT IS NOT NULL
      AND TEXT_LENGTH > 100;

-- ---------------------------------------------------------------------------
-- 4. Cortex Search Service — Earnings Transcripts
-- ---------------------------------------------------------------------------
CREATE OR REPLACE CORTEX SEARCH SERVICE ORBIT_TRANSCRIPTS_SEARCH
    TEXT INDEXES DOCUMENT_TITLE, TICKER, COMPANY_NAME, GICS_SECTOR, EVENT_TYPE
    VECTOR INDEXES DOCUMENT_TEXT (model = 'snowflake-arctic-embed-m-v1.5')
    ATTRIBUTES DOCUMENT_TITLE, TICKER, COMPANY_NAME, GICS_SECTOR, EVENT_TYPE, FISCAL_YEAR, FISCAL_PERIOD, EVENT_DATE
    WAREHOUSE = ORBIT_DEMO_SEARCH_WH
    TARGET_LAG = '1 day'
    AS
    SELECT
        TRANSCRIPT_ID AS DOCUMENT_ID,
        DOCUMENT_TITLE,
        DOCUMENT_TEXT,
        TICKER,
        COMPANY_NAME,
        GICS_SECTOR,
        EVENT_TYPE,
        FISCAL_YEAR,
        FISCAL_PERIOD,
        EVENT_DATE
    FROM ORBIT_DEMO.RAW.EARNINGS_TRANSCRIPTS_CORPUS
    WHERE DOCUMENT_TEXT IS NOT NULL
      AND LENGTH(DOCUMENT_TEXT) > 50;
