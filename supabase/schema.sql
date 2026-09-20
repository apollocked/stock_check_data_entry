-- Stockly database schema for Supabase.
--
-- Run this whole file once in the Supabase SQL editor of a new project.
-- It is safe to run again: every statement is idempotent.
--
-- It was written from what the app reads and writes (see
-- lib/data/datasources/), so if you already have a live project, compare it
-- with your existing tables before applying anything.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

-- The app is single-store: it always loads the first row of `branches`.
create table if not exists public.branches (
  id         bigint generated always as identity primary key,
  name       text not null,
  location   text,
  -- List of {id, label, type, enabled, required}; see ItemField in store.dart.
  fields     jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.items (
  id            bigint generated always as identity primary key,
  branch_id     bigint not null references public.branches (id) on delete cascade,
  name          text not null,
  description   text,
  price         numeric(12, 2),
  barcode       text,
  image_url     text,
  -- The app writes this as a JSON-encoded string and reads either a string or
  -- an object (see Item.fromMap), so jsonb accepts both.
  custom_fields jsonb not null default '{}'::jsonb,
  -- Maintained only by record_stock_movement(); may go negative on purpose.
  quantity      integer not null default 0,
  created_at    timestamptz not null default now()
);

create unique index if not exists items_branch_barcode_key
  on public.items (branch_id, barcode)
  where barcode is not null;

create index if not exists items_created_at_idx
  on public.items (created_at desc);

create table if not exists public.stock_movements (
  id            bigint generated always as identity primary key,
  item_id       bigint not null references public.items (id) on delete cascade,
  branch_id     bigint not null references public.branches (id) on delete cascade,
  movement_type text not null check (movement_type in ('IN', 'OUT', 'DAMAGE')),
  -- Always positive; the sign comes from movement_type.
  quantity      integer not null check (quantity > 0),
  note          text,
  user_id       uuid default auth.uid(),
  user_email    text,
  created_at    timestamptz not null default now()
);

create index if not exists stock_movements_created_at_idx
  on public.stock_movements (created_at desc);
create index if not exists stock_movements_item_id_idx
  on public.stock_movements (item_id);

-- ---------------------------------------------------------------------------
-- Functions
-- ---------------------------------------------------------------------------

-- Records a movement and updates the item quantity in one transaction.
-- Returns the new quantity. Raised messages are shown to the user as-is.
create or replace function public.record_stock_movement(
  p_item_id       bigint,
  p_movement_type text,
  p_quantity      integer,
  p_note          text default null
) returns integer
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_item    public.items%rowtype;
  v_new_qty integer;
begin
  if auth.uid() is null then
    raise exception 'You need to sign in first.';
  end if;

  if p_movement_type not in ('IN', 'OUT', 'DAMAGE') then
    raise exception 'Unknown movement type.';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Quantity must be greater than zero.';
  end if;

  -- Lock the row so two devices cannot overwrite each other's update.
  select * into v_item from public.items where id = p_item_id for update;
  if not found then
    raise exception 'Item not found.';
  end if;

  v_new_qty := case p_movement_type
    when 'IN' then v_item.quantity + p_quantity
    else v_item.quantity - p_quantity
  end;

  update public.items set quantity = v_new_qty where id = p_item_id;

  insert into public.stock_movements
    (item_id, branch_id, movement_type, quantity, note, user_id, user_email)
  values (
    p_item_id,
    v_item.branch_id,
    p_movement_type,
    p_quantity,
    nullif(btrim(p_note), ''),
    auth.uid(),
    auth.jwt() ->> 'email'
  );

  return v_new_qty;
end;
$$;

-- Summary numbers for the Reports tab. "Low" means 1 to 5 units, matching the
-- badge in the inventory list.
create or replace function public.branch_stock_report(p_branch_id bigint)
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  select jsonb_build_object(
    'total_items',  count(*),
    'total_units',  coalesce(sum(i.quantity), 0),
    'stock_value',  coalesce(sum(i.quantity * coalesce(i.price, 0)), 0),
    'in_stock',     count(*) filter (where i.quantity > 0),
    'zero_stock',   count(*) filter (where i.quantity = 0),
    'minus_stock',  count(*) filter (where i.quantity < 0),
    'low_stock',    count(*) filter (where i.quantity between 1 and 5),
    'total_in',     (select coalesce(sum(m.quantity), 0)
                       from public.stock_movements m
                      where m.branch_id = p_branch_id and m.movement_type = 'IN'),
    'total_out',    (select coalesce(sum(m.quantity), 0)
                       from public.stock_movements m
                      where m.branch_id = p_branch_id and m.movement_type = 'OUT'),
    'total_damage', (select coalesce(sum(m.quantity), 0)
                       from public.stock_movements m
                      where m.branch_id = p_branch_id and m.movement_type = 'DAMAGE')
  )
  from public.items i
  where i.branch_id = p_branch_id;
$$;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
-- The app has no roles yet, so every signed-in user gets full access and
-- anonymous visitors get none. If more than one team will share this project,
-- replace `using (true)` with a check against a membership table.

alter table public.branches        enable row level security;
alter table public.items           enable row level security;
alter table public.stock_movements enable row level security;

drop policy if exists "branches: signed-in access" on public.branches;
create policy "branches: signed-in access" on public.branches
  for all to authenticated using (true) with check (true);

drop policy if exists "items: signed-in access" on public.items;
create policy "items: signed-in access" on public.items
  for all to authenticated using (true) with check (true);

-- Movements are append-only from the app: read and insert, never edit.
drop policy if exists "stock_movements: signed-in read" on public.stock_movements;
create policy "stock_movements: signed-in read" on public.stock_movements
  for select to authenticated using (true);

drop policy if exists "stock_movements: signed-in insert" on public.stock_movements;
create policy "stock_movements: signed-in insert" on public.stock_movements
  for insert to authenticated with check (true);

revoke execute on function public.record_stock_movement(bigint, text, integer, text)
  from public, anon;
revoke execute on function public.branch_stock_report(bigint)
  from public, anon;
grant execute on function public.record_stock_movement(bigint, text, integer, text)
  to authenticated;
grant execute on function public.branch_stock_report(bigint)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Image storage
-- ---------------------------------------------------------------------------
-- Public bucket: item images are shown with getPublicUrl(), so anyone with the
-- link can view them, but only signed-in users can upload or delete.

insert into storage.buckets (id, name, public)
values ('grocery_images', 'grocery_images', true)
on conflict (id) do nothing;

drop policy if exists "grocery_images: signed-in upload" on storage.objects;
create policy "grocery_images: signed-in upload" on storage.objects
  for insert to authenticated with check (bucket_id = 'grocery_images');

-- Uploads use upsert, which also needs select and update.
drop policy if exists "grocery_images: signed-in read" on storage.objects;
create policy "grocery_images: signed-in read" on storage.objects
  for select to authenticated using (bucket_id = 'grocery_images');

drop policy if exists "grocery_images: signed-in update" on storage.objects;
create policy "grocery_images: signed-in update" on storage.objects
  for update to authenticated
  using (bucket_id = 'grocery_images') with check (bucket_id = 'grocery_images');

drop policy if exists "grocery_images: signed-in delete" on storage.objects;
create policy "grocery_images: signed-in delete" on storage.objects
  for delete to authenticated using (bucket_id = 'grocery_images');

-- ---------------------------------------------------------------------------
-- First store
-- ---------------------------------------------------------------------------
-- The app expects exactly one store to exist. Rename it in the app or here.

insert into public.branches (name)
select 'My Store'
where not exists (select 1 from public.branches);
