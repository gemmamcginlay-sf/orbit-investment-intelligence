# S&P Capital IQ Migration Guide

## Overview

This document describes the complete process for migrating synthetic financial data in the SAM_DEMO database to live S&P Capital IQ data from a Snowflake data share. The migration replaces five tables (FACT_SEC_FINANCIALS, FACT_SEC_SEGMENTS, FACT_ESTIMATE_CONSENSUS, FACT_ESTIMATE_DATA, and DIM_ISSUER) with views over the S&P Capital IQ Xpressfeed delivery, preserving the existing column contracts so that semantic views, agents, and downstream queries continue to work without modification.

---

## Prerequisites

- Access to the S&P Capital IQ Xpressfeed data share (database name: `DEV_EDP_EDP_XF_BARCLAYSEXECU_DEV_EDP1_VA_DB`)
- The target database `SAM_DEMO` with schemas `MARKET_DATA` and `CURATED` already populated with synthetic data
- `DIM_ISSUER` table in `SAM_DEMO.CURATED` with columns: ISSUERID, PRIMARYTICKER, CIK, LEGALNAME, etc.
- ACCOUNTADMIN or equivalent role with CREATE VIEW privileges on SAM_DEMO

---

## Source Database Structure

The S&P data lives in a single flat schema:

```
DEV_EDP_EDP_XF_BARCLAYSEXECU_DEV_EDP1_VA_DB.XPRESSFEED
```

All views are UPPERCASE (e.g., `CIQCOMPANY`, `CIQFINPERIOD`). The original documentation referenced `BASE.ciqCompany`, `FINANCIALS.ciqFinPeriod`, `ESTIMATES.ciqEstimateConsensus` — these sub-schema references are incorrect. Everything is in the single `XPRESSFEED` schema.

---

## Step 1: Create the Identifier Bridge

The bridge maps SAM's `DIM_ISSUER.ISSUERID` to S&P's `COMPANYID` using a three-tier matching strategy:

### Tier 1: US Ticker Match (Primary)
- Join `CIQTRADINGITEM` → `CIQSECURITY` → `CIQCOMPANY`
- Filter: `TRADINGITEMSTATUSID = 15` (active/trading — confirmed, NOT 1 or 11)
- Filter: `CIQEXCHANGE.COUNTRYID = 213` (US exchanges only)
- Filter: `CIQSECURITY.PRIMARYFLAG = 1`
- Deduplicate with `ROW_NUMBER() OVER (PARTITION BY TICKERSYMBOL)`

### Tier 2: US ADR Match (Secondary)
- Same as Tier 1 but relaxes `PRIMARYFLAG` on security to catch ADR securities
- Only used for tickers not matched in Tier 1

### Tier 3: CIK Fallback (Foreign ADRs)
- Join `DIM_ISSUER.CIK` → `CIQCOMPANYCROSSREF.IDENTIFIERVALUE`
- Column names: `IDENTIFIERTYPEID` (not CROSSREFTYPEID), `IDENTIFIERVALUE` (not CROSSREFVALUE)
- Filter: `IDENTIFIERTYPEID = 21` (SEC CIK Number)
- Filter: `ACTIVEFLAG = 1`
- Use `LPAD(CIK, 10, '0')` for comparison (SAM stores with leading zeros)
- Only used for issuers not matched by Tier 1 or 2

### Result
503/503 issuers matched (100%). The 44 foreign ADRs (TSM, NVO, VALE, SHEL, BP, BCS, etc.) are resolved by the CIK fallback.

### Key Reference Tables
| Table | Purpose |
|-------|---------|
| CIQTRADINGITEM | Ticker symbols, exchange, status |
| CIQSECURITY | Security → Company mapping |
| CIQCOMPANY | Company master data |
| CIQEXCHANGE | Exchange metadata (COUNTRYID for US filter) |
| CIQCOMPANYCROSSREF | CIK/LEI/CUSIP identifiers |
| CIQCROSSREFIDENTIFIERTYPE | Lookup: IdentifierTypeId → name |

### Key IDs Discovered
| ID | Meaning |
|----|---------|
| TradingItemStatusId = 15 | Active/trading |
| TradingItemStatusId = 11 | Secondary/cross-listed (NOT active) |
| ExchangeCountryId = 213 | United States |
| IdentifierTypeId = 21 | SEC CIK Number |
| IdentifierTypeId = 20002 | LEI (BBID - US) |

---

## Step 2: Create FACT_SEC_FINANCIALS View

### Join Path
```
CIQFINPERIOD (company + fiscal period)
  → CIQFININSTANCE (filing instance, filter LATESTFORFINANCIALPERIODFLAG = 1)
    → CIQFININSTANCETOCOLLECTION (bridge to collections)
      → CIQFINCOLLECTION (filter to types 1,2,3,5,12,13,15)
        → CIQFINCOLLECTIONDATA (actual values, pivot by DATAITEMID)
```

### Critical Discovery: Multiple DataCollectionTypes Required

S&P organizes financial data into separate collections by statement type:

| DataCollectionTypeId | Statement | Items |
|---------------------|-----------|-------|
| 1 | Income Statement | Revenue, Gross Profit, Operating Income, EBITDA, R&D, Interest, Tax |
| 2 | Balance Sheet | Total Assets, Current Assets/Liabilities, Cash, LT Debt, PP&E, Goodwill |
| 3 | Cash Flow | Operating CF, Investing CF, Financing CF, CapEx, D&A |
| 5 | Shareholders' Equity | Total Equity |
| 12 | Per Share (Weighted) | Wtd Avg Shares Basic/Diluted |
| 13 | Shares Outstanding | Common Shares Outstanding |
| 15 | EPS | Basic EPS, Diluted EPS |

**Using only type 1 gives 0% coverage for balance sheet and cash flow items.**

### Validated DataItemIds

| SAM Column | DataItemId | S&P Name |
|-----------|-----------|----------|
| REVENUE | 28 | Total Revenues |
| NET_INCOME | **41571** | Net Income to Company (NOT 4272 which has only 5.9% coverage) |
| GROSS_PROFIT | 10 | Gross Profit |
| OPERATING_INCOME | 21 | Operating Income |
| EBITDA | 4051 | EBITDA |
| TOTAL_ASSETS | 1007 | Total Assets |
| TOTAL_LIABILITIES | 1012 | Total Liabilities (only 9.5% — **derive as Assets − Equity**) |
| TOTAL_EQUITY | 1275 | Total Equity |
| CASH_AND_EQUIVALENTS | 1096 | Cash And Equivalents |
| LONG_TERM_DEBT | 1049 | Long-Term Debt |
| GOODWILL | 1171 | Goodwill |
| PP_AND_E | 1004 | Net Property Plant And Equipment |
| CURRENT_ASSETS | 1008 | Total Current Assets |
| CURRENT_LIABILITIES | 1009 | Total Current Liabilities |
| RETAINED_EARNINGS | 1222 | Retained Earnings |
| OPERATING_CASH_FLOW | 2006 | Cash from Operations |
| INVESTING_CASH_FLOW | 2005 | Cash from Investing |
| FINANCING_CASH_FLOW | 2004 | Cash from Financing |
| CAPEX | 2021 | Capital Expenditure |
| DEPRECIATION_AMORTIZATION | 2083 | Depreciation & Amortization |
| STOCK_BASED_COMP | 101 | Stock-Based Compensation (IS) |
| RD_EXPENSE | 100 | R&D Expenses |
| INTEREST_EXPENSE | 208 | Interest Expense |
| INCOME_TAX_EXPENSE | 75 | Income Tax Expense |
| EPS_BASIC | 3064 | Basic EPS - Continuing Operations |
| EPS_DILUTED | 142 | Diluted EPS - Continuing Operations |
| SHARES_OUTSTANDING | 1100 | Common Shares Outstanding |
| WEIGHTED_AVG_SHARES_BASIC | 3217 | Basic Weighted Average Shares Outstanding |
| WEIGHTED_AVG_SHARES_DILUTED | 342 | Diluted Weighted Average Shares Outstanding |

### Derived Columns
- `TOTAL_LIABILITIES = COALESCE(ID_1012, TOTAL_ASSETS - TOTAL_EQUITY)`
- `FREE_CASH_FLOW = OPERATING_CASH_FLOW - ABS(CAPEX)`
- Margins: computed from Revenue/Income/Profit ratios
- `REVENUE_GROWTH_PCT`: NULL (needs LAG or separate calculation)
- `TAM`, `ESTIMATED_CUSTOMER_COUNT`, `ESTIMATED_NRR_PCT`: NULL (no S&P equivalent)

### Final Coverage (50K+ rows, 501 issuers)
All core columns at 87-99% coverage. Period range: 1978-2027.

---

## Step 3: Create FACT_SEC_SEGMENTS View

### Critical Design: Reversed Join Direction

The naive approach (segment data → collection → instance → period) creates **775M+ rows** due to Cartesian explosion. The correct approach starts from the period and works down:

```
CIQFINPERIOD (Annual only, PERIODTYPEID = 1)
  → CIQFININSTANCE (LATESTFORFINANCIALPERIODFLAG = 1)
    → CIQFININSTANCETOCOLLECTION → CIQFINCOLLECTION (type 1 only)
      → CIQSEGCOLLECTSTANDCMPNTDATA (join ON FINANCIALCOLLECTIONID + COMPANYID)
        → CIQSEGMENT (segment name and type)
```

### Scope Filters
- **Period**: Annual only (`PERIODTYPEID = 1`)
- **DataItemId**: Revenue items only — `3508` (Business Segments Revenue), `3515` (Geographic Segments Revenue)
- **DataCollectionType**: 1 (Income Statement)
- **Company**: Only bridged companies

### Segment Classification Types (from CIQSEGMENTCLASSIFICATIONTYPE)
| TypeId | Meaning |
|--------|---------|
| 1 | Geographic Classification |
| 2 | Primary GIC (GICS) Classification |
| 3 | Secondary GIC Classification |
| 4 | Primary SIC Classification |
| 5 | Secondary SIC Classification |
| 6 | Primary NAIC Classification |

Note: There is NO "Customer" or "Legal Entity" classification in CIQ — those SAM columns are NULL.

### Result
~62K rows, 498 issuers. Geography and Business Segment ~47% populated.

---

## Step 4: Create FACT_ESTIMATE_CONSENSUS View

### Key Design: Mean/High/Low Pivot

S&P stores Mean, High, and Low as **separate DataItemIds** (not separate columns). The view pivots them into SAM's `CONSENSUS_MEAN`, `CONSENSUS_HIGH`, `CONSENSUS_LOW` columns.

### Estimate DataItemIds

| SAM Type | Mean ID | High ID | Low ID |
|----------|---------|---------|--------|
| Revenue | 100180 | 100182 | 100183 |
| EPS | 100173 | 100175 | 100176 |
| Net Income | 100264 | 100266 | 100267 |
| EBITDA | 100187 | 100189 | 100190 |

### TODATE Sentinel
Current/open consensus rows have `TODATE = '2079-06-06'` (confirmed, 142M rows use this value).

### Scope Filters
- `CIQESTIMATEPERIOD.PERIODTYPEID IN (1, 2)` — Annual + Quarterly only
- `CIQESTIMATENUMERICDATA.TODATE = '2079-06-06'` — Current consensus only
- DataItemId restricted to the 12 IDs above
- Company filtered via bridge

### NUM_ESTIMATES
Derived from `CIQESTIMATECOVERAGE` — count of distinct analysts with active (non-expired) coverage.

### Result
~194K rows, 495 issuers.

---

## Step 5: Create FACT_ESTIMATE_DATA View

Same structure as consensus but outputs flat rows (one per DataItemId per period) without the Mean/High/Low pivot. Uses the same 12 DataItemId filter and TODATE sentinel.

### Design Note
This view returns consensus-level values (not individual analyst estimates). `ANALYST_ID` and `BROKER_ID` are NULL. For true analyst-level detail, use `CIQESTIMATEDETAILNUMERICDATA` if available in the schema.

### Result
~583K rows, 495 issuers.

---

## Step 6: DIM_ISSUER Enrichment (Optional)

Use a MERGE statement to update DIM_ISSUER metadata from S&P:

| Column | Source |
|--------|--------|
| PROVIDERCOMPANYID | CIQCOMPANY.COMPANYID |
| CIK | CIQCOMPANYCROSSREF (IdentifierTypeId=21) |
| LEI | CIQCOMPANYCROSSREF (IdentifierTypeId=20002) |
| LEGALNAME | CIQCOMPANY.COMPANYNAME |
| ULTIMATEPARENTISSUERID | CIQCOMPANYULTIMATEPARENT.ULTIMATEPARENTCOMPANYID |
| TIER | Retained from SAM seed (no S&P equivalent) |
| GICS_SECTOR | CIQCOMPANYINDCLASS (SegmentClassificationTypeId=2) — needs lookup |
| SIC_DESCRIPTION | CIQCOMPANYINDCLASS (SegmentClassificationTypeId=4) — needs lookup |

---

## Step 7: Cutover Execution

### Backup synthetic tables
```sql
ALTER TABLE SAM_DEMO.MARKET_DATA.FACT_SEC_FINANCIALS RENAME TO FACT_SEC_FINANCIALS_SYNTHETIC;
ALTER TABLE SAM_DEMO.MARKET_DATA.FACT_SEC_SEGMENTS RENAME TO FACT_SEC_SEGMENTS_SYNTHETIC;
ALTER TABLE SAM_DEMO.MARKET_DATA.FACT_ESTIMATE_CONSENSUS RENAME TO FACT_ESTIMATE_CONSENSUS_SYNTHETIC;
ALTER TABLE SAM_DEMO.MARKET_DATA.FACT_ESTIMATE_DATA RENAME TO FACT_ESTIMATE_DATA_SYNTHETIC;
```

### Activate S&P views
```sql
ALTER VIEW SAM_DEMO.MARKET_DATA.V_SP_FACT_SEC_FINANCIALS RENAME TO FACT_SEC_FINANCIALS;
ALTER VIEW SAM_DEMO.MARKET_DATA.V_SP_FACT_SEC_SEGMENTS RENAME TO FACT_SEC_SEGMENTS;
ALTER VIEW SAM_DEMO.MARKET_DATA.V_SP_FACT_ESTIMATE_CONSENSUS RENAME TO FACT_ESTIMATE_CONSENSUS;
ALTER VIEW SAM_DEMO.MARKET_DATA.V_SP_FACT_ESTIMATE_DATA RENAME TO FACT_ESTIMATE_DATA;
```

### Rollback (if needed)
```sql
-- Rename views back to V_SP_ prefix
ALTER VIEW SAM_DEMO.MARKET_DATA.FACT_SEC_FINANCIALS RENAME TO V_SP_FACT_SEC_FINANCIALS;
ALTER VIEW SAM_DEMO.MARKET_DATA.FACT_SEC_SEGMENTS RENAME TO V_SP_FACT_SEC_SEGMENTS;
ALTER VIEW SAM_DEMO.MARKET_DATA.FACT_ESTIMATE_CONSENSUS RENAME TO V_SP_FACT_ESTIMATE_CONSENSUS;
ALTER VIEW SAM_DEMO.MARKET_DATA.FACT_ESTIMATE_DATA RENAME TO V_SP_FACT_ESTIMATE_DATA;
-- Restore synthetic tables
ALTER TABLE SAM_DEMO.MARKET_DATA.FACT_SEC_FINANCIALS_SYNTHETIC RENAME TO FACT_SEC_FINANCIALS;
ALTER TABLE SAM_DEMO.MARKET_DATA.FACT_SEC_SEGMENTS_SYNTHETIC RENAME TO FACT_SEC_SEGMENTS;
ALTER TABLE SAM_DEMO.MARKET_DATA.FACT_ESTIMATE_CONSENSUS_SYNTHETIC RENAME TO FACT_ESTIMATE_CONSENSUS;
ALTER TABLE SAM_DEMO.MARKET_DATA.FACT_ESTIMATE_DATA_SYNTHETIC RENAME TO FACT_ESTIMATE_DATA;
```

---

## Validation Checklist

Run these after deployment:

1. **Bridge**: `SELECT COUNT(*), COUNT(SP_COMPANYID) FROM V_SP_COMPANY_BRIDGE` → both should equal total DIM_ISSUER rows
2. **Financials spot-check**: Query AAPL FY2024 Revenue (~$391B), Net Income (~$94B)
3. **Segments spot-check**: Query MSFT FY2024 segments (Intelligent Cloud ~$87B)
4. **Estimates spot-check**: Query NVDA forward Revenue estimates
5. **Column contract**: Verify INFORMATION_SCHEMA.COLUMNS matches expected 54 columns for FACT_SEC_FINANCIALS
6. **NULL coverage**: Expect 87-99% non-NULL for core financial columns
7. **Row counts**: Financials ~50-60K, Segments ~50-60K, Consensus ~170-200K, Data ~500-600K

---

## Known Limitations

| Limitation | Explanation |
|-----------|-------------|
| TAM, NRR, Customer Count | Always NULL — no S&P equivalent |
| REVENUE_GROWTH_PCT | NULL — needs LAG calculation |
| CURRENCY | Hardcoded 'USD' — needs CIQCURRENCY lookup for multi-currency |
| Segment Geography/Business | ~47% populated (CIQ classification coverage varies) |
| R&D Expense | ~43% (only tech/pharma companies report separately) |
| Total Liabilities | Derived (Assets − Equity) — direct ID 1012 only 9.5% populated |
| Data share dependency | If share goes offline, ALL views fail |
| Live reads | No caching — every query hits the share in real-time |

---

## Files Reference

| File | Purpose |
|------|---------|
| `sp_migration_bridge.sql` | Identifier bridge view DDL |
| `sp_dim_issuer_rebuild.sql` | DIM_ISSUER MERGE from S&P |
| `sp_fact_sec_financials_view.sql` | Financials compatibility view |
| `sp_fact_sec_segments_view.sql` | Segments compatibility view |
| `sp_fact_estimate_consensus_view.sql` | Both estimate views |
| `sp_validation_queries.sql` | 8-section validation suite |
| `sp_cutover_checklist.sql` | Cutover execution steps + rollback |

---

## Adapting for Another Account

1. Replace `DEV_EDP_EDP_XF_BARCLAYSEXECU_DEV_EDP1_VA_DB` with your S&P data share database name
2. Verify the schema is `XPRESSFEED` (may differ by share configuration)
3. Run Section 2 of `sp_validation_queries.sql` to confirm DataItemIds match (they should be standard across all CIQ Xpressfeed deliveries)
4. Verify `TRADINGITEMSTATUSID = 15` is still the active status (query your CIQTRADINGITEM for known tickers like AAPL)
5. Verify `CIQEXCHANGE.COUNTRYID = 213` for US exchanges
6. Adjust `DIM_ISSUER` column mappings if your schema differs from SAM_DEMO
7. Run the validation checklist after deployment
