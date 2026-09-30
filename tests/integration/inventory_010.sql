-- Run after migrations 001-010 and the fixtures from hardening.sql in an isolated database.
reset role;

insert into public.locations(id, business_id, name, type) values
  ('d3000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000001', 'Inventory test location', 'WAREHOUSE');
insert into public.products(id, business_id, name, slug, sale_price, cost_price, track_inventory, status) values
  ('d5000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000001', 'Inventory test product', 'inventory-test-010', 10, 4, true, 'PUBLISHED'),
  ('d5000000-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000001', 'Hidden inventory test product', 'inventory-hidden-test-010', 10, 4, true, 'HIDDEN');
insert into public.inventory_movements(
  id, business_id, product_id, location_id, movement_type, quantity,
  reason, created_by
) values (
  'e5000000-0000-4000-8000-000000000003',
  '00000000-0000-0000-0000-000000000001',
  'd5000000-0000-4000-8000-000000000003',
  'd3000000-0000-4000-8000-000000000003',
  'PURCHASE', 5, 'Initial integration balance',
  '10000000-0000-0000-0000-000000000001'
);
insert into public.inventory_movements(
  id, business_id, product_id, location_id, movement_type, quantity,
  reason, created_by
) values (
  'e5000000-0000-4000-8000-000000000004',
  '00000000-0000-0000-0000-000000000001',
  'd5000000-0000-4000-8000-000000000004',
  'd3000000-0000-4000-8000-000000000003',
  'PURCHASE', 3, 'Hidden product integration balance',
  '10000000-0000-0000-0000-000000000001'
);

set role authenticated;
select set_config('test.auth_uid', '20000000-0000-0000-0000-000000000002', false);
do $$
declare
  stock numeric(12,3);
begin
  select current_stock into stock
  from public.get_inventory_stock()
  where product_id = 'd5000000-0000-4000-8000-000000000003'
    and location_id = 'd3000000-0000-4000-8000-000000000003';
  if stock <> 5 then raise exception 'Collaborator inventory read returned unexpected stock: %', stock; end if;

  if exists (
    select 1 from public.get_inventory_stock()
    where business_id <> '00000000-0000-0000-0000-000000000001'
  ) then
    raise exception 'Collaborator can read stock from another business';
  end if;

  if exists (
    select 1 from public.get_inventory_stock()
    where product_id = 'd5000000-0000-4000-8000-000000000004'
  ) or exists (
    select 1 from public.get_inventory_movement_history(
      'd5000000-0000-4000-8000-000000000004', null, 50, 0
    )
  ) then
    raise exception 'Collaborator can read hidden product inventory';
  end if;

  begin
    perform public.adjust_inventory_stock(
      'd5000000-0000-4000-8000-000000000003',
      'd3000000-0000-4000-8000-000000000003',
      1,
      'Collaborator adjustment denied'
    );
    raise exception 'Collaborator inventory adjustment accepted';
  exception when others then
    if sqlerrm = 'Collaborator inventory adjustment accepted' then raise; end if;
  end;

  perform public.register_wastage(
    'd5000000-0000-4000-8000-000000000003',
    'd3000000-0000-4000-8000-000000000003',
    1.125,
    'Damaged during handling'
  );

  select current_stock into stock
  from public.get_inventory_stock()
  where product_id = 'd5000000-0000-4000-8000-000000000003'
    and location_id = 'd3000000-0000-4000-8000-000000000003';
  if stock <> 3.875 then raise exception 'Wastage did not reduce stock: %', stock; end if;

  if not exists (
    select 1 from public.get_inventory_movement_history(
      'd5000000-0000-4000-8000-000000000003',
      'd3000000-0000-4000-8000-000000000003',
      50,
      0
    ) where movement_type = 'WASTAGE'
      and quantity = -1.125
      and reason = 'Damaged during handling'
      and created_by_name = 'Operator A'
  ) then
    raise exception 'Wastage history is incomplete';
  end if;

  begin
    perform public.register_wastage(
      'd5000000-0000-4000-8000-000000000003',
      '30000000-0000-0000-0000-000000000002',
      1,
      'Cross-business location denied'
    );
    raise exception 'Cross-business wastage accepted';
  exception when others then
    if sqlerrm = 'Cross-business wastage accepted' then raise; end if;
  end;
end;
$$;

select set_config('test.auth_uid', '20000000-0000-0000-0000-000000000001', false);
do $$
declare
  stock numeric(12,3);
begin
  perform public.adjust_inventory_stock(
    'd5000000-0000-4000-8000-000000000003',
    'd3000000-0000-4000-8000-000000000003',
    0.5,
    'Physical count correction'
  );

  select current_stock into stock
  from public.get_inventory_stock()
  where product_id = 'd5000000-0000-4000-8000-000000000003'
    and location_id = 'd3000000-0000-4000-8000-000000000003';
  if stock <> 4.375 then raise exception 'Admin adjustment did not change stock: %', stock; end if;

  if not exists (
    select 1 from public.get_inventory_movement_history(
      'd5000000-0000-4000-8000-000000000003',
      'd3000000-0000-4000-8000-000000000003',
      50,
      0
    ) where movement_type = 'ADJUSTMENT'
      and quantity = 0.5
      and reason = 'Physical count correction'
      and created_by_name = 'Admin A'
  ) then
    raise exception 'Adjustment history is incomplete';
  end if;

  begin
    perform public.adjust_inventory_stock(
      'd5000000-0000-4000-8000-000000000003',
      'd3000000-0000-4000-8000-000000000003',
      -100,
      'Excess reduction denied'
    );
    raise exception 'Negative stock adjustment accepted';
  exception when others then
    if sqlerrm = 'Negative stock adjustment accepted' then raise; end if;
  end;
end;
$$;

reset role;
select set_config('test.auth_uid', '20000000-0000-0000-0000-000000000001', false);
do $$
declare
  movement_id uuid := 'e5000000-0000-4000-8000-000000000003';
begin
  begin
    insert into public.inventory_movements(
      business_id, product_id, location_id, movement_type, quantity, created_by, reason
    ) values (
      '00000000-0000-0000-0000-000000000001',
      'd5000000-0000-4000-8000-000000000003',
      '30000000-0000-0000-0000-000000000002',
      'ADJUSTMENT', 1,
      '10000000-0000-0000-0000-000000000001',
      'Cross-business location denied'
    );
    raise exception 'Cross-business movement insert accepted';
  exception when others then
    if sqlerrm = 'Cross-business movement insert accepted' then raise; end if;
  end;

  begin
    update public.inventory_movements
    set reason = 'Historical edit denied'
    where id = movement_id;
    raise exception 'Inventory movement update accepted';
  exception when others then
    if sqlerrm = 'Inventory movement update accepted' then raise; end if;
  end;

  begin
    delete from public.inventory_movements where id = movement_id;
    raise exception 'Inventory movement delete accepted';
  exception when others then
    if sqlerrm = 'Inventory movement delete accepted' then raise; end if;
  end;
end;
$$;
