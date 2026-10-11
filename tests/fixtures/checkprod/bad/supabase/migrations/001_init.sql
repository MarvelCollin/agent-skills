create table public.profiles (
  id uuid primary key,
  role text not null default 'member'
);
alter table public.profiles enable row level security;
create policy "anyone can update profiles" on public.profiles
  for update using (true);

create table public.orders (
  id serial primary key,
  item text not null,
  price numeric not null,
  status text not null
);

insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);
