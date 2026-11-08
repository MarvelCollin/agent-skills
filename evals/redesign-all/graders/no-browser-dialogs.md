---
type: regex
pattern: '(^|[^.\w])(alert|confirm)\(\s*["''`]'
match: not_contains
target: { source: file, path: app/src/pages/Students.jsx }
---
