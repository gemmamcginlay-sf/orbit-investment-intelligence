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
WITH filing_ciks AS (
    -- Get distinct CIK per ADSH from the financial reports table
    SELECT DISTINCT ADSH, CIK
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_ATTRIBUTES
    WHERE CIK IS NOT NULL
)
SELECT
    ROW_NUMBER() OVER (ORDER BY i.ISSUER_ID, t.ADSH) AS FILING_TEXT_ID,
    i.ISSUER_ID,
    i.CIK,
    i.TICKER,
    i.COMPANY_NAME,
    i.GICS_SECTOR,
    t.FORM_TYPE AS FILING_TYPE,
    t.VARIABLE_NAME,
    i.COMPANY_NAME || ' - ' || t.VARIABLE_NAME || ' (' || t.ADSH || ')' AS DOCUMENT_TITLE,
    t.VALUE AS FILING_TEXT,
    LENGTH(t.VALUE) AS TEXT_LENGTH,
    'SNOWFLAKE_PUBLIC_DATA_PAID' AS DATA_SOURCE,
    CURRENT_TIMESTAMP() AS LOADED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_TEXT_ATTRIBUTES t
JOIN filing_ciks fc ON t.ADSH = fc.ADSH
JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON fc.CIK = i.CIK
WHERE t.FORM_TYPE IN ('10-K', '10-Q', '8-K')
  AND t.VARIABLE_NAME LIKE '%Filing Text'
  AND LENGTH(t.VALUE) > 500
  AND t.VALUE IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. Earnings Transcripts corpus
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE EARNINGS_TRANSCRIPTS_CORPUS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY i.ISSUER_ID, t.EVENT_TIMESTAMP DESC) AS TRANSCRIPT_ID,
    i.ISSUER_ID,
    i.TICKER,
    i.COMPANY_NAME,
    i.GICS_SECTOR,
    t.EVENT_TYPE,
    t.EVENT_TIMESTAMP::DATE AS EVENT_DATE,
    t.FISCAL_YEAR,
    t.FISCAL_PERIOD,
    t.EVENT_TITLE,
    i.COMPANY_NAME || ' ' || t.EVENT_TYPE || ' - ' || t.EVENT_TITLE || ' (' || t.EVENT_TIMESTAMP::DATE || ')' AS DOCUMENT_TITLE,
    t.TRANSCRIPT:text::VARCHAR AS DOCUMENT_TEXT,
    LENGTH(t.TRANSCRIPT:text::VARCHAR) AS TEXT_LENGTH,
    'SNOWFLAKE_PUBLIC_DATA_PAID' AS DATA_SOURCE,
    CURRENT_TIMESTAMP() AS LOADED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_EVENT_TRANSCRIPT_ATTRIBUTES t
JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON t.PRIMARY_TICKER = i.TICKER
WHERE t.EVENT_TIMESTAMP >= DATEADD(YEAR, -2, CURRENT_DATE())
  AND t.TRANSCRIPT:text IS NOT NULL
  AND LENGTH(t.TRANSCRIPT:text::VARCHAR) > 100
  AND t.TRANSCRIPT_TYPE = 'SPEAKERS_ANNOTATED';

-- ---------------------------------------------------------------------------
-- 3. Cortex Search Service — SEC Filings
-- ---------------------------------------------------------------------------
USE SCHEMA AI;

CREATE OR REPLACE CORTEX SEARCH SERVICE ORBIT_SEC_FILINGS_SEARCH
    TEXT INDEXES DOCUMENT_TITLE, TICKER, COMPANY_NAME, GICS_SECTOR, FILING_TYPE
    VECTOR INDEXES FILING_TEXT (model = 'snowflake-arctic-embed-m-v1.5')
    ATTRIBUTES DOCUMENT_TITLE, TICKER, COMPANY_NAME, GICS_SECTOR, FILING_TYPE, CIK
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
        CIK
    FROM ORBIT_DEMO.RAW.SEC_FILING_TEXT
    WHERE FILING_TEXT IS NOT NULL
      AND TEXT_LENGTH > 500;

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
