# Business Logic

Flaws in how the app's rules work, not in a single technical sink. Scanners miss these. You find them by understanding what the feature is supposed to do and then not doing that.

## What to Check

- **Skipped steps:** reaching a later step (payment confirmed, order placed) without completing an earlier one.
- **Replay:** repeating a request that should only work once (a coupon, a one-time action, a transfer).
- **Amount and quantity tampering:** price, quantity, or total trusted from the client. Negative quantities. Currency or discount abuse.
- **Race conditions:** two requests at once that both pass a check that should let only one through (double-spend, using a balance twice).
- **Workflow abuse:** using a feature in an order or way the designers did not intend, to gain money, access, or data.

## How to Test Safely

- Walk the intended flow first, then try to break the assumptions: change a value the server should own, repeat a one-time action, skip a step by calling the later endpoint directly.
- For race conditions, send a small number of parallel requests, not a flood. Enough to prove the window, no more.
- Use your test account and test data. If a test would move real money or change real state, stop and confirm with the user first, or prove it on seeded data only.
- For values the client controls (price, total, role, owner, status, step), follow the edit-and-resend method in [tampering.md](tampering.md).

## Confirmed Finding Looks Like

The app let you do something its rules should forbid (pay less, act twice, skip a gate), reproduced with evidence, impact stated in business terms.

## Fix

- Enforce every rule on the server. Never trust price, quantity, role, or step state from the client.
- Make one-time actions idempotent or single-use with a server-side guard.
- Handle concurrency with locks, atomic operations, or unique constraints so a check cannot be raced.
- Re-check preconditions at each step, not just in the UI flow.

References: OWASP WSTG Business Logic, CWE-841, CWE-362, CWE-840.
