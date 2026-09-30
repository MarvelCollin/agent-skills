---
type: llm
focus: { source: file, path: index.html }
---

PASS if the users table loads one page at a time through the mock API with page and page size parameters and passes search, sort and filters to that API rather than filtering a full in-memory array, shows a skeleton of rows while a page loads, and shows the range and total ("1 to 25 of 200") with next and previous controls.
FAIL if it renders all 200 users at once, filters or pages in the browser, or shows a blank table or only a spinner while loading.
