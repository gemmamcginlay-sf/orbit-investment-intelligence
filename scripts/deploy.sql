-- ============================================================================
-- ORBIT Investment Intelligence — Master Deployment Script
-- ============================================================================
-- Run scripts in this order from Snowsight worksheets.
-- Each script is idempotent (uses CREATE OR REPLACE).
--
-- IMPORTANT: Run 03_curated.sql FIRST (creates DIM_ISSUER), then 02_market_data.sql
-- because market data tables JOIN to DIM_ISSUER.
--
-- Deployment order:
--   1. scripts/01_setup.sql        (infra: DB, schemas, role, warehouses)
--   2. scripts/03_curated.sql      (dimensions + model portfolios — DIM_ISSUER first!)
--   3. scripts/02_market_data.sql  (market data from Paid share)
--   4. scripts/04_search_services.sql (corpus tables + Cortex Search)
--   5. scripts/05_semantic_views.sql  (Semantic Views for Cortex Analyst)
--   6. scripts/06_agents.sql       (3 Cortex Agents)
--   7. scripts/07_refresh.sql      (Dynamic Tables + daily Task)
--
-- Total deployment time: ~5-10 minutes
-- ============================================================================

-- Verify deployment
SHOW DATABASES LIKE 'ORBIT%';
SHOW SCHEMAS IN DATABASE ORBIT_DEMO;
SELECT 'Stock Prices' AS TABLE_NAME, COUNT(*) AS ROWS FROM ORBIT_DEMO.MARKET_DATA.FACT_STOCK_PRICES
UNION ALL
SELECT 'SEC Financials', COUNT(*) FROM ORBIT_DEMO.MARKET_DATA.FACT_SEC_FINANCIALS
UNION ALL
SELECT 'Treasury Yields', COUNT(*) FROM ORBIT_DEMO.MARKET_DATA.FACT_TREASURY_YIELDS
UNION ALL
SELECT 'Issuers', COUNT(*) FROM ORBIT_DEMO.CURATED.DIM_ISSUER
UNION ALL
SELECT 'Positions', COUNT(*) FROM ORBIT_DEMO.CURATED.FACT_POSITION_DAILY;

SHOW CORTEX SEARCH SERVICES IN SCHEMA ORBIT_DEMO.AI;
SHOW SEMANTIC VIEWS IN SCHEMA ORBIT_DEMO.AI;
SHOW CORTEX AGENTS IN SCHEMA ORBIT_DEMO.AI;
SHOW DYNAMIC TABLES IN SCHEMA ORBIT_DEMO.CURATED;
