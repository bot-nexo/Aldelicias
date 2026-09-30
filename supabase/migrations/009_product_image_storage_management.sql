-- Product images are public catalog assets; writes remain admin-only and business-scoped.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

do $$
begin
  if not exists (
    select 1
    from storage.buckets
    where id = 'product-images'
      and name = 'product-images'
      and public = true
      and (file_size_limit is null or file_size_limit >= 5242880)
      and allowed_mime_types @> array['image/jpeg', 'image/png', 'image/webp']::text[]
  ) then
    raise exception 'The product-images bucket exists with incompatible access or upload settings.';
  end if;

  if exists (
    select 1
    from public.product_images
    where is_primary
    group by product_id
    having count(*) > 1
  ) then
    raise exception 'Resolve duplicate primary product images before applying migration 009.';
  end if;
end;
$$;

create unique index if not exists product_images_one_primary_per_product
  on public.product_images (product_id)
  where is_primary;

create policy product_image_storage_select_admin on storage.objects
for select to authenticated
using (
  bucket_id = 'product-images'
  and public.is_admin()
  and (storage.foldername(name))[1] = public.current_business_id()::text
  and cardinality(storage.foldername(name)) = 2
  and exists (
    select 1
    from public.products p
    where p.id::text = (storage.foldername(name))[2]
      and p.business_id = public.current_business_id()
  )
);

create policy product_image_storage_insert_admin on storage.objects
for insert to authenticated
with check (
  bucket_id = 'product-images'
  and public.is_admin()
  and (storage.foldername(name))[1] = public.current_business_id()::text
  and cardinality(storage.foldername(name)) = 2
  and exists (
    select 1
    from public.products p
    where p.id::text = (storage.foldername(name))[2]
      and p.business_id = public.current_business_id()
  )
);

create policy product_image_storage_delete_admin on storage.objects
for delete to authenticated
using (
  bucket_id = 'product-images'
  and public.is_admin()
  and (storage.foldername(name))[1] = public.current_business_id()::text
  and cardinality(storage.foldername(name)) = 2
  and exists (
    select 1
    from public.products p
    where p.id::text = (storage.foldername(name))[2]
      and p.business_id = public.current_business_id()
  )
);

create policy product_image_storage_insert_scope on storage.objects
as restrictive for insert to public
with check (
  bucket_id <> 'product-images'
  or (
    auth.uid() is not null
    and public.is_admin()
    and (storage.foldername(name))[1] = public.current_business_id()::text
    and cardinality(storage.foldername(name)) = 2
    and exists (
      select 1
      from public.products p
      where p.id::text = (storage.foldername(name))[2]
        and p.business_id = public.current_business_id()
    )
  )
);

create policy product_image_storage_update_scope on storage.objects
as restrictive for update to public
using (
  bucket_id <> 'product-images'
  or (
    auth.uid() is not null
    and public.is_admin()
    and (storage.foldername(name))[1] = public.current_business_id()::text
    and cardinality(storage.foldername(name)) = 2
    and exists (
      select 1
      from public.products p
      where p.id::text = (storage.foldername(name))[2]
        and p.business_id = public.current_business_id()
    )
  )
)
with check (
  bucket_id <> 'product-images'
  or (
    auth.uid() is not null
    and public.is_admin()
    and (storage.foldername(name))[1] = public.current_business_id()::text
    and cardinality(storage.foldername(name)) = 2
    and exists (
      select 1
      from public.products p
      where p.id::text = (storage.foldername(name))[2]
        and p.business_id = public.current_business_id()
    )
  )
);

create policy product_image_storage_delete_scope on storage.objects
as restrictive for delete to public
using (
  bucket_id <> 'product-images'
  or (
    auth.uid() is not null
    and public.is_admin()
    and (storage.foldername(name))[1] = public.current_business_id()::text
    and cardinality(storage.foldername(name)) = 2
    and exists (
      select 1
      from public.products p
      where p.id::text = (storage.foldername(name))[2]
        and p.business_id = public.current_business_id()
    )
  )
);

create function public.register_product_image(
  p_product_id uuid,
  p_storage_path text,
  p_alt_text text
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  image_id uuid;
  next_sort_order integer;
  make_primary boolean;
begin
  if auth.uid() is null or public.is_admin() is not true then
    raise exception 'Only an authenticated administrator can manage product images.';
  end if;

  if p_storage_path is null
     or split_part(p_storage_path, '/', 1) <> public.current_business_id()::text
     or split_part(p_storage_path, '/', 2) <> p_product_id::text
     or cardinality(string_to_array(p_storage_path, '/')) <> 3 then
    raise exception 'Product image path must be scoped to its business and product.';
  end if;

  if p_alt_text is null or length(btrim(p_alt_text)) = 0 or length(p_alt_text) > 300 then
    raise exception 'Product image alt text is required and must be at most 300 characters.';
  end if;

  perform 1
  from public.products p
  where p.id = p_product_id
    and p.business_id = public.current_business_id()
  for update;

  if not found then
    raise exception 'Product does not belong to the active business.';
  end if;

  if not exists (
    select 1
    from storage.objects o
    where o.bucket_id = 'product-images'
      and o.name = p_storage_path
  ) then
    raise exception 'Uploaded product image was not found in Storage.';
  end if;

  select coalesce(max(sort_order), -1) + 1
  into next_sort_order
  from public.product_images
  where product_id = p_product_id;

  select not exists (
    select 1
    from public.product_images i
    where i.product_id = p_product_id
      and i.is_primary
  )
  into make_primary;

  insert into public.product_images (
    product_id,
    storage_path,
    alt_text,
    sort_order,
    is_primary
  )
  values (
    p_product_id,
    p_storage_path,
    btrim(p_alt_text),
    next_sort_order,
    make_primary
  )
  returning id into image_id;

  return image_id;
end;
$$;

create function public.set_product_image_primary(
  p_product_id uuid,
  p_image_id uuid
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  if auth.uid() is null or public.is_admin() is not true then
    raise exception 'Only an authenticated administrator can manage product images.';
  end if;

  perform 1
  from public.products p
  where p.id = p_product_id
    and p.business_id = public.current_business_id()
  for update;

  if not found or not exists (
    select 1
    from public.product_images i
    where i.id = p_image_id
      and i.product_id = p_product_id
  ) then
    raise exception 'Product image does not belong to the active business product.';
  end if;

  update public.product_images
  set is_primary = false
  where product_id = p_product_id
    and is_primary
    and id <> p_image_id;

  update public.product_images
  set is_primary = true
  where id = p_image_id
    and product_id = p_product_id;
end;
$$;

create function public.move_product_image(
  p_product_id uuid,
  p_image_id uuid,
  p_direction integer
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  image_position integer;
  image_count integer;
begin
  if auth.uid() is null or public.is_admin() is not true then
    raise exception 'Only an authenticated administrator can manage product images.';
  end if;

  if p_direction not in (-1, 1) then
    raise exception 'Image direction must be -1 or 1.';
  end if;

  perform 1
  from public.products p
  where p.id = p_product_id
    and p.business_id = public.current_business_id()
  for update;

  if not found then
    raise exception 'Product does not belong to the active business.';
  end if;

  select ranked.position, ranked.total
  into image_position, image_count
  from (
    select
      i.id,
      row_number() over (order by i.sort_order, i.created_at, i.id)::integer as position,
      count(*) over ()::integer as total
    from public.product_images i
    where i.product_id = p_product_id
  ) ranked
  where ranked.id = p_image_id;

  if not found then
    raise exception 'Product image does not belong to the requested product.';
  end if;

  if image_position + p_direction < 1 or image_position + p_direction > image_count then
    return;
  end if;

  with ranked as (
    select
      i.id,
      row_number() over (order by i.sort_order, i.created_at, i.id)::integer as position
    from public.product_images i
    where i.product_id = p_product_id
  ), remapped as (
    select
      id,
      case
        when position = image_position then image_position + p_direction
        when position = image_position + p_direction then image_position
        else position
      end - 1 as new_sort_order
    from ranked
  )
  update public.product_images i
  set sort_order = remapped.new_sort_order
  from remapped
  where i.id = remapped.id
    and i.product_id = p_product_id;
end;
$$;

revoke all on function public.register_product_image(uuid, text, text) from public, anon;
revoke all on function public.set_product_image_primary(uuid, uuid) from public, anon;
revoke all on function public.move_product_image(uuid, uuid, integer) from public, anon;
grant execute on function public.register_product_image(uuid, text, text) to authenticated;
grant execute on function public.set_product_image_primary(uuid, uuid) to authenticated;
grant execute on function public.move_product_image(uuid, uuid, integer) to authenticated;
