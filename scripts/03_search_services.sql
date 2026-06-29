-- ORBIT Investment Intelligence — Cortex Search Services
-- Co-authored with CoCo
-- ============================================================================
-- Points search services directly at source data (no staging tables needed).
-- Uses LARGE warehouse for initial indexing — scale down after creation.
-- Fully idempotent — safe to re-run.
-- ============================================================================

USE ROLE ORBIT_DEMO_ROLE;
USE DATABASE ORBIT_DEMO;
USE SCHEMA AI;

-- Scale up search warehouse for initial indexing
ALTER WAREHOUSE ORBIT_DEMO_SEARCH_WH SET WAREHOUSE_SIZE = 'LARGE';

-- ---------------------------------------------------------------------------
-- 1. Cortex Search Service — SEC Filings (direct from Paid share)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE CORTEX SEARCH SERVICE ORBIT_SEC_FILINGS_SEARCH
    TEXT INDEXES DOCUMENT_TITLE, TICKER, COMPANY_NAME, GICS_SECTOR, FILING_TYPE
    VECTOR INDEXES FILING_TEXT (model = 'snowflake-arctic-embed-m-v1.5')
    ATTRIBUTES DOCUMENT_TITLE, TICKER, COMPANY_NAME, GICS_SECTOR, FILING_TYPE, CIK
    WAREHOUSE = ORBIT_DEMO_SEARCH_WH
    TARGET_LAG = '1 day'
    AS
    WITH our_filings AS (
        SELECT DISTINCT sra.ADSH, sra.CIK
        FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_ATTRIBUTES sra
        JOIN ORBIT_DEMO.CURATED.DIM_ISSUER di ON sra.CIK = di.CIK
        WHERE di.CIK IS NOT NULL
          AND sra.PERIOD_END_DATE >= DATEADD(YEAR, -2, CURRENT_DATE())
    )
    SELECT
        t.ADSH || '_' || ROW_NUMBER() OVER (ORDER BY t.ADSH) AS DOCUMENT_ID,
        i.COMPANY_NAME || ' - ' || t.FORM_TYPE AS DOCUMENT_TITLE,
        t.VALUE AS FILING_TEXT,
        i.TICKER,
        i.COMPANY_NAME,
        i.GICS_SECTOR,
        t.FORM_TYPE AS FILING_TYPE,
        i.CIK
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_TEXT_ATTRIBUTES t
    JOIN our_filings fc ON t.ADSH = fc.ADSH
    JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON fc.CIK = i.CIK
    WHERE t.FORM_TYPE IN ('10-K', '10-Q', '8-K')
      AND t.VARIABLE_NAME LIKE '%Filing Text'
      AND t.VARIABLE_NAME NOT LIKE '%EX-%'
      AND t.VALUE IS NOT NULL
      AND LENGTH(t.VALUE) > 500;

-- ---------------------------------------------------------------------------
-- 2. Cortex Search Service — Earnings Transcripts (direct from Paid share)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE CORTEX SEARCH SERVICE ORBIT_TRANSCRIPTS_SEARCH
    TEXT INDEXES DOCUMENT_TITLE, TICKER, COMPANY_NAME, GICS_SECTOR, EVENT_TYPE
    VECTOR INDEXES DOCUMENT_TEXT (model = 'snowflake-arctic-embed-m-v1.5')
    ATTRIBUTES DOCUMENT_TITLE, TICKER, COMPANY_NAME, GICS_SECTOR, EVENT_TYPE, FISCAL_YEAR, FISCAL_PERIOD, EVENT_DATE
    WAREHOUSE = ORBIT_DEMO_SEARCH_WH
    TARGET_LAG = '1 day'
    AS
    SELECT
        t.COMPANY_ID || '_' || t.EVENT_TIMESTAMP::VARCHAR AS DOCUMENT_ID,
        i.COMPANY_NAME || ' ' || t.EVENT_TYPE || ' - ' || t.EVENT_TITLE || ' (' || t.EVENT_TIMESTAMP::DATE || ')' AS DOCUMENT_TITLE,
        t.TRANSCRIPT:text::VARCHAR AS DOCUMENT_TEXT,
        i.TICKER,
        i.COMPANY_NAME,
        i.GICS_SECTOR,
        t.EVENT_TYPE,
        t.FISCAL_YEAR,
        t.FISCAL_PERIOD,
        t.EVENT_TIMESTAMP::DATE AS EVENT_DATE
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_EVENT_TRANSCRIPT_ATTRIBUTES t
    JOIN ORBIT_DEMO.CURATED.DIM_ISSUER i ON t.PRIMARY_TICKER = i.TICKER
    WHERE t.EVENT_TIMESTAMP >= DATEADD(YEAR, -2, CURRENT_DATE())
      AND t.TRANSCRIPT:text IS NOT NULL
      AND LENGTH(t.TRANSCRIPT:text::VARCHAR) > 100
      AND t.TRANSCRIPT_TYPE = 'SPEAKERS_ANNOTATED';

-- Scale warehouse back down after creation
ALTER WAREHOUSE ORBIT_DEMO_SEARCH_WH SET WAREHOUSE_SIZE = 'MEDIUM';
