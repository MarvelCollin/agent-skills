create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  email text not null,
  role text not null default 'member'
);
alter table public.profiles enable row level security;
create policy "profiles are readable by their owner" on public.profiles for select to authenticated using (auth.uid() = id);

create table public.plans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  seat_price integer not null
);
alter table public.plans enable row level security;
create policy "plans are public" on public.plans for select to anon, authenticated using (true);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id),
  plan_id uuid not null references public.plans (id),
  seats integer not null check (seats > 0),
  total_cents integer not null,
  created_at timestamptz not null default now()
);
alter table public.orders enable row level security;
create policy "orders are readable by their owner" on public.orders for select to authenticated using (auth.uid() = user_id);

insert into storage.buckets (id, name, public) values ('attachments', 'attachments', false);
