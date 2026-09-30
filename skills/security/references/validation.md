# Validation Gates

A finding ships only if it passes every gate. This is how you keep false positives out of the report. Run each candidate through the gates before writing it into `findings.md`.

## The Gates

1. **Reproduced.** You triggered it at least twice, deliberately. A one-off or a guess does not pass.
2. **Evidence saved.** The request and response, or the code path and a screenshot, are in `evidence/`. Enough that someone else could repeat it from your notes alone.
3. **Real impact.** You can state what an attacker gains: data they should not see, an action they should not perform, access they should not have. "Reflected but not executed" or "error message" without impact is a note, not a finding.
4. **In scope.** The affected target is inside `scope.md`. If the proof relied on touching something out of scope, the finding stops at the boundary.
5. **Not by design.** You checked it is not intended behavior for the role or the feature. An admin doing admin things is not a privilege escalation.
6. **Root cause understood.** You can name why it happens (missing check, unescaped sink, wrong default) so the fix is specific, not "add validation."

## Severity

Rate each confirmed finding with CVSS or a simple High / Medium / Low based on impact and how easy it is to exploit:

- **Critical:** remote code execution, full account or data compromise, auth bypass to admin
- **High:** access to other users' data or actions, injection with real impact, secrets exposed
- **Medium:** issues that need conditions or chaining, weaker information disclosure, missing hardening with a clear path to harm
- **Low:** defense-in-depth gaps, verbose errors, missing headers with limited impact
- **Info:** worth noting, no direct impact

Record the CVSS vector when you use one, so the score is checkable.

## Downgrade or Drop

- Cannot reproduce on a second try: drop it, or move it to `notes.md` as a lead
- No stated impact: downgrade to Info or drop
- Proof needed an out-of-scope step: drop the out-of-scope part, keep only what is in scope
- Duplicate of another finding: merge them

Better to ship five solid findings than twenty shaky ones.
