# ORBIT Demo Walkthrough

A step-by-step guide to demonstrating ORBIT Investment Intelligence and the Snowflake capabilities it showcases.

## Demo Narrative

ORBIT is a proof-of-concept investment intelligence platform built entirely on Snowflake using **real market data**. It demonstrates how a financial services firm can combine live market data, AI-powered agents, and interactive analytics — all within one platform, zero data movement, zero external infrastructure. Every data point is real and sourced from Snowflake's Public Data (Paid) marketplace listing.

---

## Snowflake Capabilities Demonstrated

### 1. Snowflake Public Data (Paid) — Zero-Copy Data Sharing

**What it shows:** Instant access to institutional-grade financial data without ETL, APIs, or data engineering.

**Demo talking points:**
- 14,000+ securities with daily price data from Cybersyn
- SEC XBRL filings parsed into structured financials
- Treasury yields, economic indicators, FX rates — all live
- Earnings call transcripts with full text
- No ingestion pipelines, no storage duplication — data stays in the provider's account

**Where to show it:** Run `scripts/02_data.sql` and point out the `SNOWFLAKE_PUBLIC_DATA_PAID` references — all queries run directly against the shared data.

---

### 2. Cortex Agents — Conversational AI Over Structured + Unstructured Data

**What it shows:** Natural language access to complex financial data through purpose-built AI agents.

**Demo talking points:**
- Three specialised agents: Research, Portfolio, Market Intelligence
- Each agent combines **Cortex Analyst** (text-to-SQL) with **Cortex Search** (RAG over documents)
- Agents reason across both structured data (financials, prices) and unstructured data (SEC filings, transcripts)
- Registered with Snowflake Intelligence (CoWork) for org-wide access
- Budget controls (token + time limits) for cost governance

**Where to show it:** Open CoWork via the Streamlit AI Agents page → ask "Compare Apple and Microsoft gross margins over 8 quarters"

---

### 3. Cortex Search Services — Enterprise RAG

**What it shows:** Full-text semantic search over SEC filings and earnings transcripts without managing vector databases.

**Demo talking points:**
- Two search services: SEC filings (10-K, 10-Q, 8-K) and earnings transcripts
- Hybrid search: text indexes for keyword matching + vector indexes (Arctic Embed) for semantic similarity
- Filterable attributes (ticker, sector, filing type, fiscal year)
- Auto-refreshing with `TARGET_LAG = '1 day'`
- Used by the Research Agent for qualitative analysis

**Where to show it:** Ask the Research Agent "What risks did Apple mention in their latest 10-K?"

---

### 4. Semantic Views — Governed Text-to-SQL

**What it shows:** Business-friendly data access through natural language, with governance and verified queries.

**Demo talking points:**
- Three semantic views map business concepts to physical tables
- Metrics, dimensions, time dimensions, and relationships defined in YAML
- Verified queries provide pre-tested answers to common questions
- Used by Cortex Agents as their SQL generation backbone

**Where to show it:** `semantic_views/` folder — show how business terms like "revenue" map to `FACT_SEC_FINANCIALS.REVENUE`

---

### 5. Cortex AI Functions — Built-in NLP

**What it shows:** Production-ready NLP without model deployment.

**Demo talking points:**
- `SNOWFLAKE.CORTEX.SENTIMENT()` scores earnings call transcripts
- No model training, no GPU provisioning, no inference endpoints
- SQL-callable — works in views, dashboards, and agents
- Used in the Research Hub "Sentiment" tab

**Where to show it:** Research Hub → select any company → Sentiment tab

---

### 6. Streamlit in Snowflake — Interactive Applications

**What it shows:** Full-featured web applications running natively inside Snowflake.

**Demo talking points:**
- Multi-page navigation with branded sidebar
- Real-time queries against live data (no pre-aggregation)
- Interactive charts: Altair for ordered categories, Streamlit native for time series
- Column configs with progress bars, currency formatting, percentage formatting
- Deep links to Snowflake CoWork for agent conversations
- Runs on Snowflake compute — no external hosting

**Where to show it:** Walk through each page of the portal

---

### 7. Dynamic Tables — Declarative Data Pipelines

**What it shows:** Auto-refreshing derived tables without orchestration.

**Demo talking points:**
- Benchmark returns and sector returns computed as Dynamic Tables
- `TARGET_LAG` controls freshness (daily)
- No DAG management, no scheduler, no failure handling code
- Snowflake handles dependency resolution and incremental refresh

**Where to show it:** `scripts/06_refresh.sql` — Dynamic Tables + scheduled Task

---

### 8. Snowflake Intelligence (CoWork) — Org-Wide AI Access

**What it shows:** Democratised data access through conversational AI.

**Demo talking points:**
- Agents registered with `ALTER SNOWFLAKE INTELLIGENCE ... ADD AGENT`
- Any user with appropriate role can chat with agents
- No code, no SQL knowledge required for end users
- Sample questions guide users to high-value queries

**Where to show it:** Open `https://ai.snowflake.com` → select an ORBIT agent

---

## Demo Flow (Suggested Order)

1. **Home page** — Show the executive dashboard, explain KPIs and preview charts
2. **Market Intelligence** — Treasury yield curve, FX picker, economic indicators
3. **Research Hub** — Search for AAPL, walk through Stock Price → Earnings (Quarterly/Annual) → Margins → Sentiment
4. **Portfolio** — Select a portfolio, show holdings with weights, sector allocation
5. **AI Agents** — Click through to CoWork, ask a cross-cutting question
6. **Behind the scenes** — Show `scripts/` folder to explain how everything is built from SQL

---

## Key Data Points for Demo

| Metric | Value |
|--------|-------|
| Companies covered | 3,500+ (NYSE/NASDAQ) |
| Price history | 3 years daily |
| SEC filings analysed | Full text of 10-K, 10-Q, 8-K |
| Earnings transcripts | 2 years of calls |
| Model portfolios | 11 thematic strategies |
| Economic indicators | GDP, CPI, unemployment, rates |
| Currencies | 130+ FX pairs vs USD |
| Treasury maturities | 14 points (1M to 30Y) |

---

## Common Demo Questions & Expected Results

| Question (for agents) | Expected behaviour |
|---|---|
| "What is Apple's quarterly revenue trend?" | Line chart + table from FACT_SEC_FINANCIALS |
| "Show the US Treasury yield curve" | Bar chart ordered by maturity |
| "Top 10 holdings in ORBIT Technology" | Table from FACT_POSITION_DAILY |
| "Compare GOOGL and META gross margins" | Side-by-side quarterly comparison |
| "How has GBP/USD moved recently?" | Time series from FACT_FX_RATES |
| "Who are MSFT's largest institutional holders?" | Table from FACT_INSTITUTIONAL_HOLDINGS |
