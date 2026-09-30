---
type: regex
pattern: 'rounded-full|border-radius:\s*(9999|999)px'
match: not_contains
target: { source: file, path: index.html }
---
