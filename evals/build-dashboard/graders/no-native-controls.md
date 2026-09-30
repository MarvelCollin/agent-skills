---
type: regex
pattern: '<select|type="(date|datetime-local|time|month|week|range|color)"|[^.\w](alert|confirm|prompt)\('
match: not_contains
target: { source: file, path: index.html }
---
