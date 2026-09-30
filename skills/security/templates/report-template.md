# Security Review: {{target}}

**Date:** {{date}}
**Tester:** agent-skills /security v0.4.0
**Authorization:** {{authorization_basis}}

---

## Summary

{{three_or_four_plain_sentences: what was tested, the overall security posture, and the single most serious issue}}

| | Count |
|--------|-------|
| Critical | {{n}} |
| High | {{n}} |
| Medium | {{n}} |
| Low | {{n}} |
| Info | {{n}} |

---

## Scope and Method

- **In scope:** {{targets}}
- **Out of scope:** {{excluded}}
- **Test window:** {{window}}
- **Accounts and data:** {{test_accounts}}
- **Standards:** OWASP WSTG, OWASP Top 10, OWASP API Top 10, CWE
- **Not tested:** {{gaps}}

---

## Findings

{{one_section_per_finding_most_severe_first, using the finding format from reporting.md}}

---

## Remediation Plan

| Priority | Finding | Severity | Effort | Fix |
|----------|---------|----------|--------|-----|
| P0 | {{finding}} | {{sev}} | {{effort}} | {{fix}} |

P0 is high impact and low effort. Do these first.

---

## Appendix

- **Tools used:** {{tools}}
- **Noticed but not tested (out of scope):** {{observations}}
- **Evidence:** see the `evidence/` folder. Real secrets and personal data are redacted.
