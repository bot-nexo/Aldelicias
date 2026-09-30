-- Run after migration 009 in an isolated Supabase/PostgreSQL database.
do $$
begin
  if not exists (
    select 1
    from storage.buckets
    where id = 'product-images'
      and name = 'product-images'
      and public = true
      and file_size_limit >= 5242880
      and allowed_mime_types @> array['image/jpeg', 'image/png', 'image/webp']::text[]
  ) then
    raise exception 'Product image bucket configuration is missing or incompatible';
  end if;

  if exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in (
        'product_image_storage_select_admin',
        'product_image_storage_insert_admin',
        'product_image_storage_delete_admin',
        'product_image_storage_insert_scope',
        'product_image_storage_update_scope',
        'product_image_storage_delete_scope'
      )
      and (
        not ('authenticated' = any(roles) or 'public' = any(roles))
        or coalesce(qual, with_check, '') not ilike '%is_admin%'
        or coalesce(qual, with_check, '') not ilike '%current_business_id%'
        or coalesce(qual, with_check, '') not ilike '%products%'
      )
  ) then
    raise exception 'Product image Storage policies are not admin- and business-scoped';
  end if;

  if (
    select count(*)
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in (
        'product_image_storage_select_admin',
        'product_image_storage_insert_admin',
        'product_image_storage_delete_admin',
        'product_image_storage_insert_scope',
        'product_image_storage_update_scope',
        'product_image_storage_delete_scope'
      )
  ) <> 6 then
    raise exception 'Expected product image Storage policies are missing';
  end if;

  if (
    select count(*)
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in (
        'product_image_storage_insert_scope',
        'product_image_storage_update_scope',
        'product_image_storage_delete_scope'
      )
      and permissive = 'RESTRICTIVE'
  ) <> 3 then
    raise exception 'Restrictive Storage scope policies are missing';
  end if;

  if not exists (
    select 1 from pg_indexes
    where schemaname = 'public'
      and tablename = 'product_images'
      and indexname = 'product_images_one_primary_per_product'
  ) then
    raise exception 'Unique primary product image index is missing';
  end if;

  if (
    select count(*)
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'register_product_image',
        'set_product_image_primary',
        'move_product_image'
      )
      and not p.prosecdef
  ) <> 3 then
    raise exception 'Expected invoker-secured product image functions are missing';
  end if;
end;
$$;
