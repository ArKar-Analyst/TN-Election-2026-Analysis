# The Vijay Wave — Decoding the 2026 Tamil Nadu Assembly Election
**Codebasics Resume Project Challenge #26**
**Analyst:** Arkadeep Kar | **Tools:** SQL + Canva | **Data:** ECI 2021 & 2026

---

## Project Summary
An evidence-based investigation into how TVK won 108 seats
in its debut election — analysing geographic shifts, 
constituency-level seat flips, and the origins of TVK's 
34.9% vote share across all 6 regions of Tamil Nadu.

## Three Questions. One Verdict.
- **Q1 — Geography:** TVK swept all 6 regions — but unevenly
- **Q2 — Flips:** 163 of 234 seats changed hands (69.7%)
- **Q3 — Vote Share:** TVK absorbed ~13.5pp from DMK 
  and ~12.1pp from AIADMK equally

## Key Findings
| Metric | Value |
|---|---|
| Total Constituencies | 234 |
| TVK Seats Won | 108 |
| Seats Flipped | 163 (69.7%) |
| TVK Vote Share | 34.9% |
| Majority Mark | 118 |

## Data Sources
- Election Commission of India (ECI) — 2026 Tamil Nadu 
  Assembly Election results
- ECI — 2021 Tamil Nadu Assembly Election results 
  (benchmark comparison)

## Reproduction Steps
1. Clone this repository
2. Load `data/tn_election_2026_raw.csv` into any 
   SQL environment (MySQL / PostgreSQL / SQLite)
3. Run queries in order from `sql/tn_election_analysis.sql`
4. All figures in the deck are reproducible from 
   these queries end-to-end

## SQL Queries Used
- `COUNT(*) GROUP BY party` — seat tallies
- `GROUP BY region, party` with `CASE WHEN` pivot 
  — regional breakdown
- `JOIN winners_2021 & winners_2026 ON ac_number` 
  — flip detection
- `SUM(votes)/total` with `FULL OUTER JOIN` 
  — vote share decomposition

## Deliverables
- 📊 [Stakeholder Deck (PDF)](presentation/TN_Election_2026_AtliQ.pdf)
- 🎥 [Video Walkthrough](#) ← paste your YouTube/Drive link here
- 🔗 [LinkedIn Post](#) ← paste after publishing

## Data Limitations
- Vote share decomposition uses aggregate 
  state-level data; booth-level attribution 
  is not available from ECI public records
- "New voter pool" (~4.2%) is an estimated 
  residual, not directly measured
- Regional boundaries follow ECI's 6-zone 
  classification; results may vary 
  under alternative zonation

## Non-Partisanship Statement
All analysis is independent and non-partisan. 
No causal claims are made. All chart titles 
and findings are written to read neutrally 
across supporters of any party.

---
*Project: Codebasics Resume Project Challenge #26*
*AtliQ Media Political Desk*
