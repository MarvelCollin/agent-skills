# Data and Storage the Client Can Reach

Apps built on Supabase, Firebase, Appwrite or PocketBase let the browser talk to the database and file storage directly. The public key ships in the bundle, so the database rules are the only access control. A table without Row Level Security, a policy of `using (true)`, a public bucket or a Firebase rule of `if true` gives every visitor the data, with no server bug needed.

## What to Check

- **Tables without RLS:** any table in an exposed schema (`public` in Supabase) that the anon key can read or write.
- **Permissive policies:** `using (true)` or `with check (true)` on insert, update, delete or `for all`, update policies with no `with check`, and policies that trust any signed in user instead of the row's owner.
- **Writable protected columns:** a user can change their own `role`, `plan`, `credits` or `owner` through the REST API because only the UI hides the field.
- **Service role in the client:** a key that bypasses RLS shipped in the bundle (`service_role`, Firebase Admin credentials). See [client-exposure.md](client-exposure.md).
- **Storage:** public buckets holding private files, bucket listing open to anyone, storage policies that do not scope objects to the owner's folder, signed URLs that last for days, uploads with no size or type limit.
- **Firebase rules:** `allow read, write: if true`, the test mode rule `if request.time < timestamp.date(...)` that expires but is still live, `if request.auth != null` with no owner check, writes with no shape validation.
- **Cloud buckets:** S3 or GCS objects with a `public-read` ACL, a bucket policy with `"Principal": "*"`, public access block turned off.

## How to Test Safely

Use the project's own public key, which recon finds in the bundle, and two test accounts you created. Never use a service role key you find. Report it instead.

1. **Anon read.** With only the anon key, request each table: `curl "<project>/rest/v1/<table>?select=*&limit=1" -H "apikey: <anon key>"`. Read one row at most. Private data returned is the finding
2. **Cross user read and write.** As test user A, create a row and a file. As test user B, read, update and delete A's row by id, and download A's file by path. Use only records you created
3. **Field tampering.** As user B, `PATCH` your own profile with `role`, `plan` or `user_id` changed. A changed value on a second read is the finding (see [tampering.md](tampering.md))
4. **Storage.** Request a private file's public URL with no signature. List the bucket with the anon key. Upload one small harmless file of a type the app should refuse
5. **Firebase.** Read the deployed rules if you have the source. Otherwise read one document path you do not own through the REST API with a test account

Lightest touch only: one row, one file, records you created. Never dump a table, never delete data you did not create, and stop and tell the user at once if real user data comes back.

`grep-audit` flags leads in migrations and rules files: `rls-off`, `permissive-policy`, `public-bucket` and `open-rules`.

## Confirmed Finding Looks Like

The anon key or test user B read or changed data or a file that belongs to user A, or set a protected field, with the request and the response saved and the missing policy named.

## Fix

- Enable RLS in the same migration that creates each table, and write one policy per command scoped to `(select auth.uid())`.
- Give update policies both `using` and `with check`. Protect sensitive columns with column privileges or a trigger.
- Keep the service role key on the server only, and rotate it if it ever shipped.
- Make buckets private, serve files through short lived signed URLs, scope storage policies to the owner's folder, and set size and type limits.
- Rewrite Firebase rules to compare `request.auth.uid` with the owner and validate the shape of each write. Test them in the emulator in CI.
- Block public access on cloud buckets and use presigned URLs.

References: OWASP Top 10 A01, OWASP API Security Top 10 API1 and API3, CWE-284, CWE-639, CWE-732.
