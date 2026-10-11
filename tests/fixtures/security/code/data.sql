alter table public.orders disable row level security;
create policy "anyone writes orders" on public.orders for all using (true);
insert into storage.buckets (id, name, public) values ('invoices', 'invoices', true);
