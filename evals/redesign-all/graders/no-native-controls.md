---
type: regex
pattern: 'type=["'']date["'']|(^|[^.\w])alert\(\s*["''`]'
match: not_contains
target: { source: file, path: app/src/pages/Settings.jsx }
---
