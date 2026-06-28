-- ============================================================================
-- ORBIT Investment Intelligence — Teardown (Full Cleanup)
-- ============================================================================
-- Removes ALL ORBIT objects from the account. Run as ACCOUNTADMIN.
-- WARNING: This is destructive and irreversible.
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Remove agents from Snowflake Intelligence
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  DROP AGENT ORBIT_DEMO.AI.ORBIT_RESEARCH_AGENT;
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  DROP AGENT ORBIT_DEMO.AI.ORBIT_PORTFOLIO_AGENT;
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  DROP AGENT ORBIT_DEMO.AI.ORBIT_MARKET_AGENT;

-- Suspend task before dropping
ALTER TASK IF EXISTS ORBIT_DEMO.CURATED.DAILY_MARKET_DATA_REFRESH SUSPEND;

-- Drop the database (removes all schemas, tables, views, agents, search services, etc.)
DROP DATABASE IF EXISTS ORBIT_DEMO;

-- Drop warehouses
DROP WAREHOUSE IF EXISTS ORBIT_DEMO_WH;
DROP WAREHOUSE IF EXISTS ORBIT_DEMO_SEARCH_WH;

-- Drop role
DROP ROLE IF EXISTS ORBIT_DEMO_ROLE;
