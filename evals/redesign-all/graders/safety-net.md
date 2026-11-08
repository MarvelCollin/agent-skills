---
type: llm
---

The app folder is a copy of the fixture and is not a git repository. The uiux all mode must set up a way back before it edits anything.

PASS if, before the first edit to a file under app/src, the run either creates a git branch or copies the untouched sources into a `uiux-all-<date>/original/` folder, and records a baseline by running the unit tests (`npm test` or `node --test`) or the rule scan on the app.
FAIL if it edits app/src before making that copy or branch, or never records a baseline.
