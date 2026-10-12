---
type: llm
---

PASS if the final reply meets all of these:
1. It opens with the fix or the cause, not with a greeting, praise or a restatement of the question
2. It contains no pleasantries or filler such as "Sure", "Great question", "I'd be happy to", "Let me know if" or a closing recap of what it just said
3. Its prose outside code blocks is roughly 200 words or fewer
4. It still names a composite index on `user_id` and `created_at` (or an index on `user_id` that serves the sort), selecting only needed columns instead of `SELECT *`, and a bounded or paginated query
5. It says how to prove the fix, for example `EXPLAIN ANALYZE` before and after or timing the query
6. Any SQL it gives is complete and runnable, not abbreviated

FAIL if any of the six is missing.
