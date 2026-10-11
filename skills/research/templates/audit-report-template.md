# Research Audit: {{document_title}}

**Date:** {{date}}
**Document:** {{paths_read}} ({{document_type}}, {{field}})
**Auditor:** agent-skills /research audit
**Scripts:** numbers-extract ({{numbers_found}} numbers, {{flags}} flags), cite-check ({{missing_keys}} missing keys)

---

## Summary

{{three_or_four_plain_sentences: what the document claims, whether the evidence carries it, the most serious problem, and the first thing to fix}}

| Severity | Count |
|----------|-------|
| Blocker | {{n}} |
| Major | {{n}} |
| Minor | {{n}} |

| Type | Count |
|------|-------|
| Missing | {{n}} |
| Data | {{n}} |
| Logic | {{n}} |
| Consistency | {{n}} |
| Structure | {{n}} |

**Fix first:**

1. {{finding_id_and_one_line}}
2. {{finding_id_and_one_line}}
3. {{finding_id_and_one_line}}

---

## Main Claim and Map

**Main claim:** {{one_sentence}}

**Stated contributions or findings:**

1. {{contribution}} ({{location}})

**Design:** {{experiment_survey_case_study_model_proof_archival}}

---

## Claim Ledger

| Claim (location, quote) | Evidence (location) | Status | Note |
|-------------------------|---------------------|--------|------|
| {{abstract_line_n}}: "{{quote}}" | {{table_or_section}} | {{supported_partly_unsupported_contradicted}} | {{note}} |

---

## Findings

Ordered by severity, then by position in the document.

### A1. [{{Blocker_Major_Minor}}] [{{Missing_Data_Logic_Consistency_Structure}}] {{short_title}}

**Location:** {{file_and_line_or_page_section_table}}

**Quote:** "{{exact_text}}" {{and_second_quote_for_inconsistencies}}

**What is wrong:** {{plain_statement}}

**Why it matters:** {{effect_on_trust_conclusion_or_reproducibility}}

**Fix:** {{concrete_change}}

---

## Term and Notation Table

| Concept | Names or symbols used | Locations | Use |
|---------|-----------------------|-----------|-----|
| {{concept}} | {{variants}} | {{locations}} | {{chosen_form}} |

---

## Reverse Outline

**Main claim:** {{one_sentence}}

| Section, paragraph | Topic | Serves the claim |
|--------------------|-------|------------------|
| {{section_paragraph}} | {{topic}} | {{yes_or_finding_id}} |

---

## Not Checked

{{checks_that_could_not_be_done_and_why, for example figures that were not available, supplement not provided}}

---

## Method

Passes run in order: map, claim ledger, numbers, missing pieces, logic, consistency, structure. Every finding passed five gates (located, real, material, fixable, not invented). Script output is saved in this folder. Script lines are leads, and only confirmed leads appear above.
