-- ============================================================================
-- ORBIT Investment Intelligence — Master Deployment Script
-- ============================================================================
-- Run scripts in this order from Snowsight worksheets.
-- Each script is idempotent (uses CREATE OR REPLACE).
--
-- Deployment order:
--   1. scripts/01_setup.sql           (infra: DB, schemas, role, warehouses)
--   2. scripts/02_data.sql            (dimensions + market data + derived tables)
--   3. scripts/03_search_services.sql (corpus tables + Cortex Search)
--   4. scripts/04_semantic_views.sql  (Semantic Views for Cortex Analyst)
--   5. scripts/05_agents.sql          (3 Cortex Agents)
--   6. scripts/06_refresh.sql         (Dynamic Tables + daily Task)
--
-- Total deployment time: ~5-10 minutes
-- ============================================================================

-- Verify deployment
USE ROLE ORBIT_DEMO_ROLE;
SHOW DATABASES LIKE 'ORBIT%';
SHOW SCHEMAS IN DATABASE ORBIT_DEMO;
SELECT 'Stock Prices' AS TABLE_NAME, COUNT(*) AS NumROWS FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES
UNION ALL
SELECT 'SEC Financials', COUNT(*) FROM ORBIT_DEMO.MARKET_DATA.FACT_SEC_FINANCIALS
UNION ALL
SELECT 'Treasury Yields', COUNT(*) FROM ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS
UNION ALL
SELECT 'Issuers', COUNT(*) FROM ORBIT_DEMO.CURATED.DIM_ISSUER
UNION ALL
SELECT 'Positions', COUNT(*) FROM ORBIT_DEMO.CURATED.FACT_POSITION_DAILY;

SHOW CORTEX SEARCH SERVICES IN SCHEMA ORBIT_DEMO.AI;
DESCRIBE CORTEX SEARCH SERVICE ORBIT_DEMO.AI.ORBIT_SEC_FILINGS_SEARCH;

SHOW SEMANTIC VIEWS IN SCHEMA ORBIT_DEMO.AI;
SHOW AGENTS IN SCHEMA ORBIT_DEMO.AI;
SHOW DYNAMIC TABLES IN SCHEMA ORBIT_DEMO.CURATED;

--Check which users are granted to role
SHOW GRANTS OF ROLE ORBIT_DEMO_ROLE;