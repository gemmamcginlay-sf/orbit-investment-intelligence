# S&P Global Compustat XpressFeed Data Dictionary

## Database: DEV_EDP_EDP_XF_BARCLAYSEXECU_DEV_EDP1_VA_DB

This document describes the S&P Global Market Intelligence Compustat XpressFeed data available in this database. The data covers global company financials, security pricing, index constituents, ownership, and reference data.

---

## Schema Overview

| Schema | Object Count | Type | Description |
|--------|-------------|------|-------------|
| XPRESSFEED | 608 | Views | Primary data access layer — all S&P Compustat XpressFeed tables |
| XPRESSFEED_CDC | 606 | Views | Change Data Capture (CDC) mirror of XPRESSFEED for incremental processing |
| VA | 0 | Empty | Value-Added schema (currently unpopulated) |

---

## Data Categories

The 608 views in the XPRESSFEED schema are organized into the following functional categories:

1. **Company Reference & Fundamentals** — Company master data, annual/quarterly financials
2. **Security Reference & Pricing** — Security identifiers, daily/monthly prices, returns
3. **Index Data** — S&P index definitions, daily/monthly values, constituents
4. **Ownership & Insider Trading** — Institutional ownership, insider transactions
5. **Segments** — Business segment reporting (geographic, product, customer)
6. **Exchange Rates & Currency** — FX rates, currency reference
7. **Ratings & Industry Classification** — GICS, SIC, NAICS classifications
8. **Capital IQ (CIQ)** — Extended Capital IQ data (M&A, estimates, transcripts, filings)
9. **Reference/Lookup Tables** — Code lookups (R_ prefix tables)
10. **Data Dictionary** — Metadata about data items (DD_ prefix)
11. **SME/People** — Executive and professional data
12. **Toyo Keizai** — Japanese shareholder/company data

---

## 1. Company Reference & Fundamentals

### COMPANY
**Row Count:** ~138,746  
**Description:** Master company reference file. One row per company (GVKEY). Contains identifying information, industry codes, and status for all companies in the Compustat universe.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key — unique 6-character company identifier |
| CONM | TEXT | YES | Company Name (short format) |
| CONML | TEXT | YES | Company Name (long format) |
| ADD1–ADD4 | TEXT | YES | Address lines 1–4 |
| ADDZIP | TEXT | YES | Postal/ZIP code |
| CITY | TEXT | YES | City |
| STATE | TEXT | YES | State/Province code |
| COUNTY | TEXT | YES | County |
| FIC | TEXT | YES | Foreign Incorporation Code (ISO country) |
| LOC | TEXT | YES | Location country (ISO code) |
| INCORP | TEXT | YES | State/country of incorporation |
| PHONE | TEXT | YES | Phone number |
| FAX | TEXT | YES | Fax number |
| WEBURL | TEXT | YES | Company website URL |
| BUSDESC | TEXT | YES | Business description text |
| CIK | TEXT | YES | SEC Central Index Key |
| EIN | TEXT | YES | Employer Identification Number |
| SIC | TEXT | YES | Standard Industrial Classification code |
| NAICS | TEXT | YES | North American Industry Classification code |
| GSECTOR | TEXT | YES | GICS Sector code |
| GGROUP | TEXT | YES | GICS Industry Group code |
| GIND | TEXT | YES | GICS Industry code |
| GSUBIND | TEXT | YES | GICS Sub-Industry code |
| COSTAT | TEXT | YES | Company Status (A=Active, I=Inactive) |
| IPODATE | TIMESTAMP_NTZ | YES | IPO date |
| DLDTE | TIMESTAMP_NTZ | YES | Deletion date (when removed from database) |
| DLRSN | TEXT | YES | Deletion reason code |
| FYRC | NUMBER | YES | Fiscal Year-end month |
| IDBFLAG | TEXT | YES | International/Domestic/Both flag |
| PRICAN | TEXT | YES | Primary issue tag — Canada |
| PRIROW | TEXT | YES | Primary issue tag — Rest of World |
| PRIUSA | TEXT | YES | Primary issue tag — USA |
| SPCINDCD | NUMBER | YES | S&P Industry code |
| SPCSECCD | NUMBER | YES | S&P Sector code |
| SPCSRC | TEXT | YES | S&P source code |
| STKO | NUMBER | YES | Stock ownership type |

---

### CO_AFND1
**Row Count:** ~1,827,599  
**Description:** Company Annual Fundamentals (North America). Contains annual income statement, balance sheet, and cash flow data items for North American companies. Key financial dataset for annual analysis.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| DATADATE | TIMESTAMP_NTZ | NO | Data date (fiscal period end date) |
| INDFMT | TEXT | NO | Industry format (INDL=Industrial, FS=Financial Services, UT=Utility) |
| DATAFMT | TEXT | NO | Data format (STD=Standardized, SUMM=Summary) |
| CONSOL | TEXT | NO | Consolidation level (C=Consolidated, I=Individual) |
| POPSRC | TEXT | NO | Population source (D=Domestic, I=International) |
| FYR | NUMBER | NO | Fiscal Year-end month |
| *Financial data items* | NUMBER | YES | ~900+ annual financial data items (revenue, assets, liabilities, etc.) |

---

### CO_AFND2
**Description:** Company Annual Fundamentals (International/supplemental). Same structure as CO_AFND1 with additional international data items.

---

### CO_IFNDQ
**Row Count:** ~5,905,838  
**Description:** Company Interim (Quarterly) Fundamentals. Contains quarterly/semi-annual financial statement data — income statement, balance sheet, and cash flow items.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| DATADATE | TIMESTAMP_NTZ | NO | Data date (fiscal period end date) |
| INDFMT | TEXT | NO | Industry format |
| DATAFMT | TEXT | NO | Data format |
| CONSOL | TEXT | NO | Consolidation level |
| POPSRC | TEXT | NO | Population source |
| FYR | NUMBER | NO | Fiscal Year-end month |
| FQTR | NUMBER | YES | Fiscal quarter number (1–4) |
| *Financial data items* | NUMBER | YES | ~700+ quarterly financial data items |

---

### CO_IFNDSA
**Description:** Company Interim Fundamentals (Semi-Annual). Same key structure as CO_IFNDQ for semi-annual reporting periods.

### CO_IFNDYTD
**Description:** Company Interim Fundamentals (Year-to-Date cumulative). Year-to-date accumulated financial values.

---

### CO_MTHLY
**Row Count:** ~4,144,345  
**Description:** Company Monthly Snapshot. Monthly point-in-time market data linked to companies (market cap, shares, price-related items).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| DATADATE | TIMESTAMP_NTZ | NO | Month-end date |
| *Monthly items* | NUMBER | YES | Market capitalization, shares outstanding, price ratios |

---

### CO_INDUSTRY
**Row Count:** ~1,435,213  
**Description:** Company Industry History. Historical industry classification assignments for companies over time (SIC, NAICS, GICS changes).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| INDTYPE | TEXT | NO | Industry classification type |
| CONSOL | TEXT | NO | Consolidation level |
| *Classification fields* | TEXT/NUMBER | YES | Industry codes and effective dates |

---

### CO_HGIC
**Description:** Company Historical GICS codes. Tracks changes in GICS classification over time.

### CO_ACTHIST
**Description:** Company Action History. Corporate actions and status changes over time.

### CO_ADJFACT
**Description:** Company Adjustment Factors. Price/share adjustment factors for stock splits and dividends.

### CO_FILEDATE
**Description:** Company Filing Dates. SEC and regulatory filing dates for financial reports.

### CO_FORTUNE
**Description:** Company Fortune Rankings. Fortune 500/Global 500 rankings by year.

### CO_OFFTITL
**Description:** Company Officers and Titles. Executive/officer names and their titles.

### CO_BUSDESCL
**Description:** Company Business Description (Long). Extended business description text.

### CO_COTYPE
**Description:** Company Type codes. Classification of company legal structure/type.

### CO_IPCD
**Description:** Company Industry-specific Pension/Compensation Data.

---

## 2. Security Reference & Pricing

### SECURITY
**Row Count:** ~210,572  
**Description:** Security master file. One row per security issue (GVKEY + IID). Contains identifiers and exchange information for all securities in the universe.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| IID | TEXT | NO | Issue ID (unique within company, e.g., "01" for primary) |
| CUSIP | TEXT | YES | CUSIP identifier (9-character) |
| ISIN | TEXT | YES | International Securities Identification Number |
| SEDOL | TEXT | YES | SEDOL identifier (London Stock Exchange) |
| TIC | TEXT | YES | Ticker symbol |
| IBTIC | TEXT | YES | I/B/E/S ticker |
| TPCI | TEXT | YES | Issue type code (0=equity, others=debt/preferred) |
| EXCHG | NUMBER | YES | Exchange code |
| EXCNTRY | TEXT | YES | Exchange country (ISO code) |
| EPF | TEXT | YES | Earnings participation flag |
| DSCI | TEXT | YES | Security description |
| SECSTAT | TEXT | YES | Security status (A=Active, I=Inactive, X=Suspended) |
| DLDTEI | TIMESTAMP_NTZ | YES | Security deletion date |
| DLRSNI | TEXT | YES | Security deletion reason |

---

### SEC_DPRC
**Row Count:** ~475,690,869  
**Description:** Security Daily Pricing. The largest table — contains daily OHLC prices, volume, and related data for all securities. Primary source for daily stock price analysis.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| IID | TEXT | NO | Issue ID |
| DATADATE | TIMESTAMP_NTZ | NO | Trading date |
| CURCDD | TEXT | NO | Currency code for prices |
| PRCCD | NUMBER | YES | Price — Close (Daily) |
| PRCHD | NUMBER | YES | Price — High (Daily) |
| PRCLD | NUMBER | YES | Price — Low (Daily) |
| PRCOD | NUMBER | YES | Price — Open (Daily) |
| PRCSTD | NUMBER | YES | Price Status code |
| CSHTRD | NUMBER | YES | Shares Traded (Volume) |
| CSHOC | NUMBER | YES | Shares Outstanding (Current) |
| AJEXDI | NUMBER | YES | Adjustment Factor (cumulative) for splits/dividends |
| ADRRC | NUMBER | YES | ADR Ratio |
| DVI | NUMBER | YES | Dividend indicator |
| EPS | NUMBER | YES | Earnings Per Share (trailing 12-month) |
| EPSMO | NUMBER | YES | EPS month indicator |
| QUNIT | NUMBER | YES | Quotation unit (price multiplier) |

---

### SEC_MTHPRC
**Row Count:** ~7,711,663  
**Description:** Security Monthly Pricing. Month-end prices, returns, volume, and shares outstanding.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| IID | TEXT | NO | Issue ID |
| DATADATE | TIMESTAMP_NTZ | NO | Month-end date |
| CURCDDM | TEXT | YES | Currency code |
| PRCCM | NUMBER | YES | Price — Close (Monthly) |
| PRCHM | NUMBER | YES | Price — High (Monthly) |
| PRCLM | NUMBER | YES | Price — Low (Monthly) |
| TRTM | NUMBER | YES | Total Return (Monthly) |
| CSHTRM | NUMBER | YES | Shares Traded (Monthly total) |
| CSHOM | NUMBER | YES | Shares Outstanding |
| AJEXM | NUMBER | YES | Cumulative Adjustment Factor |
| MKVALTM | NUMBER | YES | Market Value (Total, monthly) |

---

### SEC_DIVID
**Row Count:** ~2,307,546  
**Description:** Security Dividends. Individual dividend payment records including declaration, ex-date, record, and payment dates.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| IID | TEXT | NO | Issue ID |
| DATADATE | TIMESTAMP_NTZ | NO | Ex-dividend date |
| DIVD | NUMBER | YES | Dividend per share amount |
| DIVSPM | NUMBER | YES | Special dividend marker |

---

### SEC_SPLIT
**Row Count:** ~165,636  
**Description:** Security Stock Splits. Records of stock split events with split ratios.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| IID | TEXT | NO | Issue ID |
| DATADATE | TIMESTAMP_NTZ | NO | Split date |
| SPLIT | NUMBER | YES | Split ratio factor |

---

### SEC_DTRT
**Description:** Security Daily Total Returns. Daily total return calculations including dividends.

### SEC_MTHTRT
**Description:** Security Monthly Total Returns. Monthly total return series.

### SEC_MTHSPT
**Description:** Security Monthly Spot prices and returns (alternative currency).

### SEC_EPS
**Description:** Security-level Earnings Per Share data.

### SEC_SHORTINT
**Row Count:** ~5,223,893  
**Description:** Short Interest data. Bi-monthly short interest positions reported for securities.

### SEC_HISTORY
**Description:** Security History. Historical changes to security attributes (exchange, ticker, CUSIP changes).

### SEC_IDCURRENT
**Description:** Security Current Identifiers. Latest identifier mappings for active securities.

### SEC_IDHIST
**Description:** Security Identifier History. Full history of all identifier changes.

### SEC_SPIND
**Description:** Security S&P Index membership. Which S&P indices a security belongs to.

### SEC_ADJFACT
**Description:** Security Adjustment Factors. Cumulative adjustment factors for splits/dividends.

### SEC_AFND / SEC_IFND
**Description:** Security-level Annual/Interim Fundamentals. Per-share financial data at security level.

### SEC_GMTH / SEC_GMTHPRC / SEC_GMTHDIV
**Description:** Security Global Monthly data — prices, dividends for international securities.

---

## 3. Index Data

### IDX_INDEX
**Row Count:** ~2,992  
**Description:** Index Master File. Reference data for all S&P and third-party indices tracked in the system.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEYX | TEXT | NO | Global Index Key (unique index identifier) |
| CONM | TEXT | YES | Index Name |
| IDX13KEY | TEXT | YES | 13-character index key |
| IDXCSTFLG | TEXT | YES | Index constituent flag (Y=has constituents) |
| IDXSTAT | TEXT | YES | Index Status (A=Active, I=Inactive) |
| INDEXCAT | TEXT | YES | Index Category |
| INDEXGEO | TEXT | YES | Index Geography |
| INDEXID | TEXT | YES | Index ID |
| INDEXTYPE | TEXT | YES | Index Type (price return, total return, etc.) |
| INDEXVAL | TEXT | YES | Index Valuation methodology |
| SPII | TEXT | YES | S&P Industry Index code |
| SPMI | TEXT | YES | S&P Major Index code |
| TIC | TEXT | YES | Ticker symbol |
| TICI | TEXT | YES | Ticker (international) |

---

### IDX_DAILY
**Row Count:** ~12,907,597  
**Description:** Index Daily Values. Daily closing levels, high, low for all tracked indices.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEYX | TEXT | NO | Global Index Key |
| DATADATE | TIMESTAMP_NTZ | NO | Trading date |
| PRCCD | NUMBER | YES | Index Close value |
| PRCHD | NUMBER | YES | Index High value |
| PRCLD | NUMBER | YES | Index Low value |
| PRCCDDIV | NUMBER | YES | Index Close (total return, with dividends) |
| PRCCDDIVN | NUMBER | YES | Index Close (net total return) |
| DVPSXD | NUMBER | YES | Dividends per share — ex-date |
| NEWNUM | NUMBER | YES | Number of new constituents |
| OLDNUM | NUMBER | YES | Number of removed constituents |

---

### IDX_MTH
**Description:** Index Monthly Values. Month-end index levels and returns.

### IDX_QRT / IDX_QRTDES
**Description:** Index Quarterly values and descriptive statistics.

### IDX_ANN / IDX_ANNDES
**Description:** Index Annual values and descriptive statistics.

### SPIDX_CST
**Row Count:** ~0 (currently empty)  
**Description:** S&P Index Constituents. Historical constituent membership in S&P indices (security-to-index mapping with effective dates).

### IDXCST_HIS
**Description:** Index Constituent History. Historical addition/deletion records for index membership changes.

---

## 4. S&P Industry & Ratings Indices

### SPIND
**Row Count:** ~552  
**Description:** S&P Industry Index reference. Defines the S&P industry-level index hierarchy.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| SPIIID | NUMBER | YES | S&P Industry Index ID |
| SPIMID | NUMBER | YES | S&P Major Index ID |
| SPITIC | TEXT | YES | S&P Industry ticker |

### SPIND_DLY
**Description:** S&P Industry Index — Daily values (high, low, close, number of constituents).

### SPIND_MTH
**Description:** S&P Industry Index — Monthly values.

---

## 5. Exchange Rates & Currency

### EXRT_DLY
**Row Count:** ~2,220,652  
**Description:** Daily Exchange Rates. Daily FX rates for currency pairs against USD and other base currencies.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| TOCURD | TEXT | NO | Target (to) currency code |
| DATADATE | TIMESTAMP_NTZ | NO | Rate date |
| EXRATD | NUMBER | YES | Exchange rate (daily) |
| FROMCURD | TEXT | YES | Source (from) currency code |

### EXRT_MTH
**Description:** Monthly Exchange Rates. Month-end FX rates.

### CURRENCY
**Row Count:** ~222  
**Description:** Currency Reference. ISO currency code lookup table.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| CURCD | TEXT | NO | ISO Currency Code (e.g., USD, GBP) |
| CURNAME | TEXT | YES | Currency name |
| CURTRD | TEXT | YES | Trading currency flag |

---

## 6. Ownership & Insider Trading

### IO_QHOLDERS
**Row Count:** ~946,146  
**Description:** Institutional Ownership — Quarterly Holders. Quarterly snapshot of institutional investors and their holdings.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| IID | TEXT | NO | Issue ID |
| DATADATE | TIMESTAMP_NTZ | NO | Report quarter-end date |
| INSTID | NUMBER | YES | Institution ID |
| *Holding fields* | NUMBER | YES | Shares held, market value, percent of outstanding |

### IO_QAGGREGATE
**Description:** Institutional Ownership — Quarterly Aggregate. Summary ownership statistics per security per quarter.

### IO_QBUYSELL
**Description:** Institutional Ownership — Quarterly Buy/Sell. Net buying/selling activity by institutions.

### IO_QCHANGES
**Description:** Institutional Ownership — Quarterly Changes. Period-over-period changes in institutional holdings.

### IO_QFLOATADJ
**Description:** Institutional Ownership — Float Adjustment. Float-adjusted ownership percentages.

### IT_MBUYSELL
**Description:** Insider Trading — Monthly Buy/Sell. Aggregated insider transactions by month.

### IT_MSUMMARY
**Description:** Insider Trading — Monthly Summary. Monthly summary statistics for insider activity.

### IT_R_RLTN
**Description:** Insider Trading — Relationship codes. Lookup for insider relationship types (officer, director, 10%+ owner).

---

## 7. Business Segments

### SEG_ANN
**Row Count:** ~39,209  
**Description:** Segment Annual Data. Business segment financial reporting (revenue, assets, profit by segment).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| DATADATE | TIMESTAMP_NTZ | NO | Fiscal year-end date |
| STYPE | TEXT | NO | Segment type (BUSSEG, GEOSEG, OPSEG) |
| SID | NUMBER | NO | Segment ID |
| *Financial items* | NUMBER | YES | Segment revenue, operating profit, identifiable assets, capex, depreciation |

### SEG_ANNFUND
**Description:** Segment Annual Fundamentals. Extended segment financial data items.

### SEG_GEO
**Row Count:** Included in SEG_ANN  
**Description:** Geographic Segment data. Revenue and assets by geographic region.

### SEG_PRODUCT
**Description:** Product Segment data. Revenue and financial metrics by product line.

### SEG_CUSTOMER
**Description:** Customer Segment data. Major customer disclosures.

### SEG_NAICS
**Description:** Segment NAICS codes. Industry classification for individual segments.

### SEG_TYPE
**Description:** Segment Type reference. Lookup for segment classification types.

---

## 8. Industry Classification (GICS)

### GIC_COMPANY
**Row Count:** ~101,453  
**Description:** GICS Classification — Company. Current GICS (Global Industry Classification Standard) assignments for companies.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| GVKEY | TEXT | NO | Global Company Key |
| GICCD | TEXT | YES | Full 8-digit GICS code |
| GSECTOR | TEXT | YES | GICS Sector (2-digit) |
| GGROUP | TEXT | YES | GICS Industry Group (4-digit) |
| GIND | TEXT | YES | GICS Industry (6-digit) |
| GSUBIND | TEXT | YES | GICS Sub-Industry (8-digit) |

### GIC_SECURITY
**Description:** GICS Classification — Security level. GICS codes at the individual security level.

### GIC_HISTORY
**Description:** GICS Classification — History. Historical GICS reclassification records.

### GIC_CCOMPANY / GIC_CSECURITY
**Description:** GICS Classification — Canadian company/security specific.

### GICRSTOSPRATING
**Description:** GICS to S&P Rating mapping.

---

## 9. Capital IQ (CIQ) Extended Data

The CIQ tables provide Capital IQ extended data including M&A transactions, estimates, filings, and company intelligence.

### Key CIQ Tables:

| Table | Description |
|-------|-------------|
| CIQCOMPANY | CIQ Company master data |
| CIQSECURITY | CIQ Security identifiers |
| CIQEXCHANGE | CIQ Exchange reference |
| CIQCOUNTRY / CIQCOUNTRYGEO | CIQ Country reference and geography |
| CIQINDUSTRY | CIQ Industry classification |
| CIQSIMPLEINDUSTRY | CIQ Simplified industry codes |
| CIQKEYDEVELOPMENT* | Key company events/developments |
| CIQEVENT* | Corporate events data |
| CIQESTIMATE* | Analyst estimates and consensus |
| CIQTRANSMA* | M&A transaction data (multiple sub-tables for financials, documents, features, conditions) |
| CIQTRANSOFFERING* | Public/private offering data |
| CIQFILING* | SEC and regulatory filing metadata |
| CIQOWNERSHIP* | CIQ ownership data |
| CIQPROFESSIONAL* | CIQ professional/people data |
| CIQRATINGSDEBT* | Debt ratings data |
| CIQFINANCIAL* | CIQ financial statement data |
| CIQFININSTANCE / CIQFINPERIOD | Financial reporting instances and periods |
| CIQMARKETCAP | CIQ Market capitalization data |

---

## 10. Reference / Lookup Tables (R_ prefix)

These are code-value lookup tables used to decode coded fields throughout the database.

| Table | Description |
|-------|-------------|
| R_ACCSTD | Accounting Standards codes |
| R_ACQMETH | Acquisition Method codes |
| R_ACTIONCD | Corporate Action codes |
| R_AUDITORS | Auditor codes and names |
| R_AUOPIC | Auditor Opinion codes |
| R_BALPRES | Balance Sheet Presentation codes |
| R_CF_FORMT | Cash Flow Format codes |
| R_COINDPRE | Company Industry Presentation codes |
| R_COMPSTAT | Company Status codes |
| R_CONSOL | Consolidation Level codes |
| R_COUNTRY | Country codes and names |
| R_CO_STATUS | Company Status types |
| R_CSTCLSCD | Constituent Classification codes |
| R_DATACODE | Data Item codes and descriptions |
| R_DATAFMT | Data Format codes |
| R_DIVTAXMARKER | Dividend Tax Marker codes |
| R_DOCSRCE | Document Source codes |
| R_EXCHGTIER | Exchange Tier codes |
| R_EXRT_TYP | Exchange Rate Type codes |
| R_EX_CODES | Exchange codes and names |
| R_FNDFNTCD | Fundamental/Footnote codes |
| R_FOOTNTS | Footnote descriptions |
| R_FORICD | Foreign Incorporation codes |
| R_GICCD | GICS code descriptions |
| R_HCALENDR | Holiday Calendar codes |
| R_IDXCLSCD | Index Classification codes |
| R_INACTVCD | Inactivation codes |
| R_INCSTATS | Income Status codes |
| R_INDFMT | Industry Format codes |
| R_INDSEC | Industry/Sector codes |
| R_INVVAL | Investment Valuation codes |
| R_ISSUETYP | Issue Type codes |
| R_MAJIDXCL | Major Index Classification codes |
| R_MIC_CODES | Market Identifier Codes (MIC) |
| R_NAICCD | NAICS code descriptions |
| R_NOTETYPE | Note Type codes |
| R_NTSUBTYPE | Note Subtype codes |
| R_OFFCRSO | Officer Source codes |
| R_OGMETHOD | Oil & Gas Method codes |
| R_OPINIONS | Auditor Opinion types |
| R_PRC_STAT | Price Status codes |
| R_QSRCDOC | Quarterly Source Document codes |
| R_SECANNFN | Security Annual Footnote codes |
| R_SECTORS | Sector codes |
| R_SEC_STAT | Security Status codes |
| R_SICCD | SIC code descriptions |
| R_SPIICD | S&P Industry Index codes |
| R_SPMICD | S&P Major Index codes |
| R_STATALRT | Status Alert codes |
| R_STATES | US State codes |
| R_STKO | Stock Ownership type codes |
| R_TITLES | Executive Title codes |
| R_UPDATES | Update type codes |

---

## 11. Footnotes & Annotations

| Table | Description |
|-------|-------------|
| ACO_AMDA | Annual footnotes/metadata annotations |
| ACO_IMDA | Interim footnotes/metadata annotations |
| ACO_INDFNTA | Annual industry-specific footnotes |
| ACO_INDFNTQ | Quarterly industry-specific footnotes |

---

## 12. Data Dictionary (DD_ prefix)

| Table | Description |
|-------|-------------|
| DD_GROUP | Data item group definitions |
| DD_GROUP_XREF | Group cross-reference |
| DD_ITEM | Individual data item definitions (field names, descriptions) |
| DD_PACKAGE | Data package definitions |

---

## 13. Economic Indicators

| Table | Description |
|-------|-------------|
| ECIND_DESC | Economic Indicator descriptions |
| ECIND_MTH | Economic Indicator monthly values |

---

## 14. Market Intelligence Pricing (MI prefix)

| Table | Description |
|-------|-------------|
| MIADJPRICE | Market Intelligence Adjusted Prices |
| MIBESTPRICEDATE | Best available price date selection |
| MIDATAITEM | MI Data Item reference |
| MIPRICE | MI Raw Prices |

---

## 15. Filings Data

| Table | Description |
|-------|-------------|
| FILINGDATA | Regulatory filing metadata |
| FILINGINSTITUTIONREL | Filing-to-institution relationships |
| FILINGINSTITUTIONRELTYPE | Filing institution relationship types |
| FILINGLANGUAGE | Filing language codes |
| FILINGREF | Filing cross-reference |
| FILINGSDATAESG | ESG-related filing data |
| FILINGSDATANONENGLISH | Non-English filing data |
| FILINGSDATANONSEC | Non-SEC filing data |
| FILINGSOURCE | Filing source types |
| FILINGTYPE | Filing type codes |

---

## 16. People / SME Data

| Table | Description |
|-------|-------------|
| SMECOMPANY | SME Company data |
| SMECOMPANYCROSSREF | Company cross-reference for people data |
| SMECOMPANYINFORMATION | Extended company information |
| SMEFUNCTIONBASIC | Job function classifications |
| SMEPERSONBASIC | Person/executive basic information |
| SMEPROFESSIONALBASIC | Professional background data |
| SMEPROTOFUNCTIONBASIC | Proto-function reference |
| SMEASREPORTEDINDUSTRY | Industry as reported in filings |

---

## 17. Toyo Keizai (Japanese Data)

| Table | Description |
|-------|-------------|
| TOYOCOMPANYDATA | Japanese company data items |
| TOYOINDUSTRYCLASSIFICATION | Japanese industry codes (English/Japanese) |
| TOYOSHAREHOLDERDATA | Japanese shareholder ownership data |

---

## 18. Company Relationships

| Table | Description |
|-------|-------------|
| COMPANY | Company master (see above) |
| COMPANYRELS | Company-to-company relationships (parent, subsidiary, affiliate) |
| COMPANYRELTYPE | Relationship type codes |
| COMPUSTATMARKETCAP | Compustat-calculated market capitalization |

---

## 19. Other Notable Tables

| Table | Description |
|-------|-------------|
| SOURCETYPE | Data source type reference |
| STAKETYPE | Stakeholder type reference |
| DATESOURCE | Date source/methodology reference |
| REASONFORCHANGE | Reason-for-change codes |
| PROCOMPANYCOMPDATAITEM | Executive compensation data items |
| PROCOMPANYCOMPENSATION | Executive compensation records |
| PROCOMPANYCOMPENSATIONDATA | Compensation data values |
| CO_GMTHIQR | Global monthly inter-quartile range |
| CO_GSUPPL | Global supplemental data |

---

## Key Relationships

```
COMPANY (GVKEY) ─────────┬──── CO_AFND1/CO_AFND2 (Annual Financials)
                          ├──── CO_IFNDQ/CO_IFNDSA/CO_IFNDYTD (Quarterly)
                          ├──── CO_MTHLY (Monthly Market Data)
                          ├──── CO_INDUSTRY (Industry History)
                          ├──── GIC_COMPANY (GICS Classification)
                          ├──── SEG_ANN (Business Segments)
                          └──── COMPANYRELS (Corporate Hierarchy)

SECURITY (GVKEY + IID) ──┬──── SEC_DPRC (Daily Prices — 475M rows)
                          ├──── SEC_MTHPRC (Monthly Prices)
                          ├──── SEC_DIVID (Dividends)
                          ├──── SEC_SPLIT (Stock Splits)
                          ├──── SEC_SHORTINT (Short Interest)
                          ├──── IO_QHOLDERS (Institutional Ownership)
                          └──── SPIDX_CST (Index Constituents)

IDX_INDEX (GVKEYX) ──────┬──── IDX_DAILY (Daily Index Values — 12.9M rows)
                          ├──── IDX_MTH (Monthly Index Values)
                          ├──── IDX_ANN (Annual Index Values)
                          └──── SPIDX_CST (Constituents)

EXRT_DLY (TOCURD + DATADATE) ── Daily Exchange Rates
CURRENCY (CURCD) ─────────────── Currency Reference
```

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total Views | 608 (+ 606 CDC mirrors) |
| Companies | ~138,746 |
| Securities | ~210,572 |
| Daily Price Records | ~475.7 million |
| Monthly Price Records | ~7.7 million |
| Quarterly Fundamentals | ~5.9 million |
| Annual Fundamentals | ~1.8 million |
| Index Definitions | ~2,992 |
| Daily Index Values | ~12.9 million |
| Exchange Rate Records | ~2.2 million |
| Currencies | 222 |

---

## Notes for Synthetic Data Recreation

1. **Primary Keys:** Most tables use `GVKEY` (company) or `GVKEY + IID` (security) as the entity key, with `DATADATE` as the temporal key.
2. **PACVERTOFEEDPOP:** This column appears in every table — it's an internal S&P version/population tracking field (can be populated with a constant like 1).
3. **GVKEYX:** Used exclusively for index-level entities (IDX_ tables).
4. **XPRESSFEED_CDC schema:** Contains CDC (Change Data Capture) versions of each XPRESSFEED table with a `CDC_` prefix. Same structure with additional CDC metadata columns for incremental processing.
5. **Industry Format (INDFMT):** Critical for financial tables — determines which template was used (INDL=Industrial, FS=Financial Services, UT=Utility).
6. **Data Format (DATAFMT):** STD=Standardized (use this for most analysis), SUMM=Summary.
7. **Consolidation (CONSOL):** C=Consolidated (typical), I=Individual entity.
8. **Population Source (POPSRC):** D=Domestic/North America, I=International.
9. **Scale:** Daily pricing (SEC_DPRC) is by far the largest table at ~476M rows. Plan synthetic data sizing accordingly.
10. **CIQ Tables:** The Capital IQ (CIQ) tables form their own entity model with COMPANYID as the key rather than GVKEY. Cross-reference tables link CIQ entities to Compustat GVKEYs.
