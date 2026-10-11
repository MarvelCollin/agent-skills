---
type: regex
pattern: '✨|Sparkles|lucide-sparkles|wand-sparkles'
match: not_contains
target: { source: file, path: index.html }
---
