-- Stockly database schema for Supabase, part 1 of 5: tables.
--
-- Run the files in supabase/schema/ in order (01 to 05) in the Supabase SQL
-- editor. They are safe to run again: every statement is idempotent, so
-- running them on an existing project also upgrades that project to the
-- current security model.
--
-- It was written from what the app reads and writes (see
-- lib/data/datasources/), so if you already have a live project, compare it
-- with your existing tables before applying anything.
--
-- Access model
-- ------------
-- Signing up is not enough to see the store. Only users listed in
-- public.members can read or change anything. The first account created in a
-- project becomes a member automatically; members can then give access to
-- other accounts from the app (Settings -> Team) or with:
--
--   insert into public.members (user_id)
--   select id from auth.users where email = 'person@example.com';

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
  -- Older app versions wrote this as a JSON-encoded string; current ones
  -- write an object. Item.fromMap reads both.
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

-- Accounts allowed to use the store.
create table if not exists public.members (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  added_by   uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Input limits
-- ---------------------------------------------------------------------------
-- Added as NOT VALID so existing rows are left alone; new writes are checked.

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'branches_name_len') then
    alter table public.branches add constraint branches_name_len
      check (char_length(btrim(name)) between 1 and 100) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'branches_location_len') then
    alter table public.branches add constraint branches_location_len
      check (location is null or char_length(location) <= 200) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'branches_fields_array') then
    alter table public.branches add constraint branches_fields_array
      check (jsonb_typeof(fields) = 'array' and pg_column_size(fields) <= 8192) not valid;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'items_name_len') then
    alter table public.items add constraint items_name_len
      check (char_length(btrim(name)) between 1 and 200) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'items_description_len') then
    alter table public.items add constraint items_description_len
      check (description is null or char_length(description) <= 1000) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'items_price_range') then
    alter table public.items add constraint items_price_range
      check (price is null or price >= 0) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'items_barcode_len') then
    alter table public.items add constraint items_barcode_len
      check (barcode is null or char_length(barcode) between 1 and 128) not valid;
  end if;
  -- Images must be HTTPS links (the app only uploads to Supabase Storage).
  if not exists (select 1 from pg_constraint where conname = 'items_image_url_https') then
    alter table public.items add constraint items_image_url_https
      check (image_url is null
             or (image_url like 'https://%' and char_length(image_url) <= 2048)) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'items_custom_fields_size') then
    alter table public.items add constraint items_custom_fields_size
      check (pg_column_size(custom_fields) <= 8192) not valid;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'stock_movements_note_len') then
    alter table public.stock_movements add constraint stock_movements_note_len
      check (note is null or char_length(note) <= 500) not valid;
  end if;
end;
$$;
