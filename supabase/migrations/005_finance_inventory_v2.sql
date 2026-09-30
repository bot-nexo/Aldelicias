-- AlDelicias — 005_finance_inventory_v2.sql
-- Cierra las reglas financieras definidas por el negocio:
-- 1) Efectivo, Nequi, Daviplata y transferencia.
-- 2) Métodos configurables por ADMIN.
-- 3) Compras contado/crédito.
-- 4) Cuentas por pagar a proveedores.
-- 5) Gastos con medio de pago.
-- 6) Caja física con apertura/cierre y diferencias.
-- 7) Costos indirectos por componente/consumo.
-- 8) Utilidad estimada.

create type public.purchase_payment_status as enum (
  'UNPAID', 'PARTIAL', 'PAID'
);

create type public.supplier_payment_method as enum (
  'CASH', 'NEQUI', 'DAVIPLATA', 'BANK_TRANSFER'
);

create table public.supplier_accounts_payable (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  supplier_id uuid not null references public.suppliers(id),
  purchase_id uuid not null unique references public.purchases(id),
  original_amount numeric(12,2) not null check (original_amount > 0),
  paid_amount numeric(12,2) not null default 0 check (paid_amount >= 0),
  outstanding_amount numeric(12,2) generated always as
    (original_amount - paid_amount) stored,
  status purchase_payment_status not null default 'UNPAID',
  due_date timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (paid_amount <= original_amount)
);

create table public.supplier_payments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  payable_id uuid not null references public.supplier_accounts_payable(id),
  amount numeric(12,2) not null check (amount > 0),
  payment_method public.supplier_payment_method not null,
  cash_session_id uuid references public.cash_sessions(id),
  paid_at timestamptz not null default now(),
  created_by uuid not null references public.users(id),
  notes text
);

-- Configuración de qué medios acepta el negocio.
create table public.business_payment_methods (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  code text not null check (code in ('CASH','NEQUI','DAVIPLATA','BANK_TRANSFER')),
  display_name text not null,
  is_enabled boolean not null default true,
  affects_physical_cash boolean not null default false,
  sort_order integer not null default 0,
  unique (business_id, code)
);

-- Componentes/insumos indirectos:
-- ejemplo: bolsa, servilleta, salsa, vaso, tapa.
create table public.cost_components (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  name text not null,
  unit text not null,
  unit_cost numeric(12,4) not null default 0 check (unit_cost >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, name)
);

-- Relación producto -> componente.
create table public.product_cost_components (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  product_id uuid not null references public.products(id) on delete cascade,
  component_id uuid not null references public.cost_components(id),
  quantity numeric(12,4) not null check (quantity > 0),
  created_at timestamptz not null default now(),
  unique (product_id, component_id)
);

-- Historial de costos de componentes para no alterar retrospectivamente
-- la rentabilidad de ventas anteriores.
create table public.cost_component_price_history (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  component_id uuid not null references public.cost_components(id),
  unit_cost numeric(12,4) not null check (unit_cost >= 0),
  effective_from timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- Snapshot del costo indirecto aplicado al momento de vender.
alter table public.sale_items
  add column if not exists indirect_cost_per_unit numeric(12,4) not null default 0;

alter table public.sale_items
  add column if not exists indirect_cost_total numeric(12,2) not null default 0;

alter table public.sale_items
  add column if not exists full_cost_total numeric(12,2) not null default 0;

-- Permite guardar el costo calculado total de una venta.
alter table public.sales
  add column if not exists indirect_cost_total numeric(12,2) not null default 0;

alter table public.sales
  add column if not exists operating_expense_allocated numeric(12,2) not null default 0;

alter table public.sales
  add column if not exists estimated_net_profit numeric(12,2) not null default 0;

-- Gastos pueden afectar caja física o solamente quedar registrados.
alter table public.expenses
  add column if not exists affects_physical_cash boolean not null default false;

-- Caja: referencia explícita al método utilizado.
alter table public.cash_movements
  add column if not exists payment_method_code text;

-- Índices
create index idx_payables_business_status
  on public.supplier_accounts_payable(business_id, status);

create index idx_payables_supplier
  on public.supplier_accounts_payable(supplier_id);

create index idx_supplier_payments_payable
  on public.supplier_payments(payable_id);

create index idx_supplier_payments_business_date
  on public.supplier_payments(business_id, paid_at);

create index idx_cost_components_business
  on public.cost_components(business_id);

create index idx_product_cost_components_product
  on public.product_cost_components(product_id);

create index idx_cost_history_component_date
  on public.cost_component_price_history(component_id, effective_from);

-- Calcula costo indirecto actual de un producto.
create or replace function public.product_indirect_unit_cost(
  p_product_id uuid
)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(sum(pcc.quantity * cc.unit_cost), 0)
  from public.product_cost_components pcc
  join public.cost_components cc on cc.id = pcc.component_id
  where pcc.product_id = p_product_id
    and cc.is_active = true;
$$;

-- Configura los cuatro métodos iniciales.
create or replace function public.seed_default_payment_methods(
  p_business_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.business_payment_methods
    (business_id, code, display_name, is_enabled, affects_physical_cash, sort_order)
  values
    (p_business_id, 'CASH', 'Efectivo', true, true, 1),
    (p_business_id, 'NEQUI', 'Nequi', true, false, 2),
    (p_business_id, 'DAVIPLATA', 'Daviplata', true, false, 3),
    (p_business_id, 'BANK_TRANSFER', 'Transferencia bancaria', true, false, 4)
  on conflict (business_id, code) do nothing;
end;
$$;

-- Registra una compra y crea automáticamente la cuenta por pagar.
-- El frontend deberá llamar esta RPC en lugar de escribir tablas críticas.
create or replace function public.create_purchase_with_payment_status(
  p_supplier_id uuid,
  p_location_id uuid,
  p_vehicle_id uuid,
  p_items jsonb,
  p_total numeric,
  p_payment_mode text, -- CASH / CREDIT
  p_due_date timestamptz default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid := public.current_business_id();
  v_user_id uuid;
  v_purchase_id uuid;
  v_purchase_number text;
  v_item jsonb;
  v_product public.products%rowtype;
  v_qty numeric(12,3);
  v_unit_cost numeric(12,2);
  v_calc_total numeric(12,2) := 0;
  v_status public.purchase_payment_status;
begin
  select id into v_user_id
  from public.users
  where auth_user_id = auth.uid() and is_active = true
  limit 1;

  if v_business_id is null or v_user_id is null then
    raise exception 'Usuario no autorizado';
  end if;

  if p_payment_mode not in ('CASH','CREDIT') then
    raise exception 'Modo de pago de compra inválido';
  end if;

  if p_payment_mode = 'CREDIT' and p_due_date is null then
    raise exception 'Una compra a crédito requiere fecha de vencimiento';
  end if;

  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'La compra requiere productos';
  end if;

  select 'C-' || lpad((coalesce(max(regexp_replace(purchase_number, '\D', '', 'g')::bigint), 0) + 1)::text, 8, '0')
  into v_purchase_number
  from public.purchases
  where business_id = v_business_id;

  insert into public.purchases (
    business_id, supplier_id, location_id, vehicle_id,
    purchase_number, purchase_date, subtotal, total,
    status, notes, created_by
  )
  values (
    v_business_id, p_supplier_id, p_location_id, p_vehicle_id,
    v_purchase_number, now(), p_total, p_total,
    'CONFIRMED', p_notes, v_user_id
  )
  returning id into v_purchase_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    select * into v_product
    from public.products
    where id = (v_item->>'product_id')::uuid
      and business_id = v_business_id
    for update;

    if not found then
      raise exception 'Producto no válido en compra';
    end if;

    v_qty := (v_item->>'quantity')::numeric;
    v_unit_cost := (v_item->>'unit_cost')::numeric;

    if v_qty <= 0 or v_unit_cost < 0 then
      raise exception 'Cantidad/costo inválido en compra';
    end if;

    insert into public.purchase_items (
      purchase_id, product_id, product_name_snapshot,
      quantity, unit_cost, subtotal
    )
    values (
      v_purchase_id, v_product.id, v_product.name,
      v_qty, v_unit_cost, v_qty * v_unit_cost
    );

    v_calc_total := v_calc_total + (v_qty * v_unit_cost);

    insert into public.inventory_movements (
      business_id, product_id, location_id, movement_type,
      quantity, unit_cost, total_cost,
      reference_type, reference_id, created_by
    )
    values (
      v_business_id, v_product.id, p_location_id, 'PURCHASE',
      v_qty, v_unit_cost, v_qty * v_unit_cost,
      'PURCHASE', v_purchase_id, v_user_id
    );

    -- Actualiza costo base del producto para análisis futuro.
    update public.products
    set cost_price = v_unit_cost,
        updated_at = now()
    where id = v_product.id;
  end loop;

  if round(v_calc_total,2) <> round(p_total,2) then
    raise exception 'El total enviado no coincide con los ítems de la compra';
  end if;

  v_status := case when p_payment_mode = 'CASH' then 'PAID' else 'UNPAID' end;

  insert into public.supplier_accounts_payable (
    business_id, supplier_id, purchase_id,
    original_amount, paid_amount, status, due_date
  )
  values (
    v_business_id, p_supplier_id, v_purchase_id,
    p_total,
    case when p_payment_mode = 'CASH' then p_total else 0 end,
    v_status, p_due_date
  );

  insert into public.audit_logs (
    business_id, user_id, action, entity_type, entity_id, new_values
  )
  values (
    v_business_id, v_user_id, 'CREATE_PURCHASE', 'PURCHASE', v_purchase_id,
    jsonb_build_object(
      'purchase_number', v_purchase_number,
      'total', p_total,
      'payment_mode', p_payment_mode
    )
  );

  return v_purchase_id;
end;
$$;

-- Apertura de caja.
create or replace function public.open_cash_session(
  p_cash_register_id uuid,
  p_opening_amount numeric
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid := public.current_business_id();
  v_user_id uuid;
  v_id uuid;
begin
  select id into v_user_id from public.users
  where auth_user_id = auth.uid() and is_active = true limit 1;

  if v_business_id is null or v_user_id is null then raise exception 'Usuario no autorizado'; end if;
  if p_opening_amount < 0 then raise exception 'Apertura inválida'; end if;

  if not exists (
    select 1 from public.cash_registers
    where id = p_cash_register_id and business_id = v_business_id and is_active
  ) then
    raise exception 'Caja no válida';
  end if;

  if exists (
    select 1 from public.cash_sessions
    where cash_register_id = p_cash_register_id and status = 'OPEN'
  ) then
    raise exception 'Ya existe una sesión abierta para esta caja';
  end if;

  insert into public.cash_sessions (
    cash_register_id, opened_by, opening_amount
  )
  values (
    p_cash_register_id, v_user_id, p_opening_amount
  )
  returning id into v_id;

  insert into public.cash_movements (
    cash_session_id, movement_type, amount, description, created_by, payment_method_code
  )
  values (
    v_id, 'OPENING', p_opening_amount, 'Apertura de caja', v_user_id, 'CASH'
  );

  return v_id;
end;
$$;

-- Cierre de caja.
create or replace function public.close_cash_session(
  p_cash_session_id uuid,
  p_counted_amount numeric
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_expected numeric(12,2);
  v_difference numeric(12,2);
  v_business_id uuid;
begin
  v_business_id := public.current_business_id();

  select id into v_user_id from public.users
  where auth_user_id = auth.uid() and is_active = true limit 1;

  select
    cs.opening_amount
    + coalesce(sum(
      case
        when cm.movement_type in ('SALE','DEPOSIT','OPENING') then cm.amount
        when cm.movement_type in ('EXPENSE','WITHDRAWAL','CLOSING') then -abs(cm.amount)
        else cm.amount
      end
    ) filter (where cm.movement_type <> 'OPENING'), 0)
  into v_expected
  from public.cash_sessions cs
  left join public.cash_movements cm on cm.cash_session_id = cs.id
  where cs.id = p_cash_session_id
    and cs.status = 'OPEN'
  group by cs.id, cs.opening_amount
  for update;

  if v_expected is null then
    raise exception 'Sesión de caja inexistente o ya cerrada';
  end if;

  v_difference := p_counted_amount - v_expected;

  update public.cash_sessions
  set closed_by = v_user_id,
      closed_at = now(),
      expected_amount = v_expected,
      counted_amount = p_counted_amount,
      difference = v_difference,
      status = 'CLOSED'
  where id = p_cash_session_id;

  insert into public.cash_movements (
    cash_session_id, movement_type, amount, description, created_by, payment_method_code
  )
  values (
    p_cash_session_id, 'CLOSING', p_counted_amount,
    'Cierre de caja', v_user_id, 'CASH'
  );

  return jsonb_build_object(
    'expected_amount', v_expected,
    'counted_amount', p_counted_amount,
    'difference', v_difference
  );
end;
$$;

-- Vista operativa para dashboard.
create or replace view public.v_business_daily_metrics as
select
  s.business_id,
  date_trunc('day', s.sold_at at time zone 'America/Bogota')::date as day,
  count(*) filter (where s.status = 'COMPLETED') as sales_count,
  coalesce(sum(s.total) filter (where s.status = 'COMPLETED'), 0) as sales_total,
  coalesce(sum(s.total_cost) filter (where s.status = 'COMPLETED'), 0) as product_cost,
  coalesce(sum(s.indirect_cost_total) filter (where s.status = 'COMPLETED'), 0) as indirect_cost,
  coalesce(sum(s.gross_profit) filter (where s.status = 'COMPLETED'), 0) as gross_profit,
  coalesce(sum(s.estimated_net_profit) filter (where s.status = 'COMPLETED'), 0) as estimated_net_profit
from public.sales s
group by s.business_id, date_trunc('day', s.sold_at at time zone 'America/Bogota')::date;

-- NOTA DE IMPLEMENTACIÓN:
-- create_sale deberá evolucionar para tomar el costo indirecto de
-- product_indirect_unit_cost(product_id), guardarlo como snapshot y calcular
-- full_cost_total/gross_profit/estimated_net_profit.
-- Se deja separado para que la próxima migración implemente la fórmula final
-- de rentabilidad sin mezclarla con el cierre de caja.
