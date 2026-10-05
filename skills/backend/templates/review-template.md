# Backend Review: {{project}}

**Date:** {{date}}
**Reviewer:** agent-skills /backend v0.6.0
**Scope:** {{paths_and_services_reviewed}}

---

## Summary

{{three_or_four_plain_sentences: what the service does, the overall verdict, the single most serious issue, and the first thing to fix}}

**Score: {{score}} / 100 ({{verdict}})**

| | Count |
|--------|-------|
| Critical | {{n}} |
| High | {{n}} |
| Medium | {{n}} |
| Low | {{n}} |
| Info | {{n}} |

---

## Scorecard

| Area | Rules | Weight | Grade (0 to 4) | Points | Note |
|------|-------|--------|----------------|--------|------|
| Authentication | B1 | 8 | {{g}} | {{p}} | {{one_line}} |
| Authorization | B2, B17 | 12 | {{g}} | {{p}} | {{one_line}} |
| Input and API contract | B3 | 8 | {{g}} | {{p}} | {{one_line}} |
| Data access and queries | B4, B5 | 12 | {{g}} | {{p}} | {{one_line}} |
| Schema, indexes and migrations | B6 | 8 | {{g}} | {{p}} | {{one_line}} |
| Concurrency and transactions | B7 | 8 | {{g}} | {{p}} | {{one_line}} |
| Resilience and limits | B8 | 8 | {{g}} | {{p}} | {{one_line}} |
| Caching and performance | B12 | 6 | {{g}} | {{p}} | {{one_line}} |
| Logging | B9 | 8 | {{g}} | {{p}} | {{one_line}} |
| Observability | B10 | 6 | {{g}} | {{p}} | {{one_line}} |
| Error handling | B11 | 6 | {{g}} | {{p}} | {{one_line}} |
| Config and operations | B13, B14, B16 | 5 | {{g}} | {{p}} | {{one_line}} |
| Testing | B15 | 5 | {{g}} | {{p}} | {{one_line}} |

{{note_any_area_not_assessed_and_how_the_score_was_scaled}}

---

## System Map

- **Stack:** {{stack}}
- **Entry points:** {{routes_jobs_consumers}}
- **Data stores:** {{databases_caches_queues}}
- **Dependencies:** {{outbound_services}}
- **Hot paths reviewed:** {{endpoints}}

---

## Findings

{{one_section_per_finding_most_severe_first, using the finding format from review.md}}

---

## Measurements

{{query_counts, explain_plans, load_numbers, or "No runtime measurements. Findings are from code reading."}}

---

## Fix Plan

| Priority | Finding | Severity | Effort | Fix |
|----------|---------|----------|--------|-----|
| P0 | {{finding}} | {{sev}} | {{effort}} | {{fix}} |

P0 is high impact and low effort. Do these first.

---

## Strengths

{{what_the_codebase_already_does_well_and_should_keep}}

---

## Appendix

- **Scan:** {{leads_total}} leads, {{confirmed}} confirmed. Raw output in `scan.txt`
- **Not assessed:** {{gaps}}
- **Evidence:** see the `evidence/` folder
