---
type: llm
focus: { source: file, path: supabase/migrations/20260101000000_init.sql }
---

This is the migration that was written. The browser reaches the database directly with the public anon key, so the rules in this file are the only access control.

PASS if all of these hold:
1. Row Level Security is enabled on both `profiles` and `notes` in this migration
2. Policies are scoped to the caller with `auth.uid()` (ideally `(select auth.uid())`) per command, and no insert, update, delete or `for all` policy uses `using (true)` or `with check (true)`
3. Update policies have both `using` and `with check`, so a user cannot move a row to another owner
4. A user cannot change their own `role` or `plan` through the API (a column privilege, a trigger, or a policy check that keeps them unchanged)
5. The profile pictures bucket is private (`public` false) and storage policies keep each user inside their own folder
6. The owner column on `notes` has an index

FAIL if any of the six is missing, or if any table the browser can reach is left without RLS.
