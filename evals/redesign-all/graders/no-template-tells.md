---
type: regex
pattern: '✨|📝|📊|👥|<em>|—'
match: not_contains
target: { source: file, path: app/src/pages/Dashboard.jsx }
---
