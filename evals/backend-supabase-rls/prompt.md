---
tags: [backend, build, security]
runs: 1
max_turns: 40
timeout_seconds: 900
allowed_tools: [Skill, Read, Glob, Grep, Bash, Write, Edit]
---

Write the first Supabase migration for our notes app at `supabase/migrations/20260101000000_init.sql`. We need a `profiles` table (one row per user with display name, avatar path, role and plan), a `notes` table (title, body, owner, timestamps), and a storage bucket for profile pictures. Our React app talks to Supabase directly from the browser with the anon key, there is no other backend. Users should only ever see and edit their own notes and their own profile.
