-- AlDelicias — 002_rls_and_security.sql
-- Supabase RLS foundation.
-- Requiere que public.users.auth_user_id coincida con auth.uid().

alter table public.businesses enable row level security;
alter table public.roles enable row level security;
alter table public.users enable row level security;
alter table public.vehicles enable row level security;
alter table public.locations enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.suppliers enable row level security;
alter table public.payment_methods enable row level security;
alter table public.expense_categories enable row level security;
alter table public.wastage_reasons enable row level security;
alter table public.purchases enable row level security;
alter table public.purchase_items enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.payments enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.expenses enable row level security;
alter table public.cash_registers enable row level security;
alter table public.cash_sessions enable row level security;
alter table public.cash_movements enable row level security;
alter table public.events enable row level security;
alter table public.audit_logs enable row level security;

create or replace function public.current_business_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select business_id
  from public.users
  where auth_user_id = auth.uid()
    and is_active = true
  limit 1;
$$;

create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select r.name
  from public.users u
  join public.roles r on r.id = u.role_id
  where u.auth_user_id = auth.uid()
    and u.is_active = true
  limit 1;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_user_role() = 'ADMIN';
$$;

-- Business-scoped policies.
create policy business_select_own on public.businesses
for select using (id = public.current_business_id());

create policy users_select_same_business on public.users
for select using (business_id = public.current_business_id());

create policy users_admin_write on public.users
for all using (business_id = public.current_business_id() and public.is_admin())
with check (business_id = public.current_business_id() and public.is_admin());

create policy roles_select_authenticated on public.roles
for select using (true);

create policy vehicles_business on public.vehicles
for all using (business_id = public.current_business_id())
with check (business_id = public.current_business_id());

create policy locations_business on public.locations
for all using (business_id = public.current_business_id())
with check (business_id = public.current_business_id());

create policy categories_business on public.categories
for all using (business_id = public.current_business_id())
with check (business_id = public.current_business_id());

create policy products_business_select on public.products
for select using (business_id = public.current_business_id());

create policy products_admin_write on public.products
for insert with check (business_id = public.current_business_id() and public.is_admin());

create policy products_admin_update on public.products
for update using (business_id = public.current_business_id() and public.is_admin())
with check (business_id = public.current_business_id() and public.is_admin());

create policy product_images_business on public.product_images
for select using (
  exists (
    select 1 from public.products p
    where p.id = product_id
      and p.business_id = public.current_business_id()
  )
);

create policy product_images_admin_write on public.product_images
for all using (
  public.is_admin() and exists (
    select 1 from public.products p
    where p.id = product_id
      and p.business_id = public.current_business_id()
  )
) with check (
  public.is_admin() and exists (
    select 1 from public.products p
    where p.id = product_id
      and p.business_id = public.current_business_id()
  )
);

create policy suppliers_business on public.suppliers
for all using (business_id = public.current_business_id())
with check (business_id = public.current_business_id());

create policy payment_methods_business on public.payment_methods
for select using (business_id = public.current_business_id());

create policy payment_methods_admin_write on public.payment_methods
for all using (business_id = public.current_business_id() and public.is_admin())
with check (business_id = public.current_business_id() and public.is_admin());

create policy expense_categories_business on public.expense_categories
for select using (business_id = public.current_business_id());

create policy expense_categories_admin_write on public.expense_categories
for all using (business_id = public.current_business_id() and public.is_admin())
with check (business_id = public.current_business_id() and public.is_admin());

create policy wastage_reasons_business on public.wastage_reasons
for select using (business_id = public.current_business_id());

create policy wastage_reasons_admin_write on public.wastage_reasons
for all using (business_id = public.current_business_id() and public.is_admin())
with check (business_id = public.current_business_id() and public.is_admin());

create policy purchases_business on public.purchases
for select using (business_id = public.current_business_id());

create policy purchase_items_business on public.purchase_items
for select using (
  exists (
    select 1 from public.purchases p
    where p.id = purchase_id and p.business_id = public.current_business_id()
  )
);

create policy sales_business on public.sales
for select using (business_id = public.current_business_id());

create policy sale_items_business on public.sale_items
for select using (
  exists (
    select 1 from public.sales s
    where s.id = sale_id and s.business_id = public.current_business_id()
  )
);

create policy payments_business on public.payments
for select using (
  exists (
    select 1 from public.sales s
    where s.id = sale_id and s.business_id = public.current_business_id()
  )
);

create policy inventory_business on public.inventory_movements
for select using (business_id = public.current_business_id());

create policy expenses_business on public.expenses
for select using (business_id = public.current_business_id());

create policy cash_registers_business on public.cash_registers
for select using (business_id = public.current_business_id());

create policy cash_sessions_business on public.cash_sessions
for select using (
  exists (
    select 1 from public.cash_registers cr
    where cr.id = cash_register_id
      and cr.business_id = public.current_business_id()
  )
);

create policy cash_movements_business on public.cash_movements
for select using (
  exists (
    select 1
    from public.cash_sessions cs
    join public.cash_registers cr on cr.id = cs.cash_register_id
    where cs.id = cash_session_id
      and cr.business_id = public.current_business_id()
  )
);

create policy events_business on public.events
for all using (business_id = public.current_business_id())
with check (business_id = public.current_business_id());

create policy audit_business on public.audit_logs
for select using (business_id = public.current_business_id());

-- Mutations financieras/inventario deben pasar por funciones RPC
-- SECURITY DEFINER controladas; no se conceden INSERT/UPDATE directos
-- al cliente sobre tablas críticas.
