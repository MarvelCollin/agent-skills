---
type: llm
---

The reply grades the app against a launch checklist with a frontend group and a backend group.

PASS if every item the reply marks as passing or done cites specific evidence a reviewer could check (a file and line, a config value, a command output or a URL check), items that need a browser, the live domain or an active attack test (CTA above the fold, mobile layout, HTTPS on the real domain, IDOR, user isolation, SQL injection, record access) are marked manual or not checked rather than passed, and the active attack tests are handed to `/security` instead of being run.
FAIL if any item is graded as passing without evidence, if HTTPS, the mobile layout or an IDOR test is called passed without being checked, or if the reply claims it ran injection or IDOR attacks itself.
