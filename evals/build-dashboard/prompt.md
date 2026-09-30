---
tags: [build]
runs: 1
max_turns: 80
timeout_seconds: 1800
allowed_tools: [Skill, Read, Write, Edit, Glob, Grep, Bash]
---

Build a single-file admin dashboard for a school testing system as index.html, using plain HTML, CSS and JavaScript with no build step. It should show the totals for questions, users, active schedules and test results, and a users table with a profile picture, name, role (Student or Teacher), email and joined date. Simulate a backend with a mock API function that returns one page of users at a time, with sample data for 200 users.
