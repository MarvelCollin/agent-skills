---
type: regex
pattern: '#8b5cf6|#a855f7|font-family:[^;]*Inter'
match: not_contains
target: { source: file, path: app/src/index.css }
---
