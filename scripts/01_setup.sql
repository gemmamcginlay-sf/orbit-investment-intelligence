-- ============================================================================
-- ORBIT Investment Intelligence — Infrastructure Setup
-- ============================================================================
-- Prerequisites:
--   1. Run as ACCOUNTADMIN (or role with CREATE DATABASE, CREATE ROLE privileges)
--   2. Snowflake Public Data (Paid) listing must be installed:
--      https://app.snowflake.com/marketplace/listing/GZTSZ290BUXPL
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ---------------------------------------------------------------------------
-- Role
-- ---------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS ORBIT_DEMO_ROLE;
GRANT ROLE ORBIT_DEMO_ROLE TO ROLE ACCOUNTADMIN;

-- ---------------------------------------------------------------------------
-- Database & Schemas
-- ---------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS ORBIT_DEMO;
GRANT OWNERSHIP ON DATABASE ORBIT_DEMO TO ROLE ORBIT_DEMO_ROLE;

USE ROLE ORBIT_DEMO_ROLE;
USE DATABASE ORBIT_DEMO;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS MARKET_DATA;
CREATE SCHEMA IF NOT EXISTS AI;

-- ---------------------------------------------------------------------------
-- Warehouses
-- ---------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

CREATE WAREHOUSE IF NOT EXISTS ORBIT_DEMO_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    COMMENT = 'ORBIT demo — general compute';

CREATE WAREHOUSE IF NOT EXISTS ORBIT_DEMO_SEARCH_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    COMMENT = 'ORBIT demo — Cortex Search service refresh';

GRANT USAGE ON WAREHOUSE ORBIT_DEMO_WH TO ROLE ORBIT_DEMO_ROLE;
GRANT USAGE ON WAREHOUSE ORBIT_DEMO_SEARCH_WH TO ROLE ORBIT_DEMO_ROLE;
GRANT OPERATE ON WAREHOUSE ORBIT_DEMO_WH TO ROLE ORBIT_DEMO_ROLE;
GRANT OPERATE ON WAREHOUSE ORBIT_DEMO_SEARCH_WH TO ROLE ORBIT_DEMO_ROLE;

-- ---------------------------------------------------------------------------
-- Grants on Public Data (Paid)
-- ---------------------------------------------------------------------------
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_PUBLIC_DATA_PAID TO ROLE ORBIT_DEMO_ROLE;

-- ---------------------------------------------------------------------------
-- Cortex Cross-Region (required for Ireland / non-US regions)
-- ---------------------------------------------------------------------------
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- ---------------------------------------------------------------------------
-- Additional grants for AI features
-- ---------------------------------------------------------------------------
GRANT CREATE CORTEX SEARCH SERVICE ON SCHEMA ORBIT_DEMO.AI TO ROLE ORBIT_DEMO_ROLE;
GRANT CREATE SEMANTIC VIEW ON SCHEMA ORBIT_DEMO.AI TO ROLE ORBIT_DEMO_ROLE;

-- Grant Snowflake Intelligence access
GRANT DATABASE ROLE SNOWFLAKE.INTELLIGENCE_USER TO ROLE ORBIT_DEMO_ROLE;

-- ---------------------------------------------------------------------------
-- Stage for Streamlit app
-- ---------------------------------------------------------------------------
USE ROLE ORBIT_DEMO_ROLE;
USE DATABASE ORBIT_DEMO;

CREATE STAGE IF NOT EXISTS ORBIT_DEMO.AI.STREAMLIT_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Stage for ORBIT Streamlit portal files';

-- ---------------------------------------------------------------------------
-- Verify Paid listing is accessible
-- ---------------------------------------------------------------------------
SELECT 'Paid listing accessible' AS STATUS,
       COUNT(*) AS SAMPLE_ROWS
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.STOCK_PRICE_TIMESERIES
WHERE DATE >= CURRENT_DATE() - 7
LIMIT 1;
