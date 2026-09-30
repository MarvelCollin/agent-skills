---
type: regex
pattern: '—|&mdash;'
match: not_contains
target: { source: file, path: index.html }
---
