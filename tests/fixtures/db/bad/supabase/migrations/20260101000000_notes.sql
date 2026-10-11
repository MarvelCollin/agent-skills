create table public.notes (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id),
  body text not null
);

create table public.profiles (
  id uuid primary key references auth.users (id),
  role text not null default 'member'
);
alter table public.profiles enable row level security;

create policy "anyone can edit profiles" on public.profiles for update using (true);
create policy "profiles are public" on public.profiles for select using (true);
alter table public.audit disable row level security;

insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);
