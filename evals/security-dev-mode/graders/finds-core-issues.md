---
type: llm
---

PASS if the reply identifies the SQL injection from string concatenation in the /api/notes/:id route, the reflected XSS in /api/search, and the hardcoded JWT secret, and gives a concrete fix for each (parameterized query, output encoding or a template that escapes, move the secret to an env var and rotate it).
FAIL if it misses the SQL injection or the hardcoded secret, or gives no concrete fixes.
