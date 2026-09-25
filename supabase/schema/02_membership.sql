-- Stockly schema, part 2 of 5: who may use the store.

-- ---------------------------------------------------------------------------
-- Membership
-- ---------------------------------------------------------------------------

-- True when the caller is allowed to use the store. SECURITY DEFINER so the
-- RLS policies below can call it without being able to read `members`.
create or replace function public.is_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.members where user_id = (select auth.uid())
  );
$$;

-- Makes the first account in a new project a member, so someone can get in.
create or replace function public.handle_first_member()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (select 1 from public.members) then
    insert into public.members (user_id) values (new.id)
    on conflict do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_first_member on auth.users;
create trigger on_auth_user_created_first_member
  after insert on auth.users
  for each row execute function public.handle_first_member();

-- Existing projects: keep access for everyone who already had it the first
-- time this file runs. Review public.members afterwards and remove anyone
-- who should not be there.
insert into public.members (user_id)
select id from auth.users
where not exists (select 1 from public.members)
on conflict do nothing;

create or replace function public.list_members()
returns table (user_id uuid, email text, added_at timestamptz, is_me boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select m.user_id, u.email::text, m.created_at, m.user_id = (select auth.uid())
  from public.members m
  join auth.users u on u.id = m.user_id
  where public.is_member()
  order by m.created_at;
$$;

create or replace function public.add_member(p_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid;
begin
  if not public.is_member() then
    raise exception 'You do not have access to this store.' using errcode = '42501';
  end if;

  select id into v_user
  from auth.users
  where lower(email) = lower(btrim(p_email));

  if v_user is null then
    raise exception 'No account uses that email yet. Ask them to create one in the app first.';
  end if;

  insert into public.members (user_id, added_by)
  values (v_user, auth.uid())
  on conflict do nothing;
end;
$$;

create or replace function public.remove_member(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_member() then
    raise exception 'You do not have access to this store.' using errcode = '42501';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'You cannot remove your own access.';
  end if;
  delete from public.members where user_id = p_user_id;
end;
$$;
