# Client Data Access: RLS, Storage Buckets and Database Rules

Rule B18. When the client talks to the database or storage directly, there is no server in between to check the caller. The rules in the database are the only gate. Supabase, Firebase, Appwrite, PocketBase, Hasura and presigned upload flows all work this way.

The anon or public key is meant to be public. It sits in the bundle and anyone can copy it. Treat every rule as if the attacker already has that key, a logged in test account and `curl`.

## Supabase and Postgres RLS

### Turn It On Where the Table Is Born

```sql
create table public.notes (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) default auth.uid(),
  body text not null,
  created_at timestamptz not null default now()
);
alter table public.notes enable row level security;
```

Wrong: creating the table in one migration and planning to enable RLS later. Until that later migration runs, every row is open through the REST API. Wrong: `alter table ... disable row level security` to make an error go away.

### Policies Per Command, Scoped to the Caller

```sql
create policy "notes are readable by their owner"
  on public.notes for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "notes are created by their owner"
  on public.notes for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "notes are updated by their owner"
  on public.notes for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
```

- `(select auth.uid())` instead of `auth.uid()` lets Postgres evaluate it once per query instead of once per row. Index the column the policy filters on (`user_id`)
- `using` decides which existing rows a command can see. `with check` decides which new or changed rows are allowed. An update policy needs both, or a user can move a row to another owner
- `using (true)` is for rows that are public on purpose, such as published posts, and only `for select`. On insert, update, delete or `for all` it opens the table to everyone
- Tenancy goes through a membership lookup: `using (org_id in (select org_id from memberships where user_id = (select auth.uid())))`, with an index on `memberships (user_id, org_id)`
- Columns a user must not change (role, plan, price, status, owner) are protected with a column privilege (`revoke update (role) on public.profiles from authenticated`), a trigger that rejects the change, or a security definer function that runs the business rule. Leaving the field out of the form protects nothing
- Views run with the owner's rights and skip RLS unless created `with (security_invoker = true)`. Security definer functions skip RLS too, so they check the caller and set a fixed `search_path`
- Tables that the client never needs live in a schema that is not exposed through the API (`private`), or have RLS on with no policy at all

### Keys

| Key | Where it may live |
|-----|-------------------|
| `anon` or publishable key | The client. Safe only because RLS is on |
| `service_role` or secret key | Server and edge functions only. It bypasses RLS. Never behind `NEXT_PUBLIC_`, `VITE_` or any public prefix (B16) |
| Database password and connection string | Server only |

An edge function that uses the service role checks the caller's JWT first and applies the same ownership rule the policy would.

## Supabase Storage

```sql
insert into storage.buckets (id, name, public) values ('avatars', 'avatars', false);

create policy "users read their own files"
  on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "users upload into their own folder"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
```

- Buckets are private unless every file in them is meant for everyone (marketing images). A public bucket serves any file to anyone who guesses or finds the path
- Serve private files with `createSignedUrl` and a short expiry, minutes not days
- Set `file_size_limit` and `allowed_mime_types` on the bucket, and still check the content on the server for anything that is processed (B3)
- Object names are generated (`<user id>/<uuid>.webp`), never the user's file name
- Listing a bucket needs its own select policy. Do not grant it broadly

## Firebase

Firestore and Storage rules are the only check between the client SDK and the data.

Never ship:

```
allow read, write: if true;
allow read, write: if request.time < timestamp.date(2026, 1, 1);
allow read, write: if request.auth != null;
```

The first is open to everyone. The second is the test mode rule, open until the date. The third lets any signed in user read and change every user's data.

Do this:

```
match /users/{userId}/notes/{noteId} {
  allow read, delete: if request.auth != null && request.auth.uid == userId;
  allow create, update: if request.auth != null && request.auth.uid == userId
    && request.resource.data.keys().hasOnly(['body', 'updatedAt'])
    && request.resource.data.body is string && request.resource.data.body.size() < 10000;
}
```

- Validate the shape of every write in the rule (`hasOnly`, types, sizes), because the client SDK sends whatever the user wants
- Fields such as `role` or `plan` are written only by the Admin SDK on the server or a Cloud Function
- Test rules with the emulator in CI: an owner can, another user cannot, a signed out user cannot

## S3, GCS and Presigned URLs

- Keep Block Public Access on at the account and bucket level. No `public-read` ACL, no bucket policy with `"Principal": "*"`
- Uploads go through a presigned PUT or POST with a short expiry, a content length range and a fixed key chosen by the server
- Downloads of private files go through presigned GET URLs or a CDN with signed cookies
- Server side, read the uploaded object's real type before processing it

## How to Prove It

1. With only the anon key and no session, call the REST endpoint of each table (`/rest/v1/<table>?select=*`) or the Firestore REST API. Every private table returns nothing or 401
2. Log in as test user A, create a row and a file. Log in as test user B and try to read, update and delete them by id. Every attempt fails
3. As user B, try to insert a row with `user_id` set to A and try to change your own `role`. Both fail
4. Request a private file without a signed URL. It fails
5. Run the Supabase security advisor (database linter) or the Firebase rules tests in CI so a new table without RLS fails the build

Only run these against your own project or one you are authorized to test. For a deeper attack pass, hand off to `/security`.

## Checklist

- [ ] RLS enabled on every table in an exposed schema, in the same migration that creates it
- [ ] No `using (true)` or `with check (true)` on insert, update, delete or `for all`
- [ ] Update policies have both `using` and `with check`
- [ ] Protected columns cannot be changed by the client
- [ ] Service role key only on the server, edge functions check the caller
- [ ] Buckets private by default, signed URLs, per user folders, size and type limits
- [ ] Firebase rules compare `request.auth.uid` with the owner and validate write shape
- [ ] Cloud buckets block public access, presigned URLs expire quickly
- [ ] A cross user test proves A cannot reach B's rows or files
