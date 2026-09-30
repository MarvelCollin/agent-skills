# Reporting

Turn confirmed findings into a report a developer can act on. Only findings that passed every gate in [validation.md](validation.md) go in.

Write without semicolons or em dashes (the plugin copy rule). Short sentences, plain words.

## Structure

Use [../templates/report-template.md](../templates/report-template.md). It has:

- **Summary:** what was tested, the scope, the window, and the headline in three or four sentences a non-security manager understands. State the worst issue and the overall posture.
- **Scope and method:** targets, what was and was not tested, the standards used (OWASP WSTG, ASVS, CWE).
- **Findings:** one section each, most severe first.
- **Remediation plan:** the fixes ranked by risk over effort.
- **Appendix:** tooling, accounts used, and anything out of scope that was noticed but not tested.

## Finding Format

Each finding:

```markdown
### [SEV] <short title>

- **Severity:** Critical / High / Medium / Low / Info (+ CVSS vector if used)
- **Category:** <OWASP WSTG id or Top 10 category>, CWE-<id>
- **Location:** <endpoint, parameter, or file:line>
- **Summary:** what the issue is, in one or two sentences.

**Impact.** What an attacker gains, and who is affected.

**Evidence.** The steps to reproduce, with the request and response or code path. Point to files in `evidence/`. Redact real secrets.

**Root cause.** Why it happens.

**Fix.** The specific change to make. Code-level where possible. Add a defense-in-depth note if useful.

**References.** OWASP, CWE, or vendor docs.
```

## Ranking Remediation

Put fixes in a table ordered by impact against effort, so the team knows what to do first:

| Priority | Finding | Severity | Effort | Fix |
|----------|---------|----------|--------|-----|
| P0 | ... | Critical | Low | ... |

P0 is high impact and low effort. Do it first. Keep it honest about effort.

## Tone

- Factual, not alarmist. State impact plainly and let severity carry the weight.
- Blame the code path, not the developer.
- Every finding ends with a fix. A report with no fixes is not done.
- Redact real credentials and personal data from evidence before the report leaves your hands.
