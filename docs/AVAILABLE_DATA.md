# Snowflake Public Data (Paid) — Available Data for Investment Banking

> **For:** Sahana, Mark, Anup
> **Purpose:** Show what data is available and how it maps to IB workflows.
> All of this is included in the Snowflake Public Data (Paid) listing — no additional procurement needed.

---

## How to read this document

Data is grouped by **IB use case**, not by source. For each group:

- **What's in it** — the datasets available
- **IB application** — specific workflows this supports
- **Example questions** — what an analyst could ask an agent
- **Status** — whether we're already using it in ORBIT or not

---

## 1. Equity Research & Company Fundamentals

> The core of any pitchbook or comp analysis.

**Datasets:**

- `SEC_CORPORATE_REPORT_ATTRIBUTES` — Parsed XBRL financials (revenue, EPS, margins, balance sheet) from 10-K and 10-Q filings
- `SEC_METRICS_TIMESERIES` — Standardised revenue segments by company (product, geography, service line)
- `SEC_CORPORATE_REPORT_TEXT_ATTRIBUTES` — Full text of 10-K/10-Q filings (Risk Factors, MD&A, Business Description)
- `SEC_CORPORATE_REPORT_ITEM_ATTRIBUTES` — Filing sections parsed into structured JSON for LLM use
- `SEC_FISCAL_CALENDARS` — Company fiscal year/quarter period boundaries
- `XBRL_TAXONOMY_INDEX` — Financial concept taxonomy for interpreting XBRL tags

**IB application:**

- Comparable company analysis (comps)
- DCF model inputs (revenue, margins, capex, FCF)
- Financial due diligence (DD)
- Pitchbook financial summaries

**Example questions:**

- "What are Apple's revenue segments for the last 4 quarters?"
- "Compare gross margins across FAANG companies"
- "What did Tesla say about supply chain risks in their latest 10-K?"

**Status:** ✅ Financials in use · ✅ Segments loaded (not yet exposed) · ✅ Filing text in Cortex Search

---

## 2. Investor & Ownership Intelligence

> Who owns what, who's buying/selling, and what are funds doing.

**Datasets:**

- `SEC_HOLDING_FILING_ATTRIBUTES` / `SEC_13F_ATTRIBUTES` — Quarterly 13F institutional holdings (funds with $100M+ AUM)
- `SEC_NPORT_INVESTMENTS_INDEX` — Monthly fund portfolio holdings (more timely than 13F)
- `SEC_NPORT_FILING_INDEX` / `SEC_NPORT_TIMESERIES` — Fund-level financial statistics
- `SEC_FORM4_SECURITIES_INDEX` / `SEC_FORM4_REPORTING_OWNERS_INDEX` — Insider trading (Form 4)
- `SEC_INSIDER_TRADING_SECURITIES_INDEX` — Combined Forms 3, 4, 5 insider transactions
- `SEC_FORM144_SECURITIES_TO_BE_SOLD_INDEX` — Insider intent to sell (Rule 144)
- `SEC_INVESTMENT_ADVISERS_TIMESERIES` — Investment adviser AUM, strategy, registration details
- `SEC_INVESTMENT_COMPANY_INDEX` — Registered investment company series and classes

**IB application:**

- Shareholder identification for M&A
- Institutional flow analysis (who's accumulating/distributing)
- Insider sentiment signals (pre-deal activity detection)
- Investor targeting for capital raises (ECM/DCM)
- Fund-level DD for asset management coverage

**Example questions:**

- "Who are the top 20 holders of NVDA and how did their positions change?"
- "Show me insider buying across tech stocks in the last 30 days"
- "Which funds increased their allocation to energy this quarter?"
- "What is Vanguard's total position in Apple across all their funds?"

**Status:** ✅ 13F in use · ✅ Form 4 in use · ❌ NPORT not yet ingested · ❌ Investment advisers not yet ingested

---

## 3. Corporate Governance & Proxy

> Board composition, executive compensation, shareholder votes.

**Datasets:**

- `SEC_14A_ATTRIBUTES` — Proxy statement data (executive comp, director elections, Say-on-Pay, shareholder proposals)
- `SEC_8K_ATTRIBUTES` — 8-K Item 5.07 voting results (proposal subjects, vote counts)

**IB application:**

- M&A governance analysis (board independence, anti-takeover provisions)
- Executive compensation benchmarking
- Activist investor monitoring (shareholder proposal outcomes)
- ESG governance scoring

**Example questions:**

- "What was the CEO's total compensation at Goldman Sachs last year?"
- "Did Say-on-Pay pass at all S&P 500 companies this proxy season?"
- "Which companies had shareholder proposals receive >30% support?"

**Status:** ❌ Not yet ingested — planned for Phase 2C

---

## 4. Rates, Fixed Income & Credit

> Everything needed for DCM, leveraged finance, and rate strategy.

**Datasets:**

- `US_TREASURY_TIMESERIES` — Full Treasury curve (par yields, TIPS, real yields), corporate bond yields, savings bond data, securities issuance, revenue collections
- `FEDERAL_RESERVE_TIMESERIES` — Consumer credit, commercial paper, industrial production, capacity utilisation, financial accounts (assets/liabilities/net worth)
- `FINANCIAL_ECONOMIC_INDICATORS_TIMESERIES` — SOFR, EFFR, mortgage rates (Freddie Mac), GDP, CPI, retail sales, unemployment claims
- `FREDDIE_MAC_HOUSING_TIMESERIES` — Weekly 30Y/15Y mortgage rates, house price index

**IB application:**

- Yield curve analysis and spread decomposition
- DCM pricing (new issue premiums relative to benchmarks)
- Credit cycle positioning (consumer credit tightening/easing)
- Leveraged finance market timing
- Rate strategy (SOFR/EFFR trajectory)

**Example questions:**

- "What's the current 10Y-2Y Treasury spread and how has it moved?"
- "Show the corporate bond yield vs Treasury spread over 5 years"
- "Is consumer credit growth accelerating or decelerating?"
- "What's the current 30-year fixed mortgage rate?"

**Status:** ✅ Basic Treasury yields in use · ❌ Full curve, corporates, Fed data not yet ingested

---

## 5. Global Macro & Sovereign Risk

> Cross-border M&A, EM risk, sovereign debt analysis.

**Datasets:**

- `INTERNATIONAL_MONETARY_FUND_TIMESERIES` — Commodity prices, balance of payments, government finances, international financial statistics, regional economic outlooks
- `WORLD_BANK_TIMESERIES` — Country ESG scores (17 themes), governance indicators (6 dimensions), development indicators, external debt, public sector debt
- `BANK_FOR_INTERNATIONAL_SETTLEMENTS_TIMESERIES` — Property prices, policy rates, credit-to-GDP, banking statistics, consumer prices
- `OECD_TIMESERIES` — Trade, wages, VC investment, income distribution, population, social expenditure
- `WORLD_TRADE_ORGANIZATION_TIMESERIES` — Trade flows and tariff rates between economies

**IB application:**

- Country risk assessment for cross-border M&A
- Sovereign bond analysis (debt sustainability)
- ESG-linked bond structuring (World Bank governance scores)
- Emerging market macro overview
- Trade flow analysis (tariffs, supply chain risk)

**Example questions:**

- "What's Brazil's current account deficit trend?"
- "Rank G20 countries by governance score"
- "How has China's credit-to-GDP ratio moved over 10 years?"
- "What commodities has India's import bill been most sensitive to?"

**Status:** ✅ BIS policy rates in use · ❌ IMF, World Bank, OECD, WTO not yet ingested

---

## 6. Banking & Financial Institutions (FIG)

> For the Financial Institutions Group — bank M&A, target screening, precedent transactions.

**Datasets:**

- `FINANCIAL_INSTITUTION_TIMESERIES` — FDIC call report data (financial statements, UBPRs) for all US banks
- `FINANCIAL_INSTITUTION_ENTITIES` — All US banks with charter details, start dates, geographic info
- `FINANCIAL_INSTITUTION_HIERARCHY` — Holding company → bank → branch relationships
- `FINANCIAL_INSTITUTION_EVENTS` — Bank mergers, failures, asset sales, charter discontinuations
- `FINANCIAL_BRANCH_ENTITIES` — Branch locations for all FDIC-insured institutions
- `FDIC_SUMMARY_OF_DEPOSITS_TIMESERIES` — Annual branch-level deposit data
- `SEC_BROKER_DEALER_INDEX` — Registered broker-dealers
- `SEC_SWAP_DEALER_INDEX` — Security-based swap dealers and major participants

**IB application:**

- Bank M&A target screening (CET1, NIM, efficiency ratio)
- Precedent transaction analysis (historical bank mergers)
- Branch network valuation (deposits per branch)
- Regulatory capital analysis
- Counterparty risk assessment

**Example questions:**

- "Which regional banks have CET1 > 12% and NIM declining?"
- "Show me bank M&A events in the last 3 years with asset values"
- "What's the deposit concentration for JPMorgan by state?"

**Status:** ❌ Not yet ingested — planned for Phase 2D

---

## 7. Real Estate & Structured Products

> Housing market intelligence for RMBS, REIT coverage, and real estate M&A.

**Datasets:**

- `FHFA_HOUSE_PRICE_TIMESERIES` — US home price indices since 1975 (state, MSA, national)
- `FHFA_MORTGAGE_PERFORMANCE_TIMESERIES` — Loan delinquency, forbearance, prepayment
- `FHFA_UNIFORM_APPRAISAL_TIMESERIES` — Home appraisal trends (values, features)
- `FREDDIE_MAC_HOUSING_TIMESERIES` — Weekly mortgage rates, HPI
- `US_REAL_ESTATE_TIMESERIES` — Building permits, construction spending
- `HOME_MORTGAGE_DISCLOSURE_ATTRIBUTES` — Loan-level HMDA data (applications, originations, denials, demographics)

**IB application:**

- RMBS analysis (delinquency trends, prepayment speeds)
- Real estate deal comps (price trends by metro)
- Housing market timing for related issuances
- Fair lending analysis (HMDA)
- Construction sector outlook

**Example questions:**

- "How have home prices moved in Florida vs California since 2020?"
- "What's the current 60+ day delinquency rate nationally?"
- "Show building permit trends — is construction slowing?"

**Status:** ❌ Not yet ingested — planned for Phase 2E

---

## 8. ESG, Climate & Sustainability

> For green bond structuring, ESG screening, and sustainability reporting.

**Datasets:**

- `CLIMATE_WATCH_TIMESERIES` — GHG emissions by country, sector, gas + future scenarios
- `EUROPEAN_COMMISSION_EDGAR_TIMESERIES` — CO2, CH4, N2O, F-gas emissions by country and industry
- `OUR_WORLD_IN_DATA_TIMESERIES` — Global CO2 emissions by source
- `WORLD_BANK_TIMESERIES` (ESG subset) — 17 sustainability themes, governance indicators
- `FACT_COUNTRY_EMISSIONS` (already loaded in ORBIT) — Country emissions by sector

**IB application:**

- Green/sustainability-linked bond structuring (KPI selection)
- ESG screening for deal pipeline
- Carbon intensity benchmarking
- Transition risk assessment
- Net-zero pathway analysis

**Example questions:**

- "Which G20 countries are on track to reduce emissions 50% by 2030?"
- "What's India's carbon intensity per unit GDP?"
- "Compare energy sector emissions: US vs EU vs China"

**Status:** ✅ Emissions loaded (not yet exposed) · ❌ World Bank ESG not yet ingested

---

## 9. Market Data & FX

> Daily prices, exchange rates, equity market intelligence.

**Datasets:**

- `STOCK_PRICE_TIMESERIES` — Daily OHLCV for all Nasdaq securities (pre-market open, post-market close, volume)
- `FX_RATES_TIMESERIES` — 130+ currency pairs from ECB, BIS, IMF, and central banks

**IB application:**

- Equity valuation (current and historical prices)
- FX risk assessment for cross-border deals
- Peer stock performance comparison
- Volume analysis (liquidity for block trades)

**Example questions:**

- "Show AAPL vs MSFT stock performance over 1 year"
- "What's the GBP/USD trend over 3 months?"
- "Which stocks had highest volume spike this week?"

**Status:** ✅ Fully in use

---

## 10. Corporate Structure & Identifiers

> The connective tissue between datasets.

**Datasets:**

- `COMPANY_INDEX` — 100K companies with CIK, EIN, LEI, PermID, tickers
- `COMPANY_RELATIONSHIPS` — Parent/subsidiary structures
- `COMPANY_SECURITY_RELATIONSHIPS` — Company → security identifier mapping (OpenFIGI, PermID)
- `COMPANY_CHARACTERISTICS` — Addresses, industry codes, temporal attributes
- `COMPANY_DOMAIN_RELATIONSHIPS` — Company → website mapping
- `OPENFIGI_SECURITY_INDEX` — Global security identifiers
- `PERMID_SECURITY_INDEX` — Refinitiv PermID security details
- `SEC_CIK_INDEX` — CIK to company mapping with SIC codes
- `GEOGRAPHY_INDEX` / `GEOGRAPHY_HIERARCHY` — Standardised geographic entities

**IB application:**

- M&A group structure mapping ("Who owns this entity?")
- Cross-dataset joins (link SEC filings to stock prices to institutional holdings)
- Geographic analysis at any level (country → zip code)
- Security identifier resolution

**Status:** ✅ Company Index in use · ❌ Corporate structure not yet ingested

---

## 11. Distressed & Restructuring Signals

> Early warning indicators for special situations coverage.

**Datasets:**

- `WARN_ACT_TIMESERIES` — Mass layoff and plant closure notices (60-day advance notice, 6 priority states)
- `FINANCIAL_INSTITUTION_EVENTS` — Bank failures and asset sales
- `FINANCIAL_CFPB_COMPLAINT` — Consumer complaints about financial products (signal for regulatory risk)

**IB application:**

- Early identification of restructuring candidates
- Distressed debt screening
- Labour market stress signals by geography
- Regulatory risk monitoring

**Example questions:**

- "Which companies filed WARN notices in New York this month?"
- "Show bank failures in the last 5 years with asset sizes"
- "Are consumer complaints rising at any specific institution?"

**Status:** ❌ Not yet ingested — planned for Phase 2C

---

## 12. Earnings & Management Commentary

> Qualitative intelligence from management.

**Datasets:**

- `COMPANY_EVENT_TRANSCRIPT_ATTRIBUTES` — Full earnings call transcripts (9,000+ companies), investor days, M&A announcements, AGMs. JSON format with speaker annotations.

**IB application:**

- Sentiment analysis on forward guidance
- Keyword extraction (capex plans, M&A intent, headcount)
- Management tone comparison across quarters
- Competitive intelligence from peer calls

**Example questions:**

- "What did NVIDIA's CEO say about AI demand in the last earnings call?"
- "Has Apple's management tone on China changed over the last 3 quarters?"
- "Which companies mentioned 'restructuring' in their latest call?"

**Status:** ✅ In Cortex Search (full-text search over 76K transcripts)

---

## 13. Patents & Intellectual Property

> IP valuation for tech M&A and R&D-intensive sectors.

**Datasets:**

- `USPTO_PATENT_INDEX` — Patent applications and grants (filing dates, CPC categories, publication IDs)
- `USPTO_CONTRIBUTOR_INDEX` — Patent inventors and assignees
- `USPTO_PATENT_CONTRIBUTOR_RELATIONSHIPS` — Who contributed to which patent
- `USPTO_PATENT_TEXT_ATTRIBUTES` — Full patent text (abstract, claims, description)
- `USPTO_PATENT_RELATIONSHIPS` — Related patent applications

**IB application:**

- IP portfolio valuation for tech M&A
- R&D activity tracking by company
- Competitive patent landscape analysis
- Due diligence on IP assets

**Example questions:**

- "How many patents has Qualcomm filed in the last 3 years vs Apple?"
- "What technology categories are Alphabet patenting most in?"

**Status:** ❌ Not yet ingested — planned for Phase 2C

---

## 14. Alternative Data (Not in Public Data — Requires Separate Licensing)

> Datasets that complement the above but require external sourcing.

- **Bloomberg Second Measure** — Credit/debit card transaction data at merchant level. Enables consumer spend nowcasting before earnings. ⭐ Sahana priority (see Phase 2 in CHANGES.md).
- **Consumer Edge / Earnest Analytics** — Available on Snowflake Marketplace as alternatives.

---

## Summary: What's Used vs Available

| Category                          | Available | In Use | Gap                                   |
| --------------------------------- | --------- | ------ | ------------------------------------- |
| Equity Research & Fundamentals    | 6 tables  | 4      | Segments exposed but not wired        |
| Investor & Ownership             | 8 tables  | 3      | NPORT, advisers missing               |
| Corporate Governance             | 2 tables  | 0      | Not yet ingested                      |
| Rates & Fixed Income             | 4 tables  | 1      | Full Treasury, Fed, corporates needed |
| Global Macro                     | 5 tables  | 1      | IMF, World Bank, OECD, WTO needed    |
| Banking / FIG                    | 8 tables  | 0      | Not yet ingested                      |
| Real Estate                      | 6 tables  | 0      | Not yet ingested                      |
| ESG & Climate                    | 5 tables  | 1      | Loaded but not exposed                |
| Market Data & FX                 | 2 tables  | 2      | Fully covered                         |
| Corporate Structure              | 9 tables  | 2      | Relationships, characteristics needed |
| Distressed / Restructuring       | 3 tables  | 0      | Not yet ingested                      |
| Earnings Transcripts             | 1 table   | 1      | Fully covered                         |
| Patents & IP                     | 5 tables  | 0      | Not yet ingested                      |
| **Total**                        | **64+**   | **15** | **~75% opportunity remaining**        |
