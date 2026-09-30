-- AlDelicias — 003_business_functions.sql
-- Funciones transaccionales. Ejecutar después de 001 y 002.

create or replace function public.create_sale(
  p_vehicle_id uuid,
  p_location_id uuid,
  p_items jsonb,
  p_payments jsonb,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_user_id uuid;
  v_sale_id uuid;
  v_sale_number text;
  v_subtotal numeric(12,2) := 0;
  v_total_cost numeric(12,2) := 0;
  v_total numeric(12,2);
  v_payment_total numeric(12,2) := 0;
  item jsonb;
  payment jsonb;
  v_product public.products%rowtype;
  v_qty numeric(12,3);
  v_unit_price numeric(12,2);
  v_unit_cost numeric(12,2);
begin
  v_business_id := public.current_business_id();
  select id into v_user_id from public.users where auth_user_id = auth.uid() and is_active = true limit 1;

  if v_business_id is null or v_user_id is null then
    raise exception 'Usuario no autorizado';
  end if;

  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'La venta requiere al menos un producto';
  end if;

  -- Consecutivo simple por negocio. Para alta concurrencia puede migrarse
  -- posteriormente a una tabla de secuencias por negocio.
  select 'V-' || lpad((coalesce(max(regexp_replace(sale_number, '\D', '', 'g')::bigint), 0) + 1)::text, 8, '0')
  into v_sale_number
  from public.sales
  where business_id = v_business_id;

  insert into public.sales (
    business_id, sale_number, user_id, vehicle_id, location_id,
    subtotal, discount_total, total, total_cost, gross_profit, status, notes
  )
  values (
    v_business_id, v_sale_number, v_user_id, p_vehicle_id, p_location_id,
    0, 0, 0, 0, 0, 'COMPLETED', p_notes
  )
  returning id into v_sale_id;

  for item in select * from jsonb_array_elements(p_items)
  loop
    select * into v_product
    from public.products
    where id = (item->>'product_id')::uuid
      and business_id = v_business_id
      and status in ('PUBLISHED', 'OUT_OF_STOCK')
    for update;

    if not found then
      raise exception 'Producto no válido: %', item->>'product_id';
    end if;

    v_qty := (item->>'quantity')::numeric;
    if v_qty <= 0 then raise exception 'Cantidad inválida'; end if;

    v_unit_price := coalesce((item->>'unit_price')::numeric, v_product.sale_price);
    v_unit_cost := coalesce(v_product.cost_price, 0);

    if v_product.track_inventory then
      if (
        select coalesce(sum(
          case
            when movement_type in ('PURCHASE','TRANSFER_IN','RETURN','REVERSAL','ADJUSTMENT') then quantity
            when movement_type in ('SALE','WASTAGE','TRANSFER_OUT') then -quantity
            else 0
          end
        ), 0)
        from public.inventory_movements
        where product_id = v_product.id
          and location_id = p_location_id
      ) < v_qty then
        raise exception 'Stock insuficiente para %', v_product.name;
      end if;
    end if;

    insert into public.sale_items (
      sale_id, product_id, product_name_snapshot,
      quantity, unit_price, unit_cost, subtotal, cost_total
    )
    values (
      v_sale_id, v_product.id, v_product.name,
      v_qty, v_unit_price, v_unit_price * v_qty,
      v_unit_price * v_qty, v_unit_cost * v_qty
    );

    v_subtotal := v_subtotal + (v_unit_price * v_qty);
    v_total_cost := v_total_cost + (v_unit_cost * v_qty);

    if v_product.track_inventory then
      insert into public.inventory_movements (
        business_id, product_id, location_id, movement_type,
        quantity, unit_cost, total_cost,
        reference_type, reference_id, created_by
      )
      values (
        v_business_id, v_product.id, p_location_id, 'SALE',
        -v_qty, v_unit_cost, v_unit_cost * v_qty,
        'SALE', v_sale_id, v_user_id
      );
    end if;
  end loop;

  v_total := v_subtotal;

  if jsonb_typeof(p_payments) <> 'array' or jsonb_array_length(p_payments) = 0 then
    raise exception 'La venta requiere al menos un pago';
  end if;

  for payment in select * from jsonb_array_elements(p_payments)
  loop
    if (payment->>'amount')::numeric <= 0 then
      raise exception 'Monto de pago inválido';
    end if;

    insert into public.payments (sale_id, payment_method_id, amount)
    select v_sale_id, pm.id, (payment->>'amount')::numeric
    from public.payment_methods pm
    where pm.id = (payment->>'payment_method_id')::uuid
      and pm.business_id = v_business_id
      and pm.is_active = true;

    if not found then
      raise exception 'Método de pago no válido';
    end if;

    v_payment_total := v_payment_total + (payment->>'amount')::numeric;
  end loop;

  if round(v_payment_total, 2) <> round(v_total, 2) then
    raise exception 'Los pagos no coinciden con el total de la venta';
  end if;

  update public.sales
  set subtotal = v_subtotal,
      total = v_total,
      total_cost = v_total_cost,
      gross_profit = v_total - v_total_cost,
      updated_at = now()
  where id = v_sale_id;

  insert into public.audit_logs (
    business_id, user_id, action, entity_type, entity_id, new_values
  )
  values (
    v_business_id, v_user_id, 'CREATE_SALE', 'SALE', v_sale_id,
    jsonb_build_object('sale_number', v_sale_number, 'total', v_total)
  );

  return v_sale_id;
end;
$$;

create or replace function public.create_expense(
  p_category_id uuid,
  p_amount numeric,
  p_description text,
  p_expense_date timestamptz default now(),
  p_payment_method_id uuid default null,
  p_vehicle_id uuid default null,
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
  v_id uuid;
begin
  select id into v_user_id from public.users where auth_user_id = auth.uid() and is_active = true limit 1;

  if v_business_id is null or v_user_id is null then
    raise exception 'Usuario no autorizado';
  end if;

  if p_amount <= 0 then raise exception 'El gasto debe ser mayor que cero'; end if;

  if not exists (
    select 1 from public.expense_categories
    where id = p_category_id
      and business_id = v_business_id
      and is_active
  ) then
    raise exception 'Categoría de gasto no válida';
  end if;

  insert into public.expenses (
    business_id, category_id, vehicle_id, user_id,
    description, amount, expense_date, payment_method_id, notes
  )
  values (
    v_business_id, p_category_id, p_vehicle_id, v_user_id,
    p_description, p_amount, p_expense_date, p_payment_method_id, p_notes
  )
  returning id into v_id;

  insert into public.audit_logs (
    business_id, user_id, action, entity_type, entity_id, new_values
  )
  values (
    v_business_id, v_user_id, 'CREATE_EXPENSE', 'EXPENSE', v_id,
    jsonb_build_object('amount', p_amount, 'description', p_description)
  );

  return v_id;
end;
$$;

create or replace function public.register_wastage(
  p_product_id uuid,
  p_location_id uuid,
  p_quantity numeric,
  p_reason text
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
  v_cost numeric(12,2);
begin
  select id into v_user_id from public.users where auth_user_id = auth.uid() and is_active = true limit 1;

  if v_business_id is null or v_user_id is null then raise exception 'Usuario no autorizado'; end if;
  if p_quantity <= 0 then raise exception 'Cantidad inválida'; end if;

  select coalesce(cost_price,0) into v_cost
  from public.products
  where id = p_product_id and business_id = v_business_id and track_inventory
  for update;

  if not found then raise exception 'Producto no válido'; end if;

  insert into public.inventory_movements (
    business_id, product_id, location_id, movement_type,
    quantity, unit_cost, total_cost, reason, created_by
  )
  values (
    v_business_id, p_product_id, p_location_id, 'WASTAGE',
    -p_quantity, v_cost, v_cost * p_quantity, p_reason, v_user_id
  )
  returning id into v_id;

  insert into public.audit_logs (
    business_id, user_id, action, entity_type, entity_id, new_values
  )
  values (
    v_business_id, v_user_id, 'REGISTER_WASTAGE', 'INVENTORY_MOVEMENT', v_id,
    jsonb_build_object('product_id', p_product_id, 'quantity', p_quantity, 'reason', p_reason)
  );

  return v_id;
end;
$$;

-- Las funciones de compra/caja/anulación se implementarán siguiendo el mismo
-- patrón después de cerrar las reglas operativas exactas de esos procesos.
