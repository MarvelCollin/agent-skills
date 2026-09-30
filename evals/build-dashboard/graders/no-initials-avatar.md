---
type: regex
pattern: 'getInitials|charAt\(0\)|initials'
flags: i
match: not_contains
target: { source: file, path: index.html }
---
