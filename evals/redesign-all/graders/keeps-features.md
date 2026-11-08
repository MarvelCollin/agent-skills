---
type: llm
---

The redesign must change the look and the components, never what the app can do. The original app has: routes `/`, `/students`, `/students/:id` and `/settings`, the API module `src/api.js` with `getStats`, `getStudents({ page, pageSize, q, role })`, `getStudent`, `deleteStudent`, `getSettings` and `saveSettings`, the grading helpers in `src/lib/grade.js`, a student search, a role filter (all, student, assistant), server paging, delete with a confirmation, and settings for school name, term start date and email notifications.

PASS if, judging from the files the run wrote and the final reply, all four routes still exist, every screen still calls the same API functions with the same parameters, `src/lib/grade.js` keeps `letterGrade` and `averageScore` with the same behavior, search, role filter, paging and delete still work, delete still asks for confirmation (in a custom dialog, not removed), and all three settings fields are still saved.
FAIL if any route, API call, field or feature is dropped, renamed in a way that breaks it, or replaced with mock data.
