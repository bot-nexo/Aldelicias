-- Restrict category changes to administrators while preserving business-scoped reads.
-- Categories are deactivated instead of hard-deleted to retain product references.

drop policy if exists categories_business on public.categories;
drop policy if exists categories_business_select on public.categories;
drop policy if exists categories_admin_insert on public.categories;
drop policy if exists categories_admin_update on public.categories;

create policy categories_business_select on public.categories
for select using (business_id = public.current_business_id());

create policy categories_admin_insert on public.categories
for insert with check (
  business_id = public.current_business_id()
  and public.is_admin()
);

create policy categories_admin_update on public.categories
for update using (
  business_id = public.current_business_id()
  and public.is_admin()
)
with check (
  business_id = public.current_business_id()
  and public.is_admin()
);

create or replace function public.validate_product_category_business()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.category_id is not null and not exists (
    select 1
    from public.categories c
    where c.id = new.category_id
      and c.business_id = new.business_id
      and c.is_active = true
  ) then
    raise exception 'Product category must be active and belong to the same business.';
  end if;

  return new;
end;
$$;

drop trigger if exists products_validate_category_business on public.products;
create trigger products_validate_category_business
before insert or update of category_id, business_id on public.products
for each row execute function public.validate_product_category_business();
