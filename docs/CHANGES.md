# ORBIT — Change Log & Roadmap

> A living document to coordinate changes across the team.
> Check before changing. Update after deploying.

| Who           | Role                                       |
| ------------- | ------------------------------------------ |
| Gemma         | Prototyping (CoCo-assisted)                |
| Mark          | Barclays deployment & customisation        |
| Sahana / Anup | Review & approval                          |

---

## What's Deployed Today

```
DATABASE:    ORBIT_DEMO
SCHEMAS:     RAW · MARKET_DATA · CURATED · AI
WAREHOUSE:   ORBIT_DEMO_WH (compute) · ORBIT_DEMO_SEARCH_WH (indexing)
ROLE:        ORBIT_DEMO_ROLE
REFRESH:     Daily @ 06:00 UTC (task) + 2 dynamic tables (1-day lag)
```

### Agents

All three agents use `claude-opus-4-7` for orchestration.

```
┌─────────────────────────────────────────────────────────────────────┐
│  MARKET INTELLIGENCE                                                │
│  Yields · FX · Economic indicators · Policy rates · Stock prices    │
│  Tools: market_analyst (semantic view) + chart                      │
├─────────────────────────────────────────────────────────────────────┤
│  PORTFOLIO                                                          │
│  Holdings · Weights · Allocation · 11 model portfolios              │
│  Tools: portfolio_analyst (semantic view) + chart                   │
├─────────────────────────────────────────────────────────────────────┤
│  RESEARCH                                                           │
│  SEC financials · Insider trades · 13F holdings                     │
│  + full-text search: 184K SEC filings · 76K earnings transcripts    │
│  Tools: research_analyst + sec_filings_search + transcripts_search  │
└─────────────────────────────────────────────────────────────────────┘
```

### Semantic Views

| View                     | Tables                                                                          |
| ------------------------ | ------------------------------------------------------------------------------- |
| `ORBIT_MARKET_VIEW`      | ECONOMIC_INDICATORS · FX_RATES · POLICY_RATES · STOCK_PRICES · TREASURY_YIELDS |
| `ORBIT_PORTFOLIO_VIEW`   | POSITIONS · PORTFOLIOS · ISSUERS                                                |
| `ORBIT_RESEARCH_VIEW`    | FINANCIALS · INSIDER_TRANSACTIONS · INSTITUTIONAL_HOLDINGS · ISSUERS            |

### Streamlit Portal

Home · Research Hub · Market Intelligence · Portfolio · AI Agents

### Data loaded but NOT yet exposed

| Table                        | Rows   | What it is                              |
| ---------------------------- | ------ | --------------------------------------- |
| `FACT_SEC_SEGMENTS`          | 700K   | Product/geo revenue breakdowns          |
| `FACT_COUNTRY_EMISSIONS`     | 515K   | CO2/CH4/N2O by country & sector         |
| `FACT_BENCHMARK_RETURNS`     | 7.5K   | Dynamic table running — not in any view |
| `FACT_SECTOR_RETURNS`        | 8.2K   | Dynamic table running — not in any view |

---

## The Roadmap

> One phase at a time. Fully tested before moving on. No risk to what works.

### Phase 1 — Quick Wins

Expose data that's already loaded. No new pipelines.

| ID     | What                        | Enables                                           | Why                              |
| ------ | --------------------------- | ------------------------------------------------- | -------------------------------- |
| **1A** | Revenue Segments            | "What % of Apple's revenue is Services?"          | Day 1 pitchbook question         |
| **1B** | Benchmark & Sector Returns  | "Did our Tech fund beat Nasdaq this quarter?"     | Core portfolio review            |
| **1C** | Country Emissions           | "Which G20 countries reduced emissions?"          | ESG / green bond conversations   |

### Phase 2 — Bloomberg Second Measure (Consumer Transactions) ⭐ PRIORITY

> **Sahana priority.** This is the differentiator — alternative data layered on top of traditional fundamentals.

Bloomberg Second Measure provides anonymised credit/debit card transaction data at the merchant level. It lets analysts see real consumer spending *before* earnings are reported — the "nowcasting" edge for equity research and PE due diligence.

**What it enables:**

- "How did Starbucks same-store sales trend last month vs last year?"
- "Which retailer is gaining wallet share from Target?"
- "Show me consumer spending at Peloton — is churn accelerating?"
- Period-over-period comparisons (MoM, QoQ, YoY) overlaid against reported revenue

**The plan:**

| Step | Who    | Action                                                                           |
| ---- | ------ | -------------------------------------------------------------------------------- |
| 1    | Mark   | Get access to Second Measure schema, table structures, and sample data           |
| 2    | Mark   | Share structure + examples with Gemma (column names, granularity, time range)     |
| 3    | Gemma  | Synthesise representative data matching the schema (for demo without licence)     |
| 4    | Gemma  | Build semantic view with time-period comparison metrics (MoM, QoQ, YoY)          |
| 5    | Gemma  | Build Streamlit page — merchant spend trends, peer comparison, seasonal patterns |
| 6    | Gemma  | Add as tool on Research Agent (or dedicated Consumer Intelligence agent)          |
| 7    | Both   | When live data available, swap synthetic for real — zero code changes needed      |

**Key design point:** We build the semantic view and Streamlit against a synthetic dataset that mirrors the real schema exactly. When Mark gets live access, it's a table swap — not a rebuild.

**Marketplace note:** Bloomberg Second Measure is not on the Snowflake Marketplace (it's licensed directly through Bloomberg). Closest public alternatives if needed for reference:

- [Consumer Edge](https://app.snowflake.com/marketplace/listing/GZTSZPM137) — credit/debit transaction data, merchant-attributable
- [Earnest Analytics](https://app.snowflake.com/marketplace/listing/GZSOZRN77) — credit card spend at public companies

---

### Phase 3 — New Data Pipelines (Public Data)

Ingest high-value datasets from Public Data (Paid) that we're not using yet.

| ID     | Area                   | Data                                                               | Why                                  |
| ------ | ---------------------- | ------------------------------------------------------------------ | ------------------------------------ |
| **3A** | Fixed Income           | Full Treasury curve · Fed credit · Credit spreads                  | Can't run DCM without rates          |
| **3B** | Global Macro           | IMF commodities · World Bank ESG · BIS banking                     | Cross-border deals & EM risk         |
| **3C** | Company Intelligence   | NPORT · Proxy/comp · Corporate structure · WARN · Patents          | Deep due diligence layer             |
| **3D** | Banking / FIG          | FDIC call reports · Bank M&A events                                | The client is a bank                 |
| **3E** | Real Estate            | House prices · Mortgage performance · Weekly rates                 | Structured products & REIT coverage  |

### Phase 4 — New Agents

| ID     | Agent                  | Purpose                                                |
| ------ | ---------------------- | ------------------------------------------------------ |
| **4A** | Existing agents        | Update with all Phase 1–3 data                         |
| **4B** | `ORBIT_CREDIT_AGENT`   | Bonds · Banks · Mortgages — dedicated DCM persona      |
| **4C** | `ORBIT_ESG_AGENT`      | Emissions · Sovereign sustainability — own vertical    |
| **4D** | `ORBIT_IB_COPILOT`     | Master orchestrator — single front door for CoWork     |

### Phase 5 — Streamlit Expansion

New pages, reorganised by IB workflow:

Segments · Performance · ESG · Credit · Banking · Real Estate · Governance · Consumer Spend · Layoffs

### Phase 6 — Refresh Automation

| Cadence     | Data                                                        |
| ----------- | ----------------------------------------------------------- |
| Daily       | Stock prices · Treasury yields · FX · Mortgage rates        |
| Weekly      | Fed credit · WARN layoffs · Consumer transactions           |
| Monthly     | IMF · NPORT · Corporate structure · Patents                 |
| Quarterly   | Bank financials · World Bank · Proxy data · House prices    |

---

## Change Log

### v0.1.0 — 28 Jun 2026

> Gemma · Status: **Deployed**

Initial build. 3 agents, 3 semantic views, 2 search services, 5 Streamlit pages,
daily refresh task, 2 dynamic tables. Loaded 6K issuers, 3.9M prices, 20M holdings.

**Known gaps:** segments/emissions loaded but dark · some NULL issuer names in insider data

---

### Next: Phase 1A — Revenue Segments

> Status: **Proposed**

Four changes:

1. **Semantic view** — `ORBIT_RESEARCH_VIEW.yaml` → add SEGMENTS table + join to ISSUERS
2. **Agent** — `ORBIT_RESEARCH_AGENT` → segment routing + sample question
3. **Streamlit** — new `revenue_segments.py` page
4. **Navigation** — add "Segments" under Research group

Rollback: redeploy original YAML · remove page · revert agent. Zero data risk.

---

## Notes for Contributors


---

## Open Questions

