-- Stockly schema, part 3 of 5: stock movements and the report.

-- ---------------------------------------------------------------------------
-- Stock functions
-- ---------------------------------------------------------------------------

-- Records a movement and updates the item quantity in one transaction.
-- Returns the new quantity. Raised messages are shown to the user as-is.
--
-- SECURITY DEFINER because this is the only way the app may write to
-- stock_movements or change items.quantity: both are closed to direct writes
-- below, so the log can't be forged and quantities can't drift from it.
create or replace function public.record_stock_movement(
  p_item_id       bigint,
  p_movement_type text,
  p_quantity      integer,
  p_note          text default null
) returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_item    public.items%rowtype;
  v_new_qty integer;
begin
  if auth.uid() is null then
    raise exception 'You need to sign in first.';
  end if;

  if not public.is_member() then
    raise exception 'You do not have access to this store.' using errcode = '42501';
  end if;

  if p_movement_type not in ('IN', 'OUT', 'DAMAGE') then
    raise exception 'Unknown movement type.';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Quantity must be greater than zero.';
  end if;

  if p_quantity > 1000000 then
    raise exception 'Quantity is too large.';
  end if;

  if p_note is not null and char_length(p_note) > 500 then
    raise exception 'The note is too long (500 characters max).';
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
-- badge in the inventory list. Runs as the caller, so RLS limits it to members.
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
