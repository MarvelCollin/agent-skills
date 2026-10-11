create table public.notes (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id),
  body text not null
);
create index notes_user_id_idx on public.notes (user_id);
alter table public.notes enable row level security;

create policy "notes are readable by their owner" on public.notes for select to authenticated using ((select auth.uid()) = user_id);
create policy "notes are written by their owner" on public.notes for insert to authenticated with check ((select auth.uid()) = user_id);

create table private.jobs (
  id bigint generated always as identity primary key,
  payload jsonb not null
);

insert into storage.buckets (id, name, public) values ('avatars', 'avatars', false);
