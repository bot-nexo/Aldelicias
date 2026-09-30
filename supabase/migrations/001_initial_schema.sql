-- AlDelicias — PostgreSQL/Supabase Foundation
-- Migration: 001_initial_schema.sql
-- Fuente: ERD V1.0
-- No ejecutar en producción sin revisión del entorno.

create extension if not exists "pgcrypto";

create type public.user_role as enum ('ADMIN', 'COLLABORATOR');
create type public.product_status as enum ('DRAFT', 'PUBLISHED', 'HIDDEN', 'OUT_OF_STOCK');
create type public.purchase_status as enum ('DRAFT', 'CONFIRMED', 'CANCELLED');
create type public.sale_status as enum ('COMPLETED', 'CANCELLED');
create type public.expense_status as enum ('ACTIVE', 'CANCELLED');
create type public.cash_session_status as enum ('OPEN', 'CLOSED');
create type public.event_status as enum ('NEW', 'CONTACTED', 'QUOTE', 'CONFIRMED', 'COMPLETED', 'LOST');
create type public.inventory_movement_type as enum (
  'PURCHASE', 'SALE', 'WASTAGE', 'ADJUSTMENT',
  'TRANSFER_IN', 'TRANSFER_OUT', 'RETURN', 'REVERSAL'
);
create type public.cash_movement_type as enum (
  'SALE', 'EXPENSE', 'WITHDRAWAL', 'DEPOSIT',
  'ADJUSTMENT', 'OPENING', 'CLOSING', 'REVERSAL'
);

create table public.businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  logo_url text,
  phone text,
  whatsapp text,
  email text,
  address text,
  timezone text not null default 'America/Bogota',
  currency text not null default 'COP',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  name user_role not null unique,
  description text
);

insert into public.roles (name, description)
values
  ('ADMIN', 'Acceso administrativo y financiero'),
  ('COLLABORATOR', 'Operación diaria y ventas')
on conflict (name) do nothing;

create table public.users (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  auth_user_id uuid not null unique,
  full_name text not null,
  email text,
  phone text,
  role_id uuid not null references public.roles(id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_login_at timestamptz
);

create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  name text not null,
  plate text,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.locations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  vehicle_id uuid references public.vehicles(id),
  name text not null,
  type text not null check (type in ('WAREHOUSE','VEHICLE','OTHER')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  name text not null,
  slug text not null,
  description text,
  image_url text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, slug)
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  category_id uuid references public.categories(id),
  name text not null,
  slug text not null,
  short_description text,
  description text,
  sku text,
  sale_price numeric(12,2) not null default 0 check (sale_price >= 0),
  cost_price numeric(12,2) check (cost_price >= 0),
  track_inventory boolean not null default true,
  minimum_stock numeric(12,3) not null default 0 check (minimum_stock >= 0),
  is_featured boolean not null default false,
  status product_status not null default 'DRAFT',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, slug),
  unique (business_id, sku)
);

create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  storage_path text not null,
  public_url text,
  alt_text text,
  sort_order integer not null default 0,
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.suppliers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  name text not null,
  contact_name text,
  phone text,
  whatsapp text,
  email text,
  address text,
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  name text not null,
  code text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (business_id, code)
);

create table public.expense_categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (business_id, name)
);

create table public.wastage_reasons (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (business_id, name)
);

create table public.purchases (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  supplier_id uuid not null references public.suppliers(id),
  location_id uuid not null references public.locations(id),
  vehicle_id uuid references public.vehicles(id),
  purchase_number text not null,
  purchase_date timestamptz not null default now(),
  subtotal numeric(12,2) not null default 0 check (subtotal >= 0),
  discount_total numeric(12,2) not null default 0 check (discount_total >= 0),
  total numeric(12,2) not null default 0 check (total >= 0),
  status purchase_status not null default 'DRAFT',
  notes text,
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, purchase_number)
);

create table public.purchase_items (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null references public.purchases(id) on delete restrict,
  product_id uuid not null references public.products(id),
  product_name_snapshot text not null,
  quantity numeric(12,3) not null check (quantity > 0),
  unit_cost numeric(12,2) not null check (unit_cost >= 0),
  subtotal numeric(12,2) not null check (subtotal >= 0),
  created_at timestamptz not null default now()
);

create table public.sales (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  sale_number text not null,
  user_id uuid not null references public.users(id),
  vehicle_id uuid references public.vehicles(id),
  location_id uuid references public.locations(id),
  sold_at timestamptz not null default now(),
  subtotal numeric(12,2) not null default 0 check (subtotal >= 0),
  discount_total numeric(12,2) not null default 0 check (discount_total >= 0),
  total numeric(12,2) not null default 0 check (total >= 0),
  total_cost numeric(12,2) not null default 0 check (total_cost >= 0),
  gross_profit numeric(12,2) not null default 0,
  status sale_status not null default 'COMPLETED',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, sale_number)
);

create table public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete restrict,
  product_id uuid not null references public.products(id),
  product_name_snapshot text not null,
  quantity numeric(12,3) not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  unit_cost numeric(12,2) not null default 0 check (unit_cost >= 0),
  subtotal numeric(12,2) not null check (subtotal >= 0),
  cost_total numeric(12,2) not null default 0 check (cost_total >= 0),
  created_at timestamptz not null default now()
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete restrict,
  payment_method_id uuid not null references public.payment_methods(id),
  amount numeric(12,2) not null check (amount > 0),
  created_at timestamptz not null default now()
);

create table public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  product_id uuid not null references public.products(id),
  location_id uuid not null references public.locations(id),
  movement_type inventory_movement_type not null,
  quantity numeric(12,3) not null check (quantity <> 0),
  unit_cost numeric(12,2) not null default 0 check (unit_cost >= 0),
  total_cost numeric(12,2) not null default 0,
  reference_type text,
  reference_id uuid,
  reason text,
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now()
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  category_id uuid not null references public.expense_categories(id),
  vehicle_id uuid references public.vehicles(id),
  user_id uuid not null references public.users(id),
  description text not null,
  amount numeric(12,2) not null check (amount > 0),
  expense_date timestamptz not null default now(),
  payment_method_id uuid references public.payment_methods(id),
  receipt_url text,
  notes text,
  status expense_status not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.cash_registers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  name text not null,
  location_id uuid references public.locations(id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.cash_sessions (
  id uuid primary key default gen_random_uuid(),
  cash_register_id uuid not null references public.cash_registers(id),
  opened_by uuid not null references public.users(id),
  opened_at timestamptz not null default now(),
  opening_amount numeric(12,2) not null default 0 check (opening_amount >= 0),
  closed_by uuid references public.users(id),
  closed_at timestamptz,
  expected_amount numeric(12,2),
  counted_amount numeric(12,2),
  difference numeric(12,2),
  status cash_session_status not null default 'OPEN'
);

create table public.cash_movements (
  id uuid primary key default gen_random_uuid(),
  cash_session_id uuid not null references public.cash_sessions(id),
  movement_type cash_movement_type not null,
  amount numeric(12,2) not null check (amount <> 0),
  reference_type text,
  reference_id uuid,
  description text,
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now()
);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  customer_name text not null,
  company_name text,
  phone text,
  email text,
  event_date timestamptz,
  guest_count integer check (guest_count > 0),
  event_type text,
  message text,
  status event_status not null default 'NEW',
  source text default 'WEBSITE',
  assigned_to uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  user_id uuid references public.users(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  old_values jsonb,
  new_values jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamptz not null default now()
);

-- Índices principales
create index idx_users_business on public.users(business_id);
create index idx_products_business on public.products(business_id);
create index idx_products_category on public.products(category_id);
create index idx_product_images_product on public.product_images(product_id);

create index idx_purchases_business_date on public.purchases(business_id, purchase_date);
create index idx_purchase_items_purchase on public.purchase_items(purchase_id);

create index idx_sales_business_date on public.sales(business_id, sold_at);
create index idx_sales_status on public.sales(status);
create index idx_sale_items_sale on public.sale_items(sale_id);
create index idx_sale_items_product on public.sale_items(product_id);
create index idx_payments_sale on public.payments(sale_id);

create index idx_inventory_product_location on public.inventory_movements(product_id, location_id);
create index idx_inventory_business_date on public.inventory_movements(business_id, created_at);

create index idx_expenses_business_date on public.expenses(business_id, expense_date);
create index idx_events_business_status on public.events(business_id, status);
create index idx_audit_business_date on public.audit_logs(business_id, created_at);

-- Nota:
-- RLS/policies, triggers updated_at, funciones transaccionales y RPCs
-- se implementan en migraciones separadas para mantener esta fundación auditable.
