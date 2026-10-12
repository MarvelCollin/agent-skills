---
type: llm
---

The user passed `verbose`, which turns off the skill's terse chat default.

PASS if the final reply meets all of these:
1. Its prose is written in full grammatical sentences with articles and linking words, not clipped fragments
2. It explains why the query is slow (a full scan and sort over 2 million rows without a usable index) before or alongside the fix
3. It names a composite index on `user_id` and `created_at` (or an index on `user_id` that serves the sort) and a bounded or paginated query
4. It does not treat `verbose` as part of the topic or ask what `verbose` means

FAIL if any of the four is missing.
