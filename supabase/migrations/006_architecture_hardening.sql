-- Incremental hardening. Historic migrations 001-005 remain untouched.
-- Keep payment_methods IDs because payments/expenses already reference them.
alter table public.payment_methods
  add column affects_physical_cash boolean not null default false;

update public.payment_methods
set affects_physical_cash = true
where code = 'CASH';

do $$
begin
  if exists (
    select 1
    from public.business_payment_methods legacy
    join public.payment_methods canonical
      on canonical.business_id = legacy.business_id and canonical.code = legacy.code
    where canonical.name is distinct from legacy.display_name
       or canonical.is_active is distinct from legacy.is_enabled
       or canonical.affects_physical_cash is distinct from legacy.affects_physical_cash
  ) then
    raise exception 'Payment method configuration conflict: reconcile records before applying migration 006';
  end if;
end;
$$;

insert into public.payment_methods
  (business_id, name, code, is_active, affects_physical_cash, sort_order)
select business_id, display_name, code, is_enabled, affects_physical_cash, sort_order
from public.business_payment_methods
on conflict (business_id, code) do nothing;

-- Archive rather than delete the redundant source; it is not an operative model.
alter table public.business_payment_methods rename to legacy_business_payment_methods;
revoke all on public.legacy_business_payment_methods from public, anon, authenticated;
alter table public.legacy_business_payment_methods enable row level security;
drop policy payment_methods_admin_write on public.payment_methods;
create policy payment_methods_admin_insert on public.payment_methods for insert to authenticated
  with check (business_id = public.current_business_id() and public.is_admin());
create policy payment_methods_admin_update on public.payment_methods for update to authenticated
  using (business_id = public.current_business_id() and public.is_admin())
  with check (business_id = public.current_business_id() and public.is_admin());
revoke delete, truncate on public.payment_methods from public, anon, authenticated;

-- Explicit assignments, never infer a collaborator's cash register from location.
create table public.cash_register_assignments (
  business_id uuid not null references public.businesses(id),
  user_id uuid not null references public.users(id),
  cash_register_id uuid not null references public.cash_registers(id),
  primary key (user_id, cash_register_id)
);
alter table public.cash_register_assignments enable row level security;
create policy cash_assignments_admin on public.cash_register_assignments
  for all to authenticated
  using (business_id = public.current_business_id() and public.is_admin())
  with check (business_id = public.current_business_id() and public.is_admin()
    and exists (select 1 from public.users u where u.id = cash_register_assignments.user_id and u.business_id = cash_register_assignments.business_id)
    and exists (select 1 from public.cash_registers cr where cr.id = cash_register_assignments.cash_register_id and cr.business_id = cash_register_assignments.business_id));

-- RLS is a second boundary: admin-owned tables cannot be written by collaborators.
drop policy vehicles_business on public.vehicles;
drop policy locations_business on public.locations;
drop policy categories_business on public.categories;
drop policy suppliers_business on public.suppliers;
drop policy events_business on public.events;
create policy vehicles_read on public.vehicles for select to authenticated
  using (business_id = public.current_business_id());
create policy vehicles_admin on public.vehicles for all to authenticated
  using (business_id = public.current_business_id() and public.is_admin())
  with check (business_id = public.current_business_id() and public.is_admin());
create policy locations_read on public.locations for select to authenticated
  using (business_id = public.current_business_id());
create policy locations_admin on public.locations for all to authenticated
  using (business_id = public.current_business_id() and public.is_admin())
  with check (business_id = public.current_business_id() and public.is_admin());
create policy categories_read on public.categories for select to authenticated
  using (business_id = public.current_business_id());
create policy categories_admin on public.categories for all to authenticated
  using (business_id = public.current_business_id() and public.is_admin())
  with check (business_id = public.current_business_id() and public.is_admin());
create policy suppliers_admin on public.suppliers for all to authenticated
  using (business_id = public.current_business_id() and public.is_admin())
  with check (business_id = public.current_business_id() and public.is_admin());
create policy events_admin on public.events for all to authenticated
  using (business_id = public.current_business_id() and public.is_admin())
  with check (business_id = public.current_business_id() and public.is_admin());

-- Finance/cost data is administrative, inventory reads are operational.
drop policy sales_business on public.sales;
drop policy sale_items_business on public.sale_items;
drop policy payments_business on public.payments;
drop policy expenses_business on public.expenses;
drop policy purchases_business on public.purchases;
drop policy purchase_items_business on public.purchase_items;
drop policy cash_sessions_business on public.cash_sessions;
drop policy cash_movements_business on public.cash_movements;
create policy sales_admin_read on public.sales for select to authenticated
  using (business_id = public.current_business_id() and public.is_admin());
create policy sale_items_admin_read on public.sale_items for select to authenticated
  using (public.is_admin() and exists (select 1 from public.sales s where s.id = sale_id and s.business_id = public.current_business_id()));
create policy payments_admin_read on public.payments for select to authenticated
  using (public.is_admin() and exists (select 1 from public.sales s where s.id = sale_id and s.business_id = public.current_business_id()));
create policy expenses_admin_read on public.expenses for select to authenticated
  using (business_id = public.current_business_id() and public.is_admin());
create policy purchases_admin_read on public.purchases for select to authenticated
  using (business_id = public.current_business_id() and public.is_admin());
create policy purchase_items_admin_read on public.purchase_items for select to authenticated
  using (public.is_admin() and exists (select 1 from public.purchases p where p.id = purchase_id and p.business_id = public.current_business_id()));
create policy cash_sessions_admin_read on public.cash_sessions for select to authenticated
  using (public.is_admin() and exists (select 1 from public.cash_registers cr where cr.id = cash_register_id and cr.business_id = public.current_business_id()));
create policy cash_movements_admin_read on public.cash_movements for select to authenticated
  using (public.is_admin() and exists (select 1 from public.cash_sessions cs join public.cash_registers cr on cr.id = cs.cash_register_id where cs.id = cash_session_id and cr.business_id = public.current_business_id()));

alter table public.supplier_accounts_payable enable row level security;
alter table public.supplier_payments enable row level security;
alter table public.payment_methods enable row level security;
alter table public.cost_components enable row level security;
alter table public.product_cost_components enable row level security;
alter table public.cost_component_price_history enable row level security;
create policy payables_admin on public.supplier_accounts_payable for select to authenticated
  using (business_id = public.current_business_id() and public.is_admin());
create policy supplier_payments_admin on public.supplier_payments for select to authenticated
  using (business_id = public.current_business_id() and public.is_admin());
create policy cost_components_admin on public.cost_components for all to authenticated
  using (business_id = public.current_business_id() and public.is_admin())
  with check (business_id = public.current_business_id() and public.is_admin());
create policy product_cost_components_admin on public.product_cost_components for all to authenticated
  using (business_id = public.current_business_id() and public.is_admin()
    and exists (select 1 from public.products p where p.id = product_cost_components.product_id and p.business_id = product_cost_components.business_id)
    and exists (select 1 from public.cost_components c where c.id = product_cost_components.component_id and c.business_id = product_cost_components.business_id))
  with check (business_id = public.current_business_id() and public.is_admin()
    and exists (select 1 from public.products p where p.id = product_cost_components.product_id and p.business_id = product_cost_components.business_id)
    and exists (select 1 from public.cost_components c where c.id = product_cost_components.component_id and c.business_id = product_cost_components.business_id));
create policy cost_history_admin on public.cost_component_price_history for select to authenticated
  using (business_id = public.current_business_id() and public.is_admin());

-- Initial cost baseline is recorded at migration time; historical sale snapshots
-- are not recalculated when the component price subsequently changes.
insert into public.cost_component_price_history(business_id, component_id, unit_cost, effective_from)
select c.business_id, c.id, c.unit_cost, now() from public.cost_components c
where not exists (select 1 from public.cost_component_price_history h where h.component_id = c.id);

create function public.record_component_cost_history()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or public.current_business_id() is distinct from new.business_id
     or public.is_admin() is not true or (tg_op = 'UPDATE' and new.business_id is distinct from old.business_id) then
    raise exception 'Unauthorized component cost change';
  end if;
  if tg_op = 'INSERT' or new.unit_cost is distinct from old.unit_cost then
    insert into public.cost_component_price_history(business_id, component_id, unit_cost, effective_from)
      values (new.business_id, new.id, new.unit_cost, now());
  end if;
  return new;
end;
$$;
create trigger component_cost_history after insert or update of unit_cost, business_id
  on public.cost_components for each row execute function public.record_component_cost_history();
revoke all on function public.record_component_cost_history() from public, anon, authenticated;

-- No client can directly mutate accounting/history, including by table grant.
revoke insert, update, delete, truncate on public.sales, public.sale_items, public.payments,
  public.purchases, public.purchase_items, public.inventory_movements, public.expenses,
  public.cash_sessions, public.cash_movements, public.supplier_accounts_payable,
  public.supplier_payments, public.cost_component_price_history, public.audit_logs
  from public, anon, authenticated;
revoke all on public.cash_register_assignments from public, anon;
grant select, insert, update, delete on public.cash_register_assignments to authenticated;

-- SQL views otherwise bypass table RLS via the view owner's privileges.
alter view public.v_business_daily_metrics set (security_invoker = true);

-- All existing SECURITY DEFINER entry points need explicit execution privileges.
revoke all on function public.current_business_id(), public.current_user_role(), public.is_admin(),
  public.product_indirect_unit_cost(uuid), public.seed_default_payment_methods(uuid),
  public.create_sale(uuid, uuid, jsonb, jsonb, text),
  public.create_expense(uuid, numeric, text, timestamptz, uuid, uuid, text),
  public.register_wastage(uuid, uuid, numeric, text),
  public.create_purchase_with_payment_status(uuid, uuid, uuid, jsonb, numeric, text, timestamptz, text),
  public.open_cash_session(uuid, numeric), public.close_cash_session(uuid, numeric)
  from public, anon, authenticated;
grant execute on function public.current_business_id(), public.current_user_role(), public.is_admin()
  to authenticated;

-- The old signatures lack a cash-session/payment context. Revoke them, do not
-- silently execute historical implementations with missing financial movements.
create schema app_private;
revoke all on schema app_private from public, anon, authenticated;
alter function public.create_sale(uuid, uuid, jsonb, jsonb, text)
  rename to legacy_create_sale;
alter function public.create_expense(uuid, numeric, text, timestamptz, uuid, uuid, text)
  rename to legacy_create_expense;
alter function public.create_purchase_with_payment_status(uuid, uuid, uuid, jsonb, numeric, text, timestamptz, text)
  rename to legacy_create_purchase_with_payment_status;
alter function public.legacy_create_sale(uuid, uuid, jsonb, jsonb, text)
  set schema app_private;
alter function public.legacy_create_expense(uuid, numeric, text, timestamptz, uuid, uuid, text)
  set schema app_private;
alter function public.legacy_create_purchase_with_payment_status(uuid, uuid, uuid, jsonb, numeric, text, timestamptz, text)
  set schema app_private;

create or replace function public.seed_default_payment_methods(p_business_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or public.current_business_id() is distinct from p_business_id
     or public.is_admin() is not true then
    raise exception 'Unauthorized payment method initialization';
  end if;
  insert into public.payment_methods (business_id, code, name, is_active, affects_physical_cash, sort_order)
  values (p_business_id, 'CASH', 'Efectivo', true, true, 1),
    (p_business_id, 'NEQUI', 'Nequi', true, false, 2),
    (p_business_id, 'DAVIPLATA', 'Daviplata', true, false, 3),
    (p_business_id, 'BANK_TRANSFER', 'Transferencia bancaria', true, false, 4)
  on conflict (business_id, code) do nothing;
end;
$$;
revoke all on function public.seed_default_payment_methods(uuid) from public, anon, authenticated;
grant execute on function public.seed_default_payment_methods(uuid) to authenticated;

revoke create on schema public from public, anon, authenticated;
alter default privileges in schema public revoke execute on functions from public;

create table public.role_permissions (
  role_id uuid not null references public.roles(id),
  permission text not null,
  primary key (role_id, permission)
);
alter table public.role_permissions enable row level security;
revoke all on public.role_permissions from public, anon, authenticated;
insert into public.role_permissions(role_id, permission)
select r.id, permission
from public.roles r
cross join (values
  ('SALE'), ('CASH'), ('WASTAGE'), ('INVENTORY_READ'),
  ('INVENTORY_ADMIN'), ('PURCHASE'), ('EXPENSE'), ('ADMIN_CASH'),
  ('PAYMENT_CONFIG'), ('PRODUCT'), ('CATEGORY'), ('SUPPLIER'),
  ('USER'), ('REPORT'), ('COST'), ('BUSINESS_CONFIG'), ('EVENT')
) as allowed(permission)
where r.name = 'ADMIN';
insert into public.role_permissions(role_id, permission)
select r.id, allowed.permission from public.roles r
cross join (values ('SALE'), ('CASH'), ('WASTAGE'), ('INVENTORY_READ')) as allowed(permission)
where r.name = 'COLLABORATOR';

create function public.has_permission(p_permission text)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and public.current_business_id() is not null
    and exists (
      select 1 from public.users u
      join public.role_permissions rp on rp.role_id = u.role_id
      where u.auth_user_id = auth.uid() and u.is_active
        and u.business_id = public.current_business_id() and rp.permission = p_permission
    );
$$;
revoke all on function public.has_permission(text) from public, anon, authenticated;
grant execute on function public.has_permission(text) to authenticated;

create or replace function public.current_business_id()
returns uuid language sql stable security definer set search_path = '' as $$
  select u.business_id from public.users u
  join public.businesses b on b.id = u.business_id and b.is_active
  where auth.uid() is not null and u.auth_user_id = auth.uid() and u.is_active
  limit 1;
$$;
create or replace function public.current_user_role()
returns public.user_role language sql stable security definer set search_path = '' as $$
  select r.name from public.users u
  join public.businesses b on b.id = u.business_id and b.is_active
  join public.roles r on r.id = u.role_id
  where auth.uid() is not null and u.auth_user_id = auth.uid() and u.is_active
  limit 1;
$$;
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and public.current_business_id() is not null
    and public.current_user_role() = 'ADMIN'::public.user_role;
$$;

create function app_private.actor(p_business_id uuid, p_operation text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  actor_id uuid;
begin
  if auth.uid() is null or p_business_id is null then
    raise exception 'Unauthorized operation';
  end if;
  select u.id into actor_id
  from public.users u
  join public.businesses b on b.id = u.business_id and b.is_active
  where u.auth_user_id = auth.uid() and u.business_id = p_business_id and u.is_active;
  if actor_id is null or public.has_permission(p_operation) is not true then
    raise exception 'Unauthorized operation';
  end if;
  return actor_id;
end;
$$;

create function app_private.open_session(p_session_id uuid, p_business_id uuid, p_actor_id uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  session_id uuid;
begin
  if auth.uid() is null or p_session_id is null
     or app_private.actor(p_business_id, 'CASH') is distinct from p_actor_id then
    raise exception 'Unauthorized cash session';
  end if;
  select cs.id into session_id
  from public.cash_sessions cs
  join public.cash_registers cr on cr.id = cs.cash_register_id
  where cs.id = p_session_id and cs.status = 'OPEN'
    and cr.business_id = p_business_id and cr.is_active
    and (public.is_admin() or exists (
      select 1 from public.cash_register_assignments ca
      where ca.user_id = p_actor_id and ca.cash_register_id = cr.id
        and ca.business_id = p_business_id))
  for update of cs;
  if session_id is null then raise exception 'Open assigned cash session required'; end if;
  return session_id;
end;
$$;

-- A single open session per register, also enforced under concurrent openings.
create unique index cash_sessions_one_open_per_register
  on public.cash_sessions(cash_register_id) where status = 'OPEN';
alter type public.cash_movement_type add value if not exists 'PURCHASE';

create or replace function public.open_cash_session(p_cash_register_id uuid, p_opening_amount numeric)
returns uuid language plpgsql security definer set search_path = '' as $$
#variable_conflict use_variable
declare
  business_id uuid := public.current_business_id();
  actor_id uuid;
  session_id uuid;
begin
  actor_id := app_private.actor(business_id, 'CASH');
  if p_opening_amount is null or p_opening_amount < 0 then raise exception 'Invalid opening amount'; end if;
  if not exists (
    select 1 from public.cash_registers cr where cr.id = p_cash_register_id
      and cr.business_id = business_id and cr.is_active
      and (public.is_admin() or exists (
        select 1 from public.cash_register_assignments ca
        where ca.cash_register_id = cr.id and ca.user_id = actor_id and ca.business_id = business_id))
  ) then raise exception 'Cash register not assigned to user'; end if;
  insert into public.cash_sessions(cash_register_id, opened_by, opening_amount)
    values (p_cash_register_id, actor_id, p_opening_amount) returning id into session_id;
  if p_opening_amount > 0 then
    insert into public.cash_movements(cash_session_id, movement_type, amount, created_by, payment_method_code)
      values (session_id, 'OPENING', p_opening_amount, actor_id, 'CASH');
  end if;
  insert into public.audit_logs(business_id, user_id, action, entity_type, entity_id)
    values (business_id, actor_id, 'OPEN_CASH', 'CASH_SESSION', session_id);
  return session_id;
end;
$$;

create or replace function public.close_cash_session(p_cash_session_id uuid, p_counted_amount numeric)
returns jsonb language plpgsql security definer set search_path = '' as $$
#variable_conflict use_variable
declare
  business_id uuid := public.current_business_id();
  actor_id uuid;
  expected numeric(12,2);
  difference numeric(12,2);
begin
  actor_id := app_private.actor(business_id, 'CASH');
  perform app_private.open_session(p_cash_session_id, business_id, actor_id);
  if p_counted_amount is null or p_counted_amount < 0 then raise exception 'Invalid counted amount'; end if;
  select coalesce(sum(cm.amount), 0) into expected
  from public.cash_movements cm
  where cm.cash_session_id = p_cash_session_id and cm.movement_type <> 'CLOSING';
  difference := p_counted_amount - expected;
  update public.cash_sessions set closed_by = actor_id, closed_at = now(),
    expected_amount = expected, counted_amount = p_counted_amount,
    difference = difference, status = 'CLOSED'
  where id = p_cash_session_id;
  insert into public.cash_movements(cash_session_id, movement_type, amount, created_by, payment_method_code)
    values (p_cash_session_id, 'CLOSING', p_counted_amount, actor_id, 'CASH');
  insert into public.audit_logs(business_id, user_id, action, entity_type, entity_id, new_values)
    values (business_id, actor_id, 'CLOSE_CASH', 'CASH_SESSION', p_cash_session_id,
      pg_catalog.jsonb_build_object('expected', expected, 'counted', p_counted_amount, 'difference', difference));
  return pg_catalog.jsonb_build_object('expected_amount', expected, 'counted_amount', p_counted_amount, 'difference', difference);
end;
$$;

create or replace function public.register_wastage(p_product_id uuid, p_location_id uuid, p_quantity numeric, p_reason text)
returns uuid language plpgsql security definer set search_path = '' as $$
#variable_conflict use_variable
declare
  business_id uuid := public.current_business_id();
  actor_id uuid;
  unit_cost numeric(12,2);
  available numeric(12,3);
  movement_id uuid;
begin
  actor_id := app_private.actor(business_id, 'WASTAGE');
  if p_quantity is null or p_quantity <= 0 or nullif(pg_catalog.btrim(p_reason), '') is null then
    raise exception 'Invalid wastage';
  end if;
  if not exists (select 1 from public.locations l where l.id = p_location_id and l.business_id = business_id and l.is_active) then
    raise exception 'Invalid location';
  end if;
  select coalesce(p.cost_price, 0) into unit_cost from public.products p
    where p.id = p_product_id and p.business_id = business_id and p.track_inventory for update;
  if not found then raise exception 'Invalid product'; end if;
  select coalesce(sum(m.quantity), 0) into available from public.inventory_movements m
    where m.business_id = business_id and m.product_id = p_product_id and m.location_id = p_location_id;
  if available < p_quantity then raise exception 'Insufficient stock'; end if;
  insert into public.inventory_movements(business_id, product_id, location_id, movement_type,
    quantity, unit_cost, total_cost, reason, created_by)
  values (business_id, p_product_id, p_location_id, 'WASTAGE', -p_quantity,
    unit_cost, unit_cost * p_quantity, p_reason, actor_id) returning id into movement_id;
  insert into public.audit_logs(business_id, user_id, action, entity_type, entity_id)
    values (business_id, actor_id, 'REGISTER_WASTAGE', 'INVENTORY_MOVEMENT', movement_id);
  return movement_id;
end;
$$;

create or replace function public.product_indirect_unit_cost(p_product_id uuid)
returns numeric language plpgsql stable security definer set search_path = '' as $$
declare
  unit_cost numeric;
begin
  if auth.uid() is null or public.current_business_id() is null or not exists (
    select 1 from public.products p where p.id = p_product_id and p.business_id = public.current_business_id()
  ) then raise exception 'Unauthorized product cost'; end if;
  select coalesce(sum(pcc.quantity * cc.unit_cost), 0) into unit_cost
  from public.product_cost_components pcc
  join public.cost_components cc on cc.id = pcc.component_id
  where pcc.product_id = p_product_id and pcc.business_id = public.current_business_id()
    and cc.business_id = pcc.business_id and cc.is_active;
  return unit_cost;
end;
$$;

revoke all on function public.open_cash_session(uuid, numeric),
  public.close_cash_session(uuid, numeric), public.register_wastage(uuid, uuid, numeric, text),
  public.product_indirect_unit_cost(uuid) from public, anon, authenticated;
grant execute on function public.open_cash_session(uuid, numeric),
  public.close_cash_session(uuid, numeric), public.register_wastage(uuid, uuid, numeric, text)
  to authenticated;

create table public.business_counters (
  business_id uuid not null references public.businesses(id),
  kind text not null check (kind in ('SALE', 'PURCHASE')),
  last_value bigint not null check (last_value >= 0),
  primary key (business_id, kind)
);
alter table public.business_counters enable row level security;
revoke all on public.business_counters from public, anon, authenticated;
insert into public.business_counters(business_id, kind, last_value)
select business_id, 'SALE', coalesce(max(substring(sale_number from '^V-([0-9]+)$')::bigint), 0)
from public.sales group by business_id;
insert into public.business_counters(business_id, kind, last_value)
select business_id, 'PURCHASE', coalesce(max(substring(purchase_number from '^C-([0-9]+)$')::bigint), 0)
from public.purchases group by business_id;

create function app_private.next_number(p_business_id uuid, p_kind text)
returns text language plpgsql security definer set search_path = '' as $$
declare
  next_value bigint;
begin
  if auth.uid() is null or p_kind not in ('SALE', 'PURCHASE') then raise exception 'Invalid counter'; end if;
  perform app_private.actor(p_business_id, case when p_kind = 'SALE' then 'SALE' else 'PURCHASE' end);
  insert into public.business_counters(business_id, kind, last_value)
    values (p_business_id, p_kind, 1)
  on conflict (business_id, kind) do update
    set last_value = public.business_counters.last_value + 1
  returning last_value into next_value;
  return (case when p_kind = 'SALE' then 'V-' else 'C-' end)
    || pg_catalog.lpad(next_value::text, 8, '0');
end;
$$;

-- New signature requires cash session when an accepted payment affects physical cash.
create function public.create_sale(
  p_vehicle_id uuid, p_location_id uuid, p_items jsonb, p_payments jsonb,
  p_cash_session_id uuid, p_notes text default null
)
returns uuid language plpgsql security definer set search_path = '' as $$
#variable_conflict use_variable
declare
  business_id uuid := public.current_business_id();
  actor_id uuid;
  sale_id uuid;
  sale_number text;
  item jsonb;
  payment jsonb;
  product public.products%rowtype;
  quantity numeric(12,3);
  available numeric(12,3);
  indirect_unit numeric(12,4);
  indirect_total numeric(12,2) := 0;
  direct_total numeric(12,2) := 0;
  sale_total numeric(12,2) := 0;
  payment_total numeric(12,2) := 0;
  method public.payment_methods%rowtype;
  payment_id uuid;
begin
  actor_id := app_private.actor(business_id, 'SALE');
  if not exists (select 1 from public.locations l where l.id = p_location_id and l.business_id = business_id and l.is_active
    and (p_vehicle_id is null or l.vehicle_id is null or l.vehicle_id = p_vehicle_id))
    or (p_vehicle_id is not null and not exists (select 1 from public.vehicles v
      where v.id = p_vehicle_id and v.business_id = business_id and v.is_active)) then
    raise exception 'Invalid sale location or vehicle';
  end if;
  if pg_catalog.jsonb_typeof(p_items) is distinct from 'array' or pg_catalog.jsonb_array_length(p_items) = 0
     or pg_catalog.jsonb_typeof(p_payments) is distinct from 'array' or pg_catalog.jsonb_array_length(p_payments) = 0 then
    raise exception 'Sale requires items and payments';
  end if;
  sale_number := app_private.next_number(business_id, 'SALE');
  insert into public.sales(business_id, sale_number, user_id, vehicle_id, location_id, status, notes)
    values (business_id, sale_number, actor_id, p_vehicle_id, p_location_id, 'COMPLETED', p_notes)
    returning id into sale_id;
  for item in select value from pg_catalog.jsonb_array_elements(p_items) as entries(value) loop
    if pg_catalog.jsonb_typeof(item) <> 'object' then raise exception 'Invalid sale item'; end if;
    select * into product from public.products p
      where p.id = (item->>'product_id')::uuid and p.business_id = business_id
        and p.status = 'PUBLISHED' for update;
    if not found then raise exception 'Product unavailable for sale'; end if;
    quantity := (item->>'quantity')::numeric;
    if quantity is null or quantity <= 0 then raise exception 'Invalid sale quantity'; end if;
    if product.track_inventory then
      select coalesce(sum(m.quantity), 0) into available from public.inventory_movements m
        where m.business_id = business_id and m.product_id = product.id and m.location_id = p_location_id;
      if available < quantity then raise exception 'Insufficient stock'; end if;
    end if;
    indirect_unit := public.product_indirect_unit_cost(product.id);
    insert into public.sale_items(sale_id, product_id, product_name_snapshot,
      quantity, unit_price, unit_cost, subtotal, cost_total, indirect_cost_per_unit,
      indirect_cost_total, full_cost_total)
    values (sale_id, product.id, product.name, quantity, product.sale_price,
      coalesce(product.cost_price, 0), product.sale_price * quantity,
      coalesce(product.cost_price, 0) * quantity, indirect_unit,
      round(indirect_unit * quantity, 2),
      coalesce(product.cost_price, 0) * quantity + round(indirect_unit * quantity, 2));
    sale_total := sale_total + product.sale_price * quantity;
    direct_total := direct_total + coalesce(product.cost_price, 0) * quantity;
    indirect_total := indirect_total + round(indirect_unit * quantity, 2);
    if product.track_inventory then
      insert into public.inventory_movements(business_id, product_id, location_id,
        movement_type, quantity, unit_cost, total_cost, reference_type, reference_id, created_by)
      values (business_id, product.id, p_location_id, 'SALE', -quantity,
        coalesce(product.cost_price, 0), coalesce(product.cost_price, 0) * quantity,
        'SALE', sale_id, actor_id);
    end if;
  end loop;
  for payment in select value from pg_catalog.jsonb_array_elements(p_payments) as entries(value) loop
    if pg_catalog.jsonb_typeof(payment) <> 'object' then raise exception 'Invalid payment'; end if;
    select * into method from public.payment_methods pm
      where pm.id = (payment->>'payment_method_id')::uuid
        and pm.business_id = business_id and pm.is_active;
    if not found then raise exception 'Payment method unavailable'; end if;
    if (payment->>'amount')::numeric is null or (payment->>'amount')::numeric <= 0 then
      raise exception 'Invalid payment amount';
    end if;
    insert into public.payments(sale_id, payment_method_id, amount)
      values (sale_id, method.id, (payment->>'amount')::numeric) returning id into payment_id;
    payment_total := payment_total + (payment->>'amount')::numeric;
    if method.affects_physical_cash then
      perform app_private.open_session(p_cash_session_id, business_id, actor_id);
      insert into public.cash_movements(cash_session_id, movement_type, amount,
        reference_type, reference_id, created_by, payment_method_code)
      values (p_cash_session_id, 'SALE', (payment->>'amount')::numeric,
        'PAYMENT', payment_id, actor_id, method.code);
    end if;
  end loop;
  if payment_total <> sale_total then raise exception 'Payments do not equal sale total'; end if;
  update public.sales set subtotal = sale_total, total = sale_total,
    total_cost = direct_total, indirect_cost_total = indirect_total,
    gross_profit = sale_total - direct_total - indirect_total
  where id = sale_id;
  insert into public.audit_logs(business_id, user_id, action, entity_type, entity_id, new_values)
    values (business_id, actor_id, 'CREATE_SALE', 'SALE', sale_id,
      pg_catalog.jsonb_build_object('total', sale_total));
  return sale_id;
end;
$$;
revoke all on function public.create_sale(uuid, uuid, jsonb, jsonb, uuid, text)
  from public, anon, authenticated;
grant execute on function public.create_sale(uuid, uuid, jsonb, jsonb, uuid, text)
  to authenticated;

-- IMMEDIATE means paid now by any active method; CREDIT creates unpaid payable.
create function public.create_purchase_with_payment_status(
  p_supplier_id uuid, p_location_id uuid, p_vehicle_id uuid, p_items jsonb,
  p_total numeric, p_payment_mode text, p_payment_method_id uuid,
  p_cash_session_id uuid, p_due_date timestamptz default null, p_notes text default null
)
returns uuid language plpgsql security definer set search_path = '' as $$
#variable_conflict use_variable
declare
  business_id uuid := public.current_business_id();
  actor_id uuid;
  purchase_id uuid;
  payable_id uuid;
  supplier_payment_id uuid;
  item jsonb;
  product public.products%rowtype;
  method public.payment_methods%rowtype;
  computed_total numeric(12,2) := 0;
  quantity numeric(12,3);
  unit_cost numeric(12,2);
begin
  actor_id := app_private.actor(business_id, 'PURCHASE');
  if p_payment_mode not in ('IMMEDIATE', 'CREDIT') or p_payment_mode is null
    or p_total is null or p_total <= 0 then raise exception 'Invalid purchase terms'; end if;
  if p_payment_mode = 'CREDIT' and (p_due_date is null or p_payment_method_id is not null) then
    raise exception 'Credit requires due date and no immediate payment method';
  end if;
  if p_payment_mode = 'IMMEDIATE' then
    select * into method from public.payment_methods pm
    where pm.id = p_payment_method_id and pm.business_id = business_id and pm.is_active;
    if not found then raise exception 'Active payment method required'; end if;
    if method.affects_physical_cash then
      perform app_private.open_session(p_cash_session_id, business_id, actor_id);
    end if;
  end if;
  if not exists (select 1 from public.suppliers s where s.id = p_supplier_id and s.business_id = business_id and s.is_active)
    or not exists (select 1 from public.locations l where l.id = p_location_id and l.business_id = business_id and l.is_active
      and (p_vehicle_id is null or l.vehicle_id is null or l.vehicle_id = p_vehicle_id))
    or (p_vehicle_id is not null and not exists (select 1 from public.vehicles v where v.id = p_vehicle_id and v.business_id = business_id and v.is_active))
    or pg_catalog.jsonb_typeof(p_items) is distinct from 'array' or pg_catalog.jsonb_array_length(p_items) = 0 then
    raise exception 'Invalid purchase supplier, location or items';
  end if;
  insert into public.purchases(business_id, supplier_id, location_id, vehicle_id,
    purchase_number, subtotal, total, status, notes, created_by)
  values (business_id, p_supplier_id, p_location_id, p_vehicle_id,
    app_private.next_number(business_id, 'PURCHASE'), p_total, p_total,
    'CONFIRMED', p_notes, actor_id) returning id into purchase_id;
  for item in select value from pg_catalog.jsonb_array_elements(p_items) as entries(value) loop
    if pg_catalog.jsonb_typeof(item) <> 'object' then raise exception 'Invalid purchase item'; end if;
    select * into product from public.products p where p.id = (item->>'product_id')::uuid
      and p.business_id = business_id for update;
    if not found then raise exception 'Invalid purchase product'; end if;
    quantity := (item->>'quantity')::numeric;
    unit_cost := (item->>'unit_cost')::numeric;
    if quantity is null or quantity <= 0 or unit_cost is null or unit_cost < 0 then
      raise exception 'Invalid quantity or cost';
    end if;
    computed_total := computed_total + quantity * unit_cost;
    insert into public.purchase_items(purchase_id, product_id, product_name_snapshot,
      quantity, unit_cost, subtotal) values (purchase_id, product.id, product.name,
      quantity, unit_cost, quantity * unit_cost);
    insert into public.inventory_movements(business_id, product_id, location_id,
      movement_type, quantity, unit_cost, total_cost, reference_type, reference_id, created_by)
    values (business_id, product.id, p_location_id, 'PURCHASE', quantity,
      unit_cost, quantity * unit_cost, 'PURCHASE', purchase_id, actor_id);
    update public.products set cost_price = unit_cost, updated_at = now() where id = product.id;
  end loop;
  if computed_total <> p_total then raise exception 'Purchase total does not match items'; end if;
  insert into public.supplier_accounts_payable(business_id, supplier_id, purchase_id,
    original_amount, paid_amount, status, due_date)
  values (business_id, p_supplier_id, purchase_id, p_total,
    case when p_payment_mode = 'IMMEDIATE' then p_total else 0 end,
    case when p_payment_mode = 'IMMEDIATE' then 'PAID'::public.purchase_payment_status else 'UNPAID'::public.purchase_payment_status end,
    p_due_date) returning id into payable_id;
  if p_payment_mode = 'IMMEDIATE' then
    insert into public.supplier_payments(business_id, payable_id, amount,
      payment_method, cash_session_id, created_by)
    values (business_id, payable_id, p_total,
      case when method.code in ('CASH','NEQUI','DAVIPLATA','BANK_TRANSFER')
        then method.code::public.supplier_payment_method else null end,
      case when method.affects_physical_cash then p_cash_session_id else null end, actor_id)
    returning id into supplier_payment_id;
    if method.affects_physical_cash then
      insert into public.cash_movements(cash_session_id, movement_type, amount,
        reference_type, reference_id, created_by, payment_method_code)
      values (p_cash_session_id, 'PURCHASE', -p_total, 'SUPPLIER_PAYMENT',
        supplier_payment_id, actor_id, method.code);
    end if;
  end if;
  insert into public.audit_logs(business_id, user_id, action, entity_type, entity_id, new_values)
    values (business_id, actor_id, 'CREATE_PURCHASE', 'PURCHASE', purchase_id,
      pg_catalog.jsonb_build_object('total', p_total, 'mode', p_payment_mode));
  return purchase_id;
end;
$$;
revoke all on function public.create_purchase_with_payment_status(uuid, uuid, uuid, jsonb, numeric, text, uuid, uuid, timestamptz, text)
  from public, anon, authenticated;
grant execute on function public.create_purchase_with_payment_status(uuid, uuid, uuid, jsonb, numeric, text, uuid, uuid, timestamptz, text)
  to authenticated;

create function public.create_expense(
  p_category_id uuid, p_amount numeric, p_description text, p_payment_method_id uuid,
  p_cash_session_id uuid, p_expense_date timestamptz default now(),
  p_vehicle_id uuid default null, p_notes text default null
)
returns uuid language plpgsql security definer set search_path = '' as $$
#variable_conflict use_variable
declare
  business_id uuid := public.current_business_id();
  actor_id uuid;
  expense_id uuid;
  method public.payment_methods%rowtype;
begin
  actor_id := app_private.actor(business_id, 'EXPENSE');
  if p_amount is null or p_amount <= 0 or nullif(pg_catalog.btrim(p_description), '') is null then
    raise exception 'Invalid expense'; end if;
  if not exists (select 1 from public.expense_categories c where c.id = p_category_id
      and c.business_id = business_id and c.is_active)
    or (p_vehicle_id is not null and not exists (select 1 from public.vehicles v
      where v.id = p_vehicle_id and v.business_id = business_id and v.is_active)) then
    raise exception 'Invalid expense category or vehicle'; end if;
  select * into method from public.payment_methods pm
    where pm.id = p_payment_method_id and pm.business_id = business_id and pm.is_active;
  if not found then raise exception 'Active payment method required'; end if;
  if method.affects_physical_cash then
    perform app_private.open_session(p_cash_session_id, business_id, actor_id);
  end if;
  insert into public.expenses(business_id, category_id, vehicle_id, user_id,
    description, amount, expense_date, payment_method_id, notes, affects_physical_cash)
  values (business_id, p_category_id, p_vehicle_id, actor_id, p_description,
    p_amount, p_expense_date, method.id, p_notes, method.affects_physical_cash)
  returning id into expense_id;
  if method.affects_physical_cash then
    insert into public.cash_movements(cash_session_id, movement_type, amount,
      reference_type, reference_id, created_by, payment_method_code)
    values (p_cash_session_id, 'EXPENSE', -p_amount, 'EXPENSE', expense_id, actor_id, method.code);
  end if;
  insert into public.audit_logs(business_id, user_id, action, entity_type, entity_id, new_values)
    values (business_id, actor_id, 'CREATE_EXPENSE', 'EXPENSE', expense_id,
      pg_catalog.jsonb_build_object('amount', p_amount, 'payment_method', method.code));
  return expense_id;
end;
$$;
revoke all on function public.create_expense(uuid, numeric, text, uuid, uuid, timestamptz, uuid, text)
  from public, anon, authenticated;
grant execute on function public.create_expense(uuid, numeric, text, uuid, uuid, timestamptz, uuid, text)
  to authenticated;

alter table public.supplier_payments add column payment_method_id uuid references public.payment_methods(id);
alter table public.supplier_payments alter column payment_method drop not null;
update public.supplier_payments sp set payment_method_id = pm.id
from public.payment_methods pm
where pm.business_id = sp.business_id and pm.code = sp.payment_method::text;

create function public.register_supplier_payment(
  p_payable_id uuid, p_amount numeric, p_payment_method_id uuid, p_cash_session_id uuid default null
)
returns uuid language plpgsql security definer set search_path = '' as $$
#variable_conflict use_variable
declare
  business_id uuid := public.current_business_id();
  actor_id uuid;
  payable public.supplier_accounts_payable%rowtype;
  method public.payment_methods%rowtype;
  payment_id uuid;
begin
  actor_id := app_private.actor(business_id, 'PURCHASE');
  select * into payable from public.supplier_accounts_payable ap
    where ap.id = p_payable_id and ap.business_id = business_id for update;
  if not found or p_amount is null or p_amount <= 0 or p_amount > payable.outstanding_amount then
    raise exception 'Invalid supplier payment amount or payable';
  end if;
  select * into method from public.payment_methods pm
    where pm.id = p_payment_method_id and pm.business_id = business_id and pm.is_active;
  if not found then raise exception 'Active payment method required'; end if;
  if method.affects_physical_cash then
    perform app_private.open_session(p_cash_session_id, business_id, actor_id);
  end if;
  insert into public.supplier_payments(business_id, payable_id, amount, payment_method,
    payment_method_id, cash_session_id, created_by)
  values (business_id, payable.id, p_amount,
    case when method.code in ('CASH','NEQUI','DAVIPLATA','BANK_TRANSFER')
      then method.code::public.supplier_payment_method else null end,
    method.id, case when method.affects_physical_cash then p_cash_session_id else null end, actor_id)
  returning id into payment_id;
  update public.supplier_accounts_payable set paid_amount = paid_amount + p_amount,
    status = case when paid_amount + p_amount = original_amount then 'PAID'::public.purchase_payment_status
      else 'PARTIAL'::public.purchase_payment_status end, updated_at = now()
  where id = payable.id;
  if method.affects_physical_cash then
    insert into public.cash_movements(cash_session_id, movement_type, amount,
      reference_type, reference_id, created_by, payment_method_code)
    values (p_cash_session_id, 'PURCHASE', -p_amount,
      'SUPPLIER_PAYMENT', payment_id, actor_id, method.code);
  end if;
  insert into public.audit_logs(business_id, user_id, action, entity_type, entity_id, new_values)
    values (business_id, actor_id, 'REGISTER_SUPPLIER_PAYMENT', 'SUPPLIER_PAYMENT', payment_id,
      pg_catalog.jsonb_build_object('amount', p_amount, 'method', method.code));
  return payment_id;
end;
$$;
revoke all on function public.register_supplier_payment(uuid, numeric, uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.register_supplier_payment(uuid, numeric, uuid, uuid)
  to authenticated;

create function public.record_cash_transfer(
  p_cash_session_id uuid, p_amount numeric, p_movement_type public.cash_movement_type, p_description text
)
returns uuid language plpgsql security definer set search_path = '' as $$
#variable_conflict use_variable
declare
  business_id uuid := public.current_business_id();
  actor_id uuid;
  movement_id uuid;
begin
  actor_id := app_private.actor(business_id, 'ADMIN_CASH');
  if p_movement_type not in ('DEPOSIT', 'WITHDRAWAL') or p_amount is null
     or p_amount <= 0 or nullif(pg_catalog.btrim(p_description), '') is null then
    raise exception 'Invalid cash deposit or withdrawal';
  end if;
  perform app_private.open_session(p_cash_session_id, business_id, actor_id);
  insert into public.cash_movements(cash_session_id, movement_type, amount,
    description, created_by, payment_method_code)
  values (p_cash_session_id, p_movement_type,
    case when p_movement_type = 'DEPOSIT' then p_amount else -p_amount end,
    p_description, actor_id, 'CASH') returning id into movement_id;
  insert into public.audit_logs(business_id, user_id, action, entity_type, entity_id, new_values)
    values (business_id, actor_id, p_movement_type::text, 'CASH_MOVEMENT', movement_id,
      pg_catalog.jsonb_build_object('amount', p_amount));
  return movement_id;
end;
$$;
revoke all on function public.record_cash_transfer(uuid, numeric, public.cash_movement_type, text)
  from public, anon, authenticated;
grant execute on function public.record_cash_transfer(uuid, numeric, public.cash_movement_type, text)
  to authenticated;

-- Operational read models intentionally omit unit costs and supplier/financial data.
drop policy products_business_select on public.products;
drop policy inventory_business on public.inventory_movements;
create policy products_admin_read on public.products for select to authenticated
  using (business_id = public.current_business_id() and public.is_admin());
create policy inventory_admin_read on public.inventory_movements for select to authenticated
  using (business_id = public.current_business_id() and public.is_admin());
create view public.v_operational_stock as
select p.id as product_id, p.name, p.slug, p.status, p.sale_price,
  l.id as location_id, coalesce(sum(m.quantity), 0) as quantity
from public.products p
join public.locations l on l.business_id = p.business_id and l.is_active
left join public.inventory_movements m on m.product_id = p.id and m.business_id = p.business_id
  and m.location_id = l.id
where p.business_id = public.current_business_id()
  and p.status in ('PUBLISHED', 'OUT_OF_STOCK')
  and public.has_permission('INVENTORY_READ')
group by p.id, p.name, p.slug, p.status, p.sale_price, l.id;
revoke all on public.v_operational_stock from public, anon, authenticated;
grant select on public.v_operational_stock to authenticated;
