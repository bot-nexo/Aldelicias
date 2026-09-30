-- Run after migrations 006, 007, and 008 in an isolated PostgreSQL database.
-- Verifies the legacy administrative FOR ALL policy is gone and the scoped policies remain.
do $$
begin
  if exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'categories'
      and cmd = 'ALL'
      and coalesce(qual, '') ilike '%is_admin%'
  ) then
    raise exception 'An administrative FOR ALL policy still allows DELETE on public.categories';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'categories'
      and policyname = 'categories_admin_insert'
      and cmd = 'INSERT'
  ) then
    raise exception 'categories_admin_insert is missing';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'categories'
      and policyname = 'categories_admin_update'
      and cmd = 'UPDATE'
  ) then
    raise exception 'categories_admin_update is missing';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'categories'
      and policyname = 'categories_business_select'
      and cmd = 'SELECT'
  ) then
    raise exception 'categories_business_select is missing';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'categories'
      and policyname = 'categories_read'
      and cmd = 'SELECT'
  ) then
    raise exception 'categories_read is missing';
  end if;
end;
$$;
