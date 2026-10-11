---
type: regex
pattern: 'font-family:[^;]*(Inter|Geist|Space Grotesk)\b|family=(Inter|Geist|Space\+Grotesk)\b'
match: not_contains
target: { source: file, path: index.html }
---
