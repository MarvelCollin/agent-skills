---
type: llm
---

PASS if the reply grades the service against the checklist groups (at least Security, Database Speed and Response Speed, ideally Maintenance and Caching too) with a pass, fail or unverified status per item, and backs each failure with a specific observation from the code (a line, a call or a value) rather than generic advice. Items that cannot be seen from code (backups, CDN, HTTPS at the load balancer) must be marked unverified or not applicable, not passed.
FAIL if the reply is an unstructured list of tips, grades items without evidence, or marks backups or HTTPS as passing without any proof.
