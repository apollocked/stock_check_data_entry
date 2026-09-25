-- Stockly schema, part 4 of 5: table privileges and row level security.

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------
-- Supabase grants every table to `anon` and `authenticated` by default.
-- Narrow that to exactly what the app does; RLS then decides which rows.

revoke all on public.branches, public.items, public.stock_movements, public.members
  from anon;

revoke insert, update, delete on public.branches from authenticated;
grant select on public.branches to authenticated;
grant update (name, location, fields) on public.branches to authenticated;

-- `quantity` is left out on purpose: only record_stock_movement() changes it.
revoke insert, update on public.items from authenticated;
grant select, delete on public.items to authenticated;
grant insert (branch_id, name, description, price, barcode, image_url, custom_fields)
  on public.items to authenticated;
grant update (name, description, price, barcode, image_url, custom_fields)
  on public.items to authenticated;

-- The movement log is append-only and written only by record_stock_movement().
revoke insert, update, delete on public.stock_movements from authenticated;
grant select on public.stock_movements to authenticated;

-- Membership is managed only through the functions above.
revoke insert, update, delete on public.members from authenticated;
grant select on public.members to authenticated;

revoke execute on function public.is_member() from public, anon;
revoke execute on function public.handle_first_member() from public, anon, authenticated;
revoke execute on function public.list_members() from public, anon;
revoke execute on function public.add_member(text) from public, anon;
revoke execute on function public.remove_member(uuid) from public, anon;
revoke execute on function public.record_stock_movement(bigint, text, integer, text)
  from public, anon;
revoke execute on function public.branch_stock_report(bigint)
  from public, anon;

grant execute on function public.is_member() to authenticated;
grant execute on function public.list_members() to authenticated;
grant execute on function public.add_member(text) to authenticated;
grant execute on function public.remove_member(uuid) to authenticated;
grant execute on function public.record_stock_movement(bigint, text, integer, text)
  to authenticated;
grant execute on function public.branch_stock_report(bigint)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table public.branches        enable row level security;
alter table public.items           enable row level security;
alter table public.stock_movements enable row level security;
alter table public.members         enable row level security;

-- Policies from earlier versions of this file gave every signed-in user
-- (including anyone who signs up) full access.
drop policy if exists "branches: signed-in access" on public.branches;
drop policy if exists "items: signed-in access" on public.items;
drop policy if exists "stock_movements: signed-in read" on public.stock_movements;
drop policy if exists "stock_movements: signed-in insert" on public.stock_movements;

drop policy if exists "branches: members read" on public.branches;
create policy "branches: members read" on public.branches
  for select to authenticated using ((select public.is_member()));

drop policy if exists "branches: members update" on public.branches;
create policy "branches: members update" on public.branches
  for update to authenticated
  using ((select public.is_member())) with check ((select public.is_member()));

drop policy if exists "items: members read" on public.items;
create policy "items: members read" on public.items
  for select to authenticated using ((select public.is_member()));

drop policy if exists "items: members insert" on public.items;
create policy "items: members insert" on public.items
  for insert to authenticated with check ((select public.is_member()));

drop policy if exists "items: members update" on public.items;
create policy "items: members update" on public.items
  for update to authenticated
  using ((select public.is_member())) with check ((select public.is_member()));

drop policy if exists "items: members delete" on public.items;
create policy "items: members delete" on public.items
  for delete to authenticated using ((select public.is_member()));

drop policy if exists "stock_movements: members read" on public.stock_movements;
create policy "stock_movements: members read" on public.stock_movements
  for select to authenticated using ((select public.is_member()));

drop policy if exists "members: read own row" on public.members;
create policy "members: read own row" on public.members
  for select to authenticated using (user_id = (select auth.uid()));
