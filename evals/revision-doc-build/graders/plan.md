---
type: llm
---

PASS if the final reply meets all of these:
1. It plans one page per change with the problem behind the request (written as a problem statement, not the user's chat wording), what changed and how it was checked
2. It says before shots must show the old screen and come from before the code change or from an untouched copy of the last commit, and does not suggest git stash
3. It says before and after shots use the same screen, size and account, with red boxes on what changed
4. It does not claim screenshots were taken or a docx was written when no tool did that
5. It contains no semicolons and no em dashes

FAIL if any of the five is missing.
