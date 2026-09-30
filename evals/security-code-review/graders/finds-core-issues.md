---
type: llm
---

PASS if the reply identifies the SQL injection from string concatenation in find_user, the hardcoded database password, and the use of MD5 for password hashing, and gives a concrete fix for each (parameterized query, move secret to env or a secrets manager and rotate, use a strong password hash).
FAIL if it misses the SQL injection or the hardcoded secret, or gives no concrete fixes.
