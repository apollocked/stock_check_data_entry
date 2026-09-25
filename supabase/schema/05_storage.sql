-- Stockly schema, part 5 of 5: image storage and the first store.

-- ---------------------------------------------------------------------------
-- Image storage
-- ---------------------------------------------------------------------------
-- Public bucket: item images are shown with getPublicUrl(), so anyone with the
-- link can view them. Uploads are limited to images of 5 MB or less, go under
-- items/, and never overwrite an existing file.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'grocery_images', 'grocery_images', true, 5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update
  set file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "grocery_images: signed-in upload" on storage.objects;
drop policy if exists "grocery_images: signed-in read" on storage.objects;
drop policy if exists "grocery_images: signed-in update" on storage.objects;
drop policy if exists "grocery_images: signed-in delete" on storage.objects;

drop policy if exists "grocery_images: members upload" on storage.objects;
create policy "grocery_images: members upload" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'grocery_images'
    and name like 'items/%'
    and (select public.is_member())
  );

drop policy if exists "grocery_images: members read" on storage.objects;
create policy "grocery_images: members read" on storage.objects
  for select to authenticated
  using (bucket_id = 'grocery_images' and (select public.is_member()));

drop policy if exists "grocery_images: members delete" on storage.objects;
create policy "grocery_images: members delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'grocery_images' and (select public.is_member()));

-- ---------------------------------------------------------------------------
-- First store
-- ---------------------------------------------------------------------------
-- The app expects exactly one store to exist. Rename it in the app or here.

insert into public.branches (name)
select 'My Store'
where not exists (select 1 from public.branches);
