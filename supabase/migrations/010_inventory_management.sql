-- Incremental inventory management: safe read RPCs, admin adjustments, and movement integrity.
-- Purchase, sale, and wastage RPCs remain owned by their existing migrations.

do $$
begin
  if exists (
    select 1
    from public.inventory_movements m
    left join public.products p on p.id = m.product_id
    left join public.locations l on l.id = m.location_id
    left join public.users u on u.id = m.created_by
    where p.id is null
       or l.id is null
       or u.id is null
       or p.business_id is distinct from m.business_id
       or l.business_id is distinct from m.business_id
       or u.business_id is distinct from m.business_id
  ) then
    raise exception 'Resolve cross-business inventory movement references before applying migration 010.';
  end if;
end;
$$;

create index if not exists inventory_movements_stock_lookup_idx
  on public.inventory_movements (business_id, product_id, location_id);

create index if not exists inventory_movements_history_lookup_idx
  on public.inventory_movements (business_id, created_at desc, id desc);

create function public.validate_inventory_movement_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.products p
    where p.id = new.product_id
      and p.business_id = new.business_id
  ) then
    raise exception 'Inventory product must belong to the movement business.';
  end if;

  if not exists (
    select 1 from public.locations l
    where l.id = new.location_id
      and l.business_id = new.business_id
  ) then
    raise exception 'Inventory location must belong to the movement business.';
  end if;

  if not exists (
    select 1 from public.users u
    where u.id = new.created_by
      and u.business_id = new.business_id
  ) then
    raise exception 'Inventory actor must belong to the movement business.';
  end if;

  if new.movement_type in ('WASTAGE', 'ADJUSTMENT')
     and nullif(pg_catalog.btrim(new.reason), '') is null then
    raise exception 'Wastage and adjustment movements require a reason.';
  end if;

  return new;
end;
$$;

create trigger inventory_movement_validate_insert
before insert on public.inventory_movements
for each row execute function public.validate_inventory_movement_insert();

create function public.prevent_inventory_movement_mutation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception 'Inventory movements are immutable; record a compensating movement instead.';
end;
$$;

create trigger inventory_movement_append_only
before update or delete on public.inventory_movements
for each row execute function public.prevent_inventory_movement_mutation();

create function public.get_inventory_stock()
returns table (
  business_id uuid,
  product_id uuid,
  product_name text,
  sku text,
  product_status public.product_status,
  minimum_stock numeric(12,3),
  location_id uuid,
  location_name text,
  current_stock numeric(12,3)
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  active_business_id uuid := public.current_business_id();
begin
  if auth.uid() is null
     or active_business_id is null
     or (public.is_admin() is not true and public.has_permission('INVENTORY_READ') is not true) then
    raise exception 'Unauthorized inventory read';
  end if;

  return query
  select
    p.business_id,
    p.id,
    p.name,
    p.sku,
    p.status,
    p.minimum_stock,
    l.id,
    l.name,
    coalesce(sum(m.quantity), 0)::numeric(12,3)
  from public.products p
  join public.locations l
    on l.business_id = p.business_id
   and l.is_active
  left join public.inventory_movements m
    on m.business_id = p.business_id
   and m.product_id = p.id
   and m.location_id = l.id
  where p.business_id = active_business_id
    and p.track_inventory
    and (
      public.is_admin()
      or p.status in (
        'PUBLISHED'::public.product_status,
        'OUT_OF_STOCK'::public.product_status
      )
    )
  group by p.business_id, p.id, p.name, p.sku, p.status, p.minimum_stock, l.id, l.name
  order by l.name, p.sort_order, p.name;
end;
$$;

create function public.get_inventory_movement_history(
  p_product_id uuid default null,
  p_location_id uuid default null,
  p_limit integer default 100,
  p_offset integer default 0
)
returns table (
  movement_id uuid,
  business_id uuid,
  product_id uuid,
  product_name text,
  location_id uuid,
  location_name text,
  movement_type public.inventory_movement_type,
  quantity numeric(12,3),
  reason text,
  reference_type text,
  reference_id uuid,
  created_by uuid,
  created_by_name text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  active_business_id uuid := public.current_business_id();
begin
  if auth.uid() is null
     or active_business_id is null
     or (public.is_admin() is not true and public.has_permission('INVENTORY_READ') is not true) then
    raise exception 'Unauthorized inventory history read';
  end if;

  if p_limit is null or p_limit < 1 or p_limit > 200
     or p_offset is null or p_offset < 0 then
    raise exception 'Invalid inventory history pagination';
  end if;

  if p_product_id is not null and not exists (
    select 1 from public.products p
    where p.id = p_product_id
      and p.business_id = active_business_id
  ) then
    raise exception 'Invalid inventory product filter';
  end if;

  if p_location_id is not null and not exists (
    select 1 from public.locations l
    where l.id = p_location_id
      and l.business_id = active_business_id
  ) then
    raise exception 'Invalid inventory location filter';
  end if;

  return query
  select
    m.id,
    m.business_id,
    m.product_id,
    p.name,
    m.location_id,
    l.name,
    m.movement_type,
    m.quantity,
    m.reason,
    m.reference_type,
    m.reference_id,
    m.created_by,
    u.full_name,
    m.created_at
  from public.inventory_movements m
  join public.products p
    on p.id = m.product_id
   and p.business_id = m.business_id
  join public.locations l
    on l.id = m.location_id
   and l.business_id = m.business_id
  join public.users u
    on u.id = m.created_by
   and u.business_id = m.business_id
  where m.business_id = active_business_id
    and (p_product_id is null or m.product_id = p_product_id)
    and (p_location_id is null or m.location_id = p_location_id)
    and (
      public.is_admin()
      or p.status in (
        'PUBLISHED'::public.product_status,
        'OUT_OF_STOCK'::public.product_status
      )
    )
  order by m.created_at desc, m.id desc
  limit p_limit
  offset p_offset;
end;
$$;

create function public.adjust_inventory_stock(
  p_product_id uuid,
  p_location_id uuid,
  p_delta numeric,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  active_business_id uuid := public.current_business_id();
  actor_id uuid;
  available_stock numeric(12,3);
  adjustment_delta numeric(12,3);
  movement_id uuid;
begin
  actor_id := app_private.actor(active_business_id, 'INVENTORY_ADMIN');

  if p_delta is null or p_delta = 0 or p_delta <> pg_catalog.round(p_delta, 3) then
    raise exception 'Adjustment must be a non-zero quantity with at most three decimals.';
  end if;

  if p_reason is null
     or pg_catalog.length(pg_catalog.btrim(p_reason)) < 3
     or pg_catalog.length(p_reason) > 500 then
    raise exception 'Adjustment reason must contain 3 to 500 characters.';
  end if;

  adjustment_delta := p_delta;

  if not exists (
    select 1 from public.locations l
    where l.id = p_location_id
      and l.business_id = active_business_id
      and l.is_active
  ) then
    raise exception 'Invalid inventory location';
  end if;

  perform 1
  from public.products p
  where p.id = p_product_id
    and p.business_id = active_business_id
    and p.track_inventory
  for update;

  if not found then
    raise exception 'Invalid tracked inventory product';
  end if;

  select pg_catalog.coalesce(pg_catalog.sum(m.quantity), 0)
  into available_stock
  from public.inventory_movements m
  where m.business_id = active_business_id
    and m.product_id = p_product_id
    and m.location_id = p_location_id;

  if available_stock + adjustment_delta < 0 then
    raise exception 'Adjustment would create negative stock';
  end if;

  insert into public.inventory_movements (
    business_id,
    product_id,
    location_id,
    movement_type,
    quantity,
    reference_type,
    reason,
    created_by
  )
  values (
    active_business_id,
    p_product_id,
    p_location_id,
    'ADJUSTMENT'::public.inventory_movement_type,
    adjustment_delta,
    'INVENTORY_ADJUSTMENT',
    pg_catalog.btrim(p_reason),
    actor_id
  )
  returning id into movement_id;

  insert into public.audit_logs (
    business_id,
    user_id,
    action,
    entity_type,
    entity_id,
    new_values
  )
  values (
    active_business_id,
    actor_id,
    'INVENTORY_ADJUSTMENT',
    'INVENTORY_MOVEMENT',
    movement_id,
    pg_catalog.jsonb_build_object(
      'product_id', p_product_id,
      'location_id', p_location_id,
      'quantity_delta', adjustment_delta,
      'reason', pg_catalog.btrim(p_reason)
    )
  );

  return movement_id;
end;
$$;

revoke all on function public.validate_inventory_movement_insert() from public, anon, authenticated;
revoke all on function public.prevent_inventory_movement_mutation() from public, anon, authenticated;
revoke all on function public.get_inventory_stock() from public, anon, authenticated;
revoke all on function public.get_inventory_movement_history(uuid, uuid, integer, integer) from public, anon, authenticated;
revoke all on function public.adjust_inventory_stock(uuid, uuid, numeric, text) from public, anon, authenticated;
grant execute on function public.get_inventory_stock() to authenticated;
grant execute on function public.get_inventory_movement_history(uuid, uuid, integer, integer) to authenticated;
grant execute on function public.adjust_inventory_stock(uuid, uuid, numeric, text) to authenticated;
