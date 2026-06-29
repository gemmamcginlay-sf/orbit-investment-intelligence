# Deployment Guide

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Snowflake account | Enterprise edition or higher (for Cortex AI) |
| Cortex AI | Enabled on the account |
| Snowflake Public Data (Paid) | [Install from Marketplace](https://app.snowflake.com/marketplace/listing/GZTSZ290BUXPL) |
| Role | ACCOUNTADMIN (for initial setup only) |
| Region | US (for Cortex AI availability) |

## Deployment Steps

### Step 1: Infrastructure (`scripts/01_setup.sql`)

Creates the database, schemas, role, and warehouses.

```sql
-- Run as ACCOUNTADMIN
-- Creates: ORBIT_DEMO database, ORBIT_DEMO_ROLE, warehouses
```

**Objects created:**
- Database: `ORBIT_DEMO`
- Schemas: `CURATED`, `MARKET_DATA`, `AI`, `RAW`
- Role: `ORBIT_DEMO_ROLE`
- Warehouses: `ORBIT_DEMO_WH` (XS), `ORBIT_DEMO_SEARCH_WH` (Medium)

---

### Step 2: Data Layer (`scripts/02_data.sql`)

Builds all dimension and fact tables from the Snowflake Public Data (Paid) listing.

```sql
-- Run as ORBIT_DEMO_ROLE
-- Duration: ~3-5 minutes (depends on warehouse size)
```

**What it does:**
- Builds `DIM_ISSUER` from COMPANY_INDEX with SIC→GICS sector mapping
- Creates 10 fact tables from various paid data sources
- Generates 11 model portfolios with randomised allocations
- Computes financial ratios (margins, ROE, D/E, FCF)

**Important:** The `DIM_ISSUER` query filters to companies with price data in the last 30 days. If run on a weekend, some tickers may be excluded — this is expected.

---

### Step 3: Cortex Search Services (`scripts/03_search_services.sql`)

Creates two Cortex Search services for RAG over unstructured documents.

```sql
-- Run as ORBIT_DEMO_ROLE
-- Duration: ~5-10 minutes (initial indexing)
-- Temporarily scales ORBIT_DEMO_SEARCH_WH to LARGE
```

**Services created:**
- `ORBIT_SEC_FILINGS_SEARCH` — Full text of 10-K, 10-Q, 8-K filings
- `ORBIT_TRANSCRIPTS_SEARCH` — Earnings call transcripts

Both use hybrid indexing (text + vector with `snowflake-arctic-embed-m-v1.5`) and auto-refresh daily.

---

### Step 4: Semantic Views (`scripts/04_semantic_views.sql`)

Deploys three semantic views that define the business vocabulary for text-to-SQL.

```sql
-- Run as ORBIT_DEMO_ROLE
-- Duration: ~30 seconds
```

**Views created:**
- `ORBIT_MARKET_VIEW` — Yields, FX, economic indicators, policy rates, stock prices
- `ORBIT_RESEARCH_VIEW` — SEC financials, segments, insiders, institutional holdings
- `ORBIT_PORTFOLIO_VIEW` — Portfolios, positions, benchmarks

---

### Step 5: Cortex Agents (`scripts/05_agents.sql`)

Creates three Cortex Agents and registers them with Snowflake Intelligence.

```sql
-- Run as ORBIT_DEMO_ROLE
-- Duration: ~30 seconds
```

**Agents created:**
- `ORBIT_RESEARCH_AGENT` — Multi-tool (Analyst + 2 Search services)
- `ORBIT_PORTFOLIO_AGENT` — Single-tool (Portfolio Analyst)
- `ORBIT_MARKET_AGENT` — Single-tool (Market Analyst)

All agents use `claude-opus-4-7` for orchestration with 300-second / 32K-token budgets.

---

### Step 6: Refresh Pipeline (`scripts/06_refresh.sql`)

Sets up Dynamic Tables and a scheduled Task for daily data refresh.

```sql
-- Run as ORBIT_DEMO_ROLE
-- Duration: ~30 seconds
```

**Objects created:**
- `DT_BENCHMARK_RETURNS` — Dynamic Table
- `DT_SECTOR_RETURNS` — Dynamic Table
- `ORBIT_DAILY_REFRESH` — Scheduled Task (runs daily at 06:00 UTC)

---

### Step 7: Streamlit Portal

The portal runs from the Workspace — no additional deployment needed. Open the Workspace and run the app.

Alternatively, deploy as a standalone Streamlit in Snowflake:
```sql
CREATE OR REPLACE STREAMLIT ORBIT_DEMO.AI.ORBIT_PORTAL
    ROOT_LOCATION = '@ORBIT_DEMO.AI.STREAMLIT_STAGE/orbit_portal'
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = 'ORBIT_DEMO_WH';
```

---

## Teardown

To remove all objects:

```sql
-- scripts/teardown.sql
-- Drops the entire ORBIT_DEMO database, role, and warehouses
```

---

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| "Object does not exist" on paid data | Marketplace listing not installed | Install Snowflake Public Data (Paid) from Marketplace |
| Missing companies (e.g., Tesla) | DIM_ISSUER built when price data was stale | Re-run `02_data.sql` DIM_ISSUER section |
| Gross margin NULL | Company doesn't report GrossProfit tag | Fixed in code — uses CostOfRevenue fallback |
| Search service error on subquery | Change tracking limitation | Fixed — uses JOIN instead of IN (SELECT) |
| Yield curve out of order | Streamlit alphabetically sorts x-axis | Fixed — uses Altair with sort=None |
| FX table shows 1 currency | Global MAX(DATE) only has 1 row that day | Fixed — uses per-currency latest via QUALIFY |
| Agent "unexpected AGENT" error | Wrong DDL syntax | Use `CREATE AGENT` not `CREATE CORTEX AGENT` |

---

## Estimated Costs

| Component | Credit usage |
|-----------|-------------|
| Initial data build | ~2-5 credits (one-time) |
| Search service indexing | ~3-5 credits (one-time) |
| Daily refresh task | ~0.5 credits/day |
| Streamlit portal | ~0.1 credits/hour (while active) |
| Agent queries | ~0.01-0.05 credits/query |
| Search service maintenance | ~0.5 credits/day |

Total steady-state: approximately 1-2 credits/day with moderate usage.
