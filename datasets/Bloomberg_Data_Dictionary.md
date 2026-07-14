# Bloomberg Data Plus (DL+) Database Documentation

**Database:** `DEV_EDP_EDP_DLPLUS_08803CFE_DATABASE_VA_DB`  
**Source:** Bloomberg Data License Plus (DL+) via Snowflake Data Share  
**Generated:** 2026-07-14

---

## Overview

This database contains Bloomberg reference data, pricing, ratings, corporate actions, and lookup tables delivered via Bloomberg's Data License Plus (DL+) product. All objects are views referencing a shared database (`DEV_EDP_EDP_DLPLUS_08803CFE_DATABASE_SHR_DB`).

The database is organized into 5 schemas:

| Schema | Views | Description |
|--------|-------|-------------|
| **CORE** | 6 | Primary entity, instrument, market, price, rating, and schedule data |
| **BULK** | ~50 | Multi-row/array data associated with instruments and entities |
| **EXT** | 2 | Corporate actions and subscription metadata |
| **LOOKUP** | ~200 | Reference/code-value lookup tables |
| **META** | 2 | Job tracking and client claim metadata |

---

## Schema: CORE

The CORE schema contains the primary Bloomberg reference and pricing data. These are wide, denormalized views with hundreds to thousands of columns per view.

### CORE.ENTITY

**~345 columns** | Primary key: `ID_BPL_ENTITY`

Company/issuer-level reference data including financials, sanctions, classifications, and corporate structure.

| Column | Type | Description |
|--------|------|-------------|
| UPDATESET | TEXT | Bloomberg update set identifier (batch ID) |
| APPLIEDTIME | TIMESTAMP_NTZ | Timestamp when the data was applied |
| ID_BPL_ENTITY | TEXT | Bloomberg unique entity identifier (primary key) |
| LONG_COMP_NAME | TEXT | Full legal company name |
| ID_BB_COMPANY | NUMBER | Bloomberg company ID |
| ACQUIRED_BY_PARENT | BOOLEAN | Whether entity was acquired by parent |
| AIFMD_INDICATOR | BOOLEAN | Alternative Investment Fund Managers Directive flag |
| BLOOMBERG_LEGAL_FORM | TEXT | Legal form classification |
| BPL_ACTIVE | BOOLEAN | Whether entity is currently active |
| BPL_PRIMARY_IDENTIFIER | TEXT | Primary Bloomberg identifier |
| BPL_SECONDARY_IDENTIFIER | TEXT | Secondary Bloomberg identifier |
| BPL_STATUS | TEXT | Entity lifecycle status |
| BUSINESSDATE | DATE | Business date of the data |
| CNTRY_OF_DOMICILE | TEXT | Country of domicile (ISO code) |
| CNTRY_OF_INCORPORATION | TEXT | Country of incorporation (ISO code) |
| CNTRY_OF_RISK | TEXT | Country of risk (ISO code) |
| COMPANY_ADDRESS | TEXT | Registered company address |
| CLASSIFICATION_SCHEME | TEXT | Industry classification scheme used |
| CLASSIFICATION_LEVEL_1_CODE | TEXT | Level 1 industry classification code |
| CLASSIFICATION_LEVEL_1_NAME | TEXT | Level 1 industry classification name |
| CLASSIFICATION_LEVEL_2_CODE | TEXT | Level 2 industry classification code |
| CLASSIFICATION_LEVEL_2_NAME | TEXT | Level 2 industry classification name |
| CLASSIFICATION_LEVEL_3_CODE | TEXT | Level 3 sector classification code |
| CLASSIFICATION_LEVEL_3_NAME | TEXT | Level 3 sector classification name |
| CLASSIFICATION_LEVEL_4_CODE through _7_CODE | TEXT | Deeper industry classification levels |

**Financial Data Columns (selected):**

| Column | Type | Description |
|--------|------|-------------|
| ANN_RETURN_ON_ASSET | NUMBER | Annual return on assets |
| BS_ACCT_PAYABLE | NUMBER | Balance sheet accounts payable |
| BS_CASH_NEAR_CASH_ITEM | NUMBER | Cash and near-cash items |
| BS_CUR_LIAB | NUMBER | Current liabilities |
| BS_CUSTOMER_DEPOSITS | NUMBER | Customer deposits (banking) |
| BS_SH_OUT | NUMBER | Shares outstanding |
| BS_TIER1_CAP_RATIO | NUMBER | Tier 1 capital ratio |
| BS_TOT_ASSET | NUMBER | Total assets |
| BS_TOT_LIAB2 | NUMBER | Total liabilities |

**Sanctions Columns (selected):**

| Column | Type | Description |
|--------|------|-------------|
| AUSTRALIAN_SANCTION_STATUS | TEXT | Australian sanction status |
| BIS_STATUS | TEXT | US Bureau of Industry and Security status |
| CANADIAN_SANCTION_STATUS | TEXT | Canadian sanction status |
| CANADIAN_SANCTION_SCHEDULE_1/2/3 | TEXT | Canadian sanction schedule details |

**Debt Structure Columns (CAST_*):**

| Column | Type | Description |
|--------|------|-------------|
| CAST_AMT_OUTSTDG_1ST_LIEN_BONDS | NUMBER | Outstanding 1st lien bonds amount |
| CAST_AMT_OUTSTDG_1ST_LIEN_LOANS | NUMBER | Outstanding 1st lien loans amount |
| CAST_AMT_OUTSTDG_2ND_LIEN_BONDS | NUMBER | Outstanding 2nd lien bonds amount |
| CAST_AMT_OUTSTDG_SR_UNSEC_BONDS | NUMBER | Outstanding senior unsecured bonds |
| CAST_AMT_OUTSTDG_TOTAL_DEBT | NUMBER | Total outstanding debt |
| CAST_PARENT_ID | NUMBER | Parent entity ID in capital structure |
| CAST_PARENT_NAME | TEXT | Parent entity name in capital structure |

---

### CORE.INSTRUMENT

**~2,400 columns** | Primary key: `ID_BPL_INSTRUMENT`

The largest view, containing comprehensive security-level reference data for all instrument types (equities, fixed income, derivatives, funds, structured products, etc.).

| Column | Type | Description |
|--------|------|-------------|
| UPDATESET | TEXT | Bloomberg update set identifier |
| APPLIEDTIME | TIMESTAMP_NTZ | Timestamp when data was applied |
| ID_BPL_INSTRUMENT | TEXT | Bloomberg unique instrument identifier (primary key) |
| ID_BPL_ENTITY | TEXT | Link to parent entity |
| NAME | TEXT | Instrument name |

**Identifier Columns:**

| Column | Type | Description |
|--------|------|-------------|
| ID_BB_GLOBAL | TEXT | Bloomberg Global ID (BBGID) |
| ID_BB_SEC_NUM_DES | TEXT | Bloomberg security number description |
| ID_CUSIP | TEXT | CUSIP identifier |
| ID_ISIN | TEXT | ISIN identifier |
| ID_SEDOL1 | TEXT | SEDOL identifier |
| TICKER | TEXT | Exchange ticker symbol |
| PARSEKYABLE_DES | TEXT | Bloomberg parseable description |
| COMPOSITE_ID_BB_GLOBAL | TEXT | Composite Bloomberg Global ID |

**Security Classification:**

| Column | Type | Description |
|--------|------|-------------|
| MARKET_SECTOR_DES | TEXT | Market sector (Equity, Corp, Govt, Mtge, etc.) |
| SECURITY_TYP | TEXT | Security type code |
| SECURITY_TYP2 | TEXT | Secondary security type |
| SECURITY_DES | TEXT | Security description |
| ASSET_CLASS | TEXT | Asset class classification |
| BPIPE_REFERENCE_SECURITY_CLASS | TEXT | Reference security class |

**Fixed Income Columns (selected):**

| Column | Type | Description |
|--------|------|-------------|
| COUPON | NUMBER | Coupon rate |
| CPN_CRNCY | TEXT | Coupon currency |
| CPN_FREQ | NUMBER | Coupon frequency |
| CPN_TYP | TEXT | Coupon type (Fixed, Float, Zero, etc.) |
| MATURITY | DATE | Maturity date |
| ISSUE_DT | DATE | Issue date |
| FIRST_CPN_DT | DATE | First coupon date |
| AMT_ISSUED | NUMBER | Amount issued |
| AMT_OUTSTANDING | NUMBER | Amount outstanding |
| MIN_PIECE | NUMBER | Minimum denomination |
| PAR_AMT | NUMBER | Par amount |
| PAYMENT_RANK | TEXT | Payment rank/seniority |
| CALLABLE | BOOLEAN | Whether bond is callable |
| PUTTABLE | BOOLEAN | Whether bond is puttable |
| CONVERTIBLE | BOOLEAN | Whether bond is convertible |
| SINKABLE | BOOLEAN | Whether bond has sinking fund |
| COLLAT_TYP | TEXT | Collateral type |

**Floating Rate Columns:**

| Column | Type | Description |
|--------|------|-------------|
| FLOAT_RT_RESET_FREQ | TEXT | Float rate reset frequency |
| FLT_BENCH_MULTIPLIER | NUMBER | Floating benchmark multiplier |
| FLT_CPN_CONVENTION | TEXT | Floating coupon convention |
| FLT_SPREAD | NUMBER | Floating rate spread |
| RESET_IDX | TEXT | Reference index for resets |

**Equity Columns (selected):**

| Column | Type | Description |
|--------|------|-------------|
| EQY_PRIM_EXCH | TEXT | Primary exchange |
| EQY_SH_OUT | NUMBER | Shares outstanding |
| EQY_FLOAT | NUMBER | Free float shares |
| DVD_CRNCY | TEXT | Dividend currency |
| DVD_EX_DT | DATE | Dividend ex-date |
| DVD_PAY_DT | DATE | Dividend pay date |
| INDUSTRY_GROUP | TEXT | Industry group |
| INDUSTRY_SECTOR | TEXT | Industry sector |
| INDUSTRY_SUBGROUP | TEXT | Industry subgroup |

**Options/Derivatives Columns (selected):**

| Column | Type | Description |
|--------|------|-------------|
| OPT_PUT_CALL | TEXT | Put or Call indicator |
| OPT_STRIKE_PX | NUMBER | Strike price |
| OPT_EXPIRE_DT | DATE | Expiration date |
| OPT_EXER_TYP | TEXT | Exercise type (American/European) |
| OPT_CONT_SIZE | NUMBER | Contract size |
| OPT_UNDL_TICKER | TEXT | Underlying ticker |
| FUT_FIRST_TRADE_DT | DATE | Futures first trade date |
| FUT_LAST_TRADE_DT | DATE | Futures last trade date |
| FUT_DLV_DT_FIRST | DATE | Futures first delivery date |

**Fund Columns (selected):**

| Column | Type | Description |
|--------|------|-------------|
| FUND_ASSET_CLASS_FOCUS | TEXT | Fund asset class focus |
| FUND_GEO_FOCUS | TEXT | Fund geographic focus |
| FUND_INCEPT_DT | DATE | Fund inception date |
| FUND_MGR_NAME | TEXT | Fund manager name |
| FUND_NET_ASSET_VAL | NUMBER | Net asset value |
| FUND_TOTAL_ASSETS | NUMBER | Total fund assets |
| FUND_TYP | TEXT | Fund type |

**Structured Product/MBS Columns (selected):**

| Column | Type | Description |
|--------|------|-------------|
| MTG_ORIG_AMT | NUMBER | Original mortgage amount |
| MTG_FACTOR | NUMBER | Mortgage pool factor |
| COLLAT_ARM_WA_GROSS_MARGIN_ALL | NUMBER | Weighted avg gross margin (ARM) |
| PREPAY_RT_1M | NUMBER | 1-month prepayment rate |
| ORIG_CREDIT_SUPPORT | NUMBER | Original credit support level |

**Sanctions/Regulatory Columns:**

| Column | Type | Description |
|--------|------|-------------|
| OFAC_SANCTIONED_SECURITY | BOOLEAN | OFAC sanctioned flag |
| NUM_CA_SANCTIONED_CONSTITUENTS | NUMBER | Canadian sanctioned constituents count |
| NUM_EU_SANCTIONED_CONSTITUENTS | NUMBER | EU sanctioned constituents count |
| NUM_OFAC_SANCTIONED_CONSTITUENTS | NUMBER | OFAC sanctioned constituents count |
| NUM_UK_SANCTIONED_CONSTITUENTS | NUMBER | UK sanctioned constituents count |

---

### CORE.MARKET

**~438 columns** | Primary key: `ID_BPL_MARKET`

Market-level data representing a specific listing or trading venue for an instrument.

| Column | Type | Description |
|--------|------|-------------|
| UPDATESET | TEXT | Bloomberg update set identifier |
| APPLIEDTIME | TIMESTAMP_NTZ | Timestamp when data was applied |
| ID_BPL_MARKET | TEXT | Bloomberg unique market identifier (primary key) |
| ID_BPL_INSTRUMENT | TEXT | Link to parent instrument |
| ID_BB_GLOBAL | TEXT | Bloomberg Global ID for this listing |
| TICKER | TEXT | Ticker symbol on this exchange |
| EXCH_CODE | TEXT | Exchange code |
| EQY_PRIM_EXCH | TEXT | Primary exchange |
| CRNCY | TEXT | Trading currency |
| COUNTRY_ISO | TEXT | Country of listing |
| MARKET_SECTOR_DES | TEXT | Market sector description |
| SECURITY_TYP | TEXT | Security type |
| NAME | TEXT | Instrument name on this market |

---

### CORE.PRICE

**~850 columns** | Primary key: `ID_BPL_MARKET`

Real-time and end-of-day pricing data, analytics, and derived measures.

| Column | Type | Description |
|--------|------|-------------|
| UPDATESET | TEXT | Bloomberg update set identifier |
| APPLIEDTIME | TIMESTAMP_NTZ | Timestamp when data was applied |
| ID_BPL_MARKET | TEXT | Bloomberg market identifier (links to MARKET) |
| BUSINESSDATE | DATE | Business date of pricing |

**Price Fields:**

| Column | Type | Description |
|--------|------|-------------|
| PX_LAST | NUMBER | Last price |
| PX_BID | NUMBER | Bid price |
| PX_ASK | NUMBER | Ask price |
| PX_MID | NUMBER | Mid price |
| PX_OPEN | NUMBER | Opening price |
| PX_HIGH | NUMBER | High price |
| PX_LOW | NUMBER | Low price |
| PX_CLOSE_1D | NUMBER | Previous day close |
| PX_VOLUME | NUMBER | Trading volume |

**Yield & Spread Columns:**

| Column | Type | Description |
|--------|------|-------------|
| YLD_YTM_MID | NUMBER | Yield to maturity (mid) |
| YLD_YTM_BID | NUMBER | Yield to maturity (bid) |
| YLD_YTM_ASK | NUMBER | Yield to maturity (ask) |
| YLD_CNV_MID | NUMBER | Yield to convention (mid) |
| OAS_SPREAD_MID | NUMBER | Option-adjusted spread (mid) |
| ASW_SPREAD | NUMBER | Asset swap spread |
| Z_SPREAD_MID | NUMBER | Z-spread (mid) |
| DISCOUNT_MARGIN | NUMBER | Discount margin (floaters) |

**Duration & Risk:**

| Column | Type | Description |
|--------|------|-------------|
| DUR_ADJ_MID | NUMBER | Modified duration (mid) |
| DUR_ADJ_OAS_MID | NUMBER | OAS-adjusted duration |
| CONV_MID | NUMBER | Convexity (mid) |
| DV01 | NUMBER | Dollar value of 1bp |

**Total Return:**

| Column | Type | Description |
|--------|------|-------------|
| PREV_BUS_TRR_1DAY | NUMBER | 1-day total return |
| PREV_BUS_TRR_1WK | NUMBER | 1-week total return |
| PREV_BUS_TRR_1MO | NUMBER | 1-month total return |
| PREV_BUS_TRR_1YR | NUMBER | 1-year total return |
| PREV_BUS_ANN_TRR_3YR | NUMBER | 3-year annualized total return |
| PREV_BUS_ANN_TRR_5YR | NUMBER | 5-year annualized total return |

**Equity Analytics:**

| Column | Type | Description |
|--------|------|-------------|
| PE_RATIO | NUMBER | Price-to-earnings ratio |
| EQY_DVD_YLD_IND | NUMBER | Indicated dividend yield |
| CUR_MKT_CAP | NUMBER | Current market capitalization |
| OPEN_INT | NUMBER | Open interest (derivatives) |
| VOLUME_AVG_30D | NUMBER | 30-day average volume |

---

### CORE.RATING

**~411 columns** | Primary key: `ID_BPL_INSTRUMENT`

Credit ratings from major rating agencies (S&P, Moody's, Fitch, DBRS, etc.).

| Column | Type | Description |
|--------|------|-------------|
| UPDATESET | TEXT | Bloomberg update set identifier |
| APPLIEDTIME | TIMESTAMP_NTZ | Timestamp when data was applied |
| ID_BPL_INSTRUMENT | TEXT | Bloomberg instrument identifier |
| RTG_SP | TEXT | S&P issuer credit rating |
| RTG_SP_LT_LC_ISSUER_CREDIT | TEXT | S&P long-term local currency issuer credit rating |
| RTG_SP_LT_FC_ISSUER_CREDIT | TEXT | S&P long-term foreign currency issuer credit rating |
| RTG_MOODY | TEXT | Moody's rating |
| RTG_MOODY_LONG_TERM | TEXT | Moody's long-term rating |
| RTG_FITCH | TEXT | Fitch rating |
| RTG_FITCH_LT_ISSUER_DEFAULT | TEXT | Fitch long-term issuer default rating |
| RTG_DBRS | TEXT | DBRS rating |
| RTG_DBRS_LT_ISSUER | TEXT | DBRS long-term issuer rating |

*Contains ratings from many additional agencies and jurisdictions, including watch/outlook statuses.*

---

### CORE.SCHEDULE

**~200+ columns** | Primary key: `ID_BPL_INSTRUMENT`

Payment and amortization schedule information for fixed income instruments.

| Column | Type | Description |
|--------|------|-------------|
| UPDATESET | TEXT | Bloomberg update set identifier |
| APPLIEDTIME | TIMESTAMP_NTZ | Timestamp when data was applied |
| ID_BPL_INSTRUMENT | TEXT | Bloomberg instrument identifier |
| SINK_SCHEDULE | TEXT | Sinking fund schedule |
| CALL_SCHEDULE | TEXT | Call schedule |
| PUT_SCHEDULE | TEXT | Put schedule |
| RESET_SCHEDULE | TEXT | Rate reset schedule |

---

## Schema: BULK

The BULK schema contains multi-row (array) data that cannot be represented in single rows in the CORE tables. Each view has a standard structure with `BULK_ROW` as a row counter.

**Common columns across all BULK views:**

| Column | Type | Description |
|--------|------|-------------|
| UPDATESET | TEXT | Bloomberg update set identifier |
| APPLIEDTIME | TIMESTAMP_NTZ | Timestamp when data was applied |
| ID_BPL_* | TEXT | Foreign key (INSTRUMENT, ENTITY, MARKET, or CAX) |
| BULK_ROW | NUMBER | Row sequence number within the array |

### BULK Views — Corporate Actions (ID_BPL_CAX)

| View | Description |
|------|-------------|
| ADDITIONAL_DVD_CRNCY | Additional dividend currency amounts |
| ADVISERS_LIST | List of advisers for corporate actions |
| AMENDED_TERMS | Amended terms history for offerings |
| CP_ACQUIRER_CONSORTIUM | Acquirer consortium members in M&A |
| CP_ADVISORS | Corporate action advisors with percentages |
| CP_COLLAR | Collar conditions and payout structures |
| CP_REORG_PLAN | Reorganization plan details |
| CP_SELLER_CONSORTIUM | Seller consortium members |
| CP_TARGET_CONSORTIUM | Target consortium members |
| CP_UNIT_BBIDS | Unit Bloomberg IDs for corporate actions |

### BULK Views — Instrument Level (ID_BPL_INSTRUMENT)

| View | Description |
|------|-------------|
| CERT_UNDERLYING | Certificate underlying securities and weightings |
| COLLAT_TYPES | Collateral types for structured products |
| DELIVERY_TYP_LIST | Delivery type options for derivatives |
| FLT_PAY_HOLIDAY_CDR | Floating payment holiday calendars |
| FLT_REFIX_HOLIDAY_CDR | Floating refix holiday calendars |
| FUND_ASSET_ALLOC_CALC | Fund asset allocation percentages |
| GOVERNING_LAW | Governing law jurisdictions |
| HB_GEO_CNTRY_ALLOC | Fund geographic country allocation |
| HB_INDUSTRY_GROUP_ALLOC | Fund industry/sector allocation |
| ISSUE_UNDERWRITER | Bond underwriter details |

### BULK Views — Entity Level (ID_BPL_ENTITY)

| View | Description |
|------|-------------|
| ALTERNATE_COMPANY_NAME | Alternative company names |
| COUPON_TYP_DISTRIBUTION | Coupon type distribution of outstanding debt |
| COUPON_TYP_DISTRIBUTION_ISSUER | Issuer-level coupon type distribution |
| CRNCY_DISTRIBUTION | Currency distribution of outstanding debt |
| CRNCY_DISTRIBUTION_ISSUER | Issuer-level currency distribution |
| DBT_TYPE | Debt type breakdown |
| DBT_TYPE_ISSUER | Issuer-level debt type breakdown |
| DDIS_AMT_OUT_BY_YR_ISUR_SUB_BNLN | Amount outstanding by year (issuer sub-bonds/loans) |

### BULK Views — Market Level (ID_BPL_MARKET)

| View | Description |
|------|-------------|
| DES_CASH_FLOW | Descriptive cash flow schedule (coupon + principal) |
| FLT_CPN_HIST | Floating coupon rate history |

---

## Schema: EXT

### EXT.CORP_ACTIONS

**~900 columns** | Primary key: `ID_BPL_CAX`

Comprehensive corporate actions data covering M&A, IPOs, dividends, splits, spin-offs, tender offers, and more.

| Column | Type | Description |
|--------|------|-------------|
| UPDATESET | TEXT | Bloomberg update set identifier |
| APPLIEDTIME | TIMESTAMP_NTZ | Timestamp when data was applied |
| ID_BPL_CAX | TEXT | Bloomberg corporate action identifier (primary key) |
| BPL_ACTIVE | BOOLEAN | Whether corporate action is active |
| BPL_STATUS | TEXT | Corporate action lifecycle status |

**Action Classification:**

| Column | Type | Description |
|--------|------|-------------|
| CP_ACTION_TYP | TEXT | Corporate action type |
| CP_ACTION_STATUS | TEXT | Action status |
| MARKET_SECTOR_DES | TEXT | Market sector |
| OFFERING_TYPE_IPO_OR_ADDITIONAL | TEXT | IPO vs additional offering |
| OFFERING_STAGE | TEXT | Stage of offering |

**Dates:**

| Column | Type | Description |
|--------|------|-------------|
| DVD_EX_DT | DATE | Dividend ex-date |
| DVD_PAY_DT | DATE | Dividend pay date |
| DVD_RECORD_DT | DATE | Dividend record date |
| ANNOUNCE_DT | DATE | Announcement date |
| EFFECTIVE_DT | DATE | Effective date |
| LAUNCH_DATE | DATE | Launch date |
| LISTING_DATE | DATE | Listing date |

**M&A Fields:**

| Column | Type | Description |
|--------|------|-------------|
| CP_DEAL_STATUS | TEXT | Deal status |
| CP_DEAL_VALUE | NUMBER | Deal value |
| CP_ACQUIRER_NAME | TEXT | Acquirer name |
| CP_TARGET_NAME | TEXT | Target name |
| LONG_COMP_NAME | TEXT | Company long name |
| MARKET_CAPITALIZATION | NUMBER | Market capitalization |

**IPO/Offering Fields:**

| Column | Type | Description |
|--------|------|-------------|
| OFFERING_PLACING_PRICE | NUMBER | Placing price |
| OFFERING_PLACING_SHARES | NUMBER | Shares placed |
| OFFERING_GROSS_SPREAD | NUMBER | Gross spread |
| NUM_SHARES_OFFRD_FILING_TERM | NUMBER | Shares offered at filing |
| LEAD_MGR | TEXT | Lead manager |

---

### EXT.SUBSCRIPTION

**10 columns** | Primary key: `ID_BPL_SUBSCRIPTION`

Metadata about data subscriptions/entitlements.

| Column | Type | Description |
|--------|------|-------------|
| UPDATESET | TEXT | Bloomberg update set identifier |
| BPL_ID | TEXT | Bloomberg product line ID |
| ID_BPL_SUBSCRIPTION | TEXT | Subscription identifier (primary key) |
| APPLIEDTIME | TIMESTAMP_NTZ | Timestamp when data was applied |
| DATA_PRODUCT_TYPE | TEXT | Type of data product subscribed |
| DELETIONTIME | TIMESTAMP_NTZ | When subscription was deleted (if applicable) |
| PRICE_POINT | TEXT | Pricing tier/point |
| STATUS | TEXT | Subscription status |
| STRATEGY | TEXT | Subscription strategy |
| SUBSCRIBER | TEXT | Subscriber identifier |

---

## Schema: LOOKUP

The LOOKUP schema contains ~200 reference/code-value lookup tables. **All lookup tables share the same structure:**

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| UPDATESET | TEXT | NO | Bloomberg update set identifier |
| CODE | TEXT | NO | Lookup code value |
| PARENT_CODE | TEXT | NO | Parent code for hierarchical lookups |
| APPLIEDTIME | TIMESTAMP_NTZ | YES | Timestamp when data was applied |
| PARENT_CODE_TABLE | TEXT | YES | Name of the parent lookup table |
| VALUE | TEXT | YES | Human-readable description/value for the code |

### Lookup Tables by Category

**Asset Classification:**
- `ASSET_CLASS` — Asset class codes
- `BPIPE_REFERENCE_SECURITY_CLASS` — Security class reference
- `MARKET_SECTOR_DES` — Market sector descriptions
- `SECURITY_TYP` — Security type codes
- `SECURITY_TYP2` — Secondary security types

**Geographic/Country:**
- `CNTRY_OF_DOMICILE` — Country of domicile codes
- `CNTRY_OF_INCORPORATION` — Country of incorporation codes
- `CNTRY_OF_RISK` — Country of risk codes
- `COUNTRY_ISO` — ISO country codes
- `COUNTRY_FULL_NAME` — Full country names

**Fixed Income:**
- `CPN_TYP` — Coupon types (Fixed, Float, Zero, etc.)
- `CPN_FREQ` — Coupon frequency codes
- `COLLAT_TYP` — Collateral types
- `DAY_CNT_DES` — Day count conventions
- `PAYMENT_RANK` — Payment rank/seniority
- `MTG_DEAL_TYP` — Mortgage deal types
- `RESET_IDX` — Reset index codes
- `YLD_FLAG` — Yield calculation flags
- `XO_REDEMP_TYP` — Redemption types

**Equity:**
- `EQY_PRIM_EXCH` — Primary exchange codes
- `EXCH_CODE` — Exchange codes
- `INDUSTRY_GROUP` — Industry group codes
- `INDUSTRY_SECTOR` — Industry sector codes
- `INDUSTRY_SUBGROUP` — Industry subgroup codes

**Options/Derivatives:**
- `OPT_EXER_TYP` — Option exercise types
- `OPT_PUT_CALL` — Put/Call indicator
- `OPT_EXOTIC_TYP` — Exotic option types
- `DELIVERY_TYP` — Delivery types

**Ratings:**
- `RTG_SP` — S&P rating codes
- `RTG_MOODY` — Moody's rating codes
- `RTG_FITCH` — Fitch rating codes
- `RTG_DBRS` — DBRS rating codes

**Fund:**
- `FUND_ASSET_CLASS_FOCUS` — Fund asset class focus
- `FUND_GEO_FOCUS` — Fund geographic focus
- `FUND_TYP` — Fund type codes

**Corporate Actions:**
- `CP_ACTION_TYP` — Corporate action types
- `CP_ACTION_STATUS` — Corporate action statuses
- `CP_DEAL_STATUS` — M&A deal statuses

**Warrant:**
- `WRT_COVERED` — Covered warrant indicator
- `WRT_EQY_PRIM_EXCH` — Warrant primary exchange
- `WRT_EXER_TYP` — Warrant exercise types
- `WRT_PX_TYP` — Warrant price types
- `WRT_SETTLE_TYP` — Warrant settlement types
- `WRT_TYP` — Warrant types

**Currency:**
- `CRNCY` — Currency codes
- `DVD_CRNCY` — Dividend currency codes

**Sanctions:**
- `AUSTRALIAN_SANCTION_STATUS` — Australian sanction statuses
- `BIS_STATUS` — BIS sanction statuses
- `CANADIAN_SANCTION_STATUS` — Canadian sanction statuses
- `EU_SANCTION_STATUS` — EU sanction statuses
- `UK_SANCTION_STATUS` — UK sanction statuses
- `OFAC_STATUS` — OFAC sanction statuses
- `VOTING_RIGHTS_DES` — Voting rights descriptions

---

## Schema: META

### META.CLIENT_CLAIM

**1 column** | Tracks client claim UUIDs for data entitlements.

| Column | Type | Description |
|--------|------|-------------|
| CLAIM_UUID | TEXT | Unique claim identifier |

### META.JOBS

**6 columns** | Tracks Bloomberg data delivery jobs.

| Column | Type | Description |
|--------|------|-------------|
| UPDATESET | TEXT | Bloomberg update set identifier |
| UPDATE_TIME | TIMESTAMP_NTZ | When the update was processed |
| SCHEMA_CHANGES | TEXT | Any schema changes in this update |
| STATUS | TEXT | Job completion status |
| TRACKING_ID | NUMBER | Bloomberg tracking ID for the job |
| UPDATED_TABLES | TEXT | List of tables updated in this job |

---

## Key Relationships

```
CORE.ENTITY (ID_BPL_ENTITY)
    │
    ├──> CORE.INSTRUMENT (ID_BPL_ENTITY → parent entity)
    │        │
    │        ├──> CORE.MARKET (ID_BPL_INSTRUMENT → parent instrument)
    │        │        │
    │        │        └──> CORE.PRICE (ID_BPL_MARKET → market listing)
    │        │
    │        ├──> CORE.RATING (ID_BPL_INSTRUMENT)
    │        │
    │        ├──> CORE.SCHEDULE (ID_BPL_INSTRUMENT)
    │        │
    │        └──> BULK.* views with ID_BPL_INSTRUMENT
    │
    └──> BULK.* views with ID_BPL_ENTITY

EXT.CORP_ACTIONS (ID_BPL_CAX)
    └──> BULK.* views with ID_BPL_CAX
```

---

## Notes for Synthetic Data Generation

1. **Primary Keys**: Use `ID_BPL_*` format (text UUIDs) for all primary keys.
2. **UPDATESET**: A batch identifier string — use format like `"20260714_001"`.
3. **APPLIEDTIME**: Timestamp of data delivery — use recent timestamps.
4. **BULK_ROW**: Sequential integer starting at 1 for each parent key.
5. **LOOKUP tables**: All share identical structure — generate code/value pairs per table name.
6. **Scale**: CORE.INSTRUMENT and CORE.PRICE have 2,400+ and 850+ columns respectively. For synthetic data, focus on the key columns documented above.
7. **Data Types**: Most columns are TEXT or NUMBER. Dates use DATE type, flags use BOOLEAN.
8. **Nullability**: Key columns (UPDATESET, ID_BPL_*) are NOT NULL; most data columns are nullable.
