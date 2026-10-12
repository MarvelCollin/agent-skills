---
tags: [backend, terse]
runs: 1
max_turns: 10
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
---

/backend query Our Express dashboard runs `SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC` on every page load against Postgres. It was fine at launch but now the table has 2 million rows and the page takes 4 seconds. There is no index besides the primary key. What should I change?
