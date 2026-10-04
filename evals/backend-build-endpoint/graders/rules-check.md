---
type: llm
---

PASS if the final reply gives a short rules check or self-review of the endpoint against backend rules (for example N+1, pagination, authorization, indexes), and considers the index that supports the query (such as an index on `Order(userId, createdAt)`), either added to the schema or recommended.
FAIL if there is no self-review, or indexing is never considered.
