-- Run in an isolated PostgreSQL database with auth.uid() backed by test.auth_uid.
-- The runner applies historic migrations and 006 before executing this file.
grant usage on schema public, auth to authenticated;
grant select on all tables in schema public to authenticated;
grant update on public.cost_components, public.products to authenticated;
grant execute on function auth.uid() to authenticated;

insert into public.businesses(id, name, slug) values
  ('00000000-0000-0000-0000-000000000001', 'A', 'a'),
  ('00000000-0000-0000-0000-000000000002', 'B', 'b');
insert into public.users(id, business_id, auth_user_id, full_name, role_id) values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Admin A', (select id from public.roles where name = 'ADMIN')),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', 'Operator A', (select id from public.roles where name = 'COLLABORATOR')),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003', 'Admin B', (select id from public.roles where name = 'ADMIN'));
insert into public.locations(id, business_id, name, type) values
  ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'A location', 'WAREHOUSE'),
  ('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'B location', 'WAREHOUSE');
insert into public.categories(id, business_id, name, slug) values
  ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Category A', 'a');
insert into public.products(id, business_id, category_id, name, slug, sale_price, cost_price, status) values
  ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 'Product A', 'a', 10, 4, 'PUBLISHED'),
  ('50000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 'Out', 'out', 10, 4, 'OUT_OF_STOCK');
insert into public.inventory_movements(business_id, product_id, location_id, movement_type, quantity, created_by)
  values ('00000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'PURCHASE', 8, '10000000-0000-0000-0000-000000000001');
select set_config('test.auth_uid', '20000000-0000-0000-0000-000000000001', false);
insert into public.cost_components(id, business_id, name, unit, unit_cost) values
  ('60000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Bag', 'unit', 1);
insert into public.product_cost_components(business_id, product_id, component_id, quantity)
  values ('00000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000001', 1);
insert into public.cash_registers(id, business_id, name) values
  ('70000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Register A');
insert into public.cash_register_assignments(business_id, user_id, cash_register_id) values
  ('00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', '70000000-0000-0000-0000-000000000001');
insert into public.payment_methods(id, business_id, name, code, affects_physical_cash) values
  ('80000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Cash', 'CASH', true),
  ('80000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Nequi', 'NEQUI', false);
insert into public.suppliers(id, business_id, name) values
  ('90000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Supplier A');
insert into public.expense_categories(id, business_id, name) values
  ('a0000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Operating');

set role authenticated;
select set_config('test.auth_uid', '20000000-0000-0000-0000-000000000002', false);
do $$
declare
  session_id uuid;
  created_sale_id uuid;
  result jsonb;
begin
  session_id := public.open_cash_session('70000000-0000-0000-0000-000000000001', 20);
  perform set_config('test.session_id', session_id::text, false);
  created_sale_id := public.create_sale(null, '30000000-0000-0000-0000-000000000001',
    '[{"product_id":"50000000-0000-0000-0000-000000000001","quantity":2,"unit_price":0}]',
    '[{"payment_method_id":"80000000-0000-0000-0000-000000000001","amount":10},{"payment_method_id":"80000000-0000-0000-0000-000000000002","amount":10}]',
    session_id);
  if (select total <> 20 or total_cost <> 8 or indirect_cost_total <> 2 or gross_profit <> 10
    from public.sales where id = created_sale_id) then raise exception 'Sale totals or indirect cost snapshot incorrect'; end if;
  if (select unit_price <> 10 or unit_cost <> 4 or indirect_cost_per_unit <> 1
    from public.sale_items where sale_id = created_sale_id limit 1) then raise exception 'Historical sale snapshot incorrect'; end if;
  begin
    perform public.create_sale(null, '30000000-0000-0000-0000-000000000001',
      '[{"product_id":"50000000-0000-0000-0000-000000000002","quantity":1}]',
      '[{"payment_method_id":"80000000-0000-0000-0000-000000000001","amount":10}]', session_id);
    raise exception 'Out of stock accepted';
  exception when others then
    if sqlerrm = 'Out of stock accepted' then raise; end if;
  end;
  begin
    perform public.create_expense('a0000000-0000-0000-0000-000000000001', 2, 'Denied',
      '80000000-0000-0000-0000-000000000001', session_id);
    raise exception 'Collaborator expense accepted';
  exception when others then
    if sqlerrm = 'Collaborator expense accepted' then raise; end if;
  end;
  result := public.close_cash_session(session_id, 30);
  if result->>'expected_amount' <> '30.00' or result->>'difference' <> '0.00' then
    raise exception 'Cash closing mismatch: %', result;
  end if;
end;
$$;

select set_config('test.auth_uid', '20000000-0000-0000-0000-000000000001', false);
do $$
declare
  session_id uuid;
  created_purchase_id uuid;
  credit_id uuid;
  payable_id uuid;
  result jsonb;
  original_total numeric;
begin
  session_id := public.open_cash_session('70000000-0000-0000-0000-000000000001', 20);
  begin
    perform public.create_purchase_with_payment_status(
      '90000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', null,
      '[{"product_id":"50000000-0000-0000-0000-000000000001","quantity":2,"unit_cost":4}]',
      8, 'IMMEDIATE', '80000000-0000-0000-0000-000000000001', null);
    raise exception 'Cash purchase without session accepted';
  exception when others then
    if sqlerrm = 'Cash purchase without session accepted' then raise; end if;
  end;
  created_purchase_id := public.create_purchase_with_payment_status(
    '90000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', null,
    '[{"product_id":"50000000-0000-0000-0000-000000000001","quantity":2,"unit_cost":4}]',
    8, 'IMMEDIATE', '80000000-0000-0000-0000-000000000001', session_id);
  if (select outstanding_amount <> 0 or status <> 'PAID' from public.supplier_accounts_payable where purchase_id = created_purchase_id) then
    raise exception 'Immediate payable not settled'; end if;
  perform public.create_purchase_with_payment_status(
    '90000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', null,
    '[{"product_id":"50000000-0000-0000-0000-000000000001","quantity":1,"unit_cost":4}]',
    4, 'IMMEDIATE', '80000000-0000-0000-0000-000000000002', null);
  credit_id := public.create_purchase_with_payment_status(
    '90000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', null,
    '[{"product_id":"50000000-0000-0000-0000-000000000001","quantity":2,"unit_cost":4}]',
    8, 'CREDIT', null, null, now() + interval '7 days');
  select id into payable_id from public.supplier_accounts_payable where purchase_id = credit_id;
  perform public.register_supplier_payment(payable_id, 4, '80000000-0000-0000-0000-000000000002', null);
  if (select outstanding_amount <> 4 or status <> 'PARTIAL' from public.supplier_accounts_payable where id = payable_id) then
    raise exception 'Credit payable partial balance incorrect'; end if;
  perform public.register_supplier_payment(payable_id, 4, '80000000-0000-0000-0000-000000000001', session_id);
  perform public.create_expense('a0000000-0000-0000-0000-000000000001', 3, 'Cash expense',
    '80000000-0000-0000-0000-000000000001', session_id);
  perform public.create_expense('a0000000-0000-0000-0000-000000000001', 3, 'Digital expense',
    '80000000-0000-0000-0000-000000000002', null);
  perform public.record_cash_transfer(session_id, 5, 'DEPOSIT', 'Float');
  perform public.record_cash_transfer(session_id, 2, 'WITHDRAWAL', 'Cash removal');
  result := public.close_cash_session(session_id, 8);
  if result->>'expected_amount' <> '8.00' or result->>'difference' <> '0.00' then
    raise exception 'Cash expected should be 20 - 8 - 4 - 3 + 5 - 2: %', result;
  end if;
  if (select count(*) <> 1 from public.cash_movements where reference_type = 'EXPENSE') then
    raise exception 'Digital expense should not affect cash'; end if;
  select total into original_total from public.sales limit 1;
  update public.cost_components set unit_cost = 3 where id = '60000000-0000-0000-0000-000000000001';
  if (select count(*) <> 2 from public.cost_component_price_history where component_id = '60000000-0000-0000-0000-000000000001') then
    raise exception 'Component cost history missing'; end if;
  if (select indirect_cost_total <> 2 from public.sales limit 1) or original_total <> 20 then
    raise exception 'Cost change rewrote historical sale'; end if;
  begin
    perform public.create_expense('a0000000-0000-0000-0000-000000000001', 3, 'Cross business',
      '80000000-0000-0000-0000-000000000001', null, now(), null);
    raise exception 'Cash expense without session accepted';
  exception when others then
    if sqlerrm = 'Cash expense without session accepted' then raise; end if;
  end;
end;
$$;

select set_config('test.auth_uid', '20000000-0000-0000-0000-000000000002', false);
do $$
begin
  if exists (select 1 from public.products) then raise exception 'Operator can read cost-bearing products'; end if;
  if not exists (select 1 from public.v_operational_stock where product_id = '50000000-0000-0000-0000-000000000001') then
    raise exception 'Operator cannot read operational stock'; end if;
  begin
    update public.products set sale_price = 1 where id = '50000000-0000-0000-0000-000000000001';
    if found then raise exception 'Operator updated price'; end if;
  exception when others then
    if sqlerrm = 'Operator updated price' then raise; end if;
  end;
  begin
    perform public.record_cash_transfer(null, 1, 'DEPOSIT', 'Denied');
    raise exception 'Operator moved cash';
  exception when others then
    if sqlerrm = 'Operator moved cash' then raise; end if;
  end;
end;
$$;
select set_config('test.auth_uid', '20000000-0000-0000-0000-000000000003', false);
do $$
begin
  if exists (select 1 from public.v_operational_stock) then raise exception 'Cross business stock visible'; end if;
  begin
    perform public.register_wastage('50000000-0000-0000-0000-000000000001',
      '30000000-0000-0000-0000-000000000001', 1, 'Denied');
    raise exception 'Cross business wastage accepted';
  exception when others then
    if sqlerrm = 'Cross business wastage accepted' then raise; end if;
  end;
end;
$$;
