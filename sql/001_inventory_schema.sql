-- =====================================================
-- CONTROL DE INVENTARIO - ESQUEMA BASE (PostgreSQL/Supabase)
-- Archivo: /sql/001_inventory_schema.sql
-- Esquema: public
-- =====================================================

-- Opcional para UUID en PostgreSQL/Supabase
create extension if not exists "pgcrypto";

-- =====================================================
-- TABLAS MAESTRAS
-- =====================================================

create table if not exists public.inventory_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.inventory_suppliers (
  id uuid primary key default gen_random_uuid(),
  legal_name text not null,
  trade_name text,
  tax_id text,
  email text,
  phone text,
  address text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.inventory_locations (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =====================================================
-- PRODUCTOS
-- =====================================================

create table if not exists public.inventory_products (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  barcode text,
  name text not null,
  description text,
  category_id uuid references public.inventory_categories(id) on update cascade on delete set null,
  supplier_id uuid references public.inventory_suppliers(id) on update cascade on delete set null,
  unit text not null default 'unidad',
  cost numeric(12,2) not null default 0,
  price numeric(12,2) not null default 0,
  min_stock numeric(12,2) not null default 0,
  max_stock numeric(12,2),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chk_inventory_products_cost_non_negative check (cost >= 0),
  constraint chk_inventory_products_price_non_negative check (price >= 0),
  constraint chk_inventory_products_min_non_negative check (min_stock >= 0),
  constraint chk_inventory_products_max_valid check (max_stock is null or max_stock >= min_stock)
);

-- Stock consolidado por producto y ubicación
create table if not exists public.inventory_stock (
  product_id uuid not null references public.inventory_products(id) on update cascade on delete cascade,
  location_id uuid not null references public.inventory_locations(id) on update cascade on delete restrict,
  quantity numeric(12,2) not null default 0,
  updated_at timestamptz not null default now(),
  primary key (product_id, location_id),
  constraint chk_inventory_stock_quantity_non_negative check (quantity >= 0)
);

-- =====================================================
-- MOVIMIENTOS
-- =====================================================

create table if not exists public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.inventory_products(id) on update cascade on delete restrict,
  location_id uuid not null references public.inventory_locations(id) on update cascade on delete restrict,
  movement_type text not null,
  quantity numeric(12,2) not null,
  unit_cost numeric(12,2),
  reference_type text,
  reference_id text,
  note text,
  moved_at timestamptz not null default now(),
  created_by uuid,
  created_at timestamptz not null default now(),
  constraint chk_inventory_movements_type check (movement_type in ('in','out','adjustment')),
  constraint chk_inventory_movements_qty_non_zero check (quantity <> 0)
);

-- =====================================================
-- ÍNDICES
-- =====================================================

create index if not exists idx_inventory_products_name      on public.inventory_products (name);
create index if not exists idx_inventory_products_category  on public.inventory_products (category_id);
create index if not exists idx_inventory_stock_location     on public.inventory_stock (location_id);
create index if not exists idx_inventory_movements_product  on public.inventory_movements (product_id);
create index if not exists idx_inventory_movements_location on public.inventory_movements (location_id);
create index if not exists idx_inventory_movements_moved_at on public.inventory_movements (moved_at desc);

-- =====================================================
-- FUNCIÓN + TRIGGER PARA ACTUALIZAR STOCK
-- =====================================================

create or replace function public.fn_inventory_apply_movement()
returns trigger
language plpgsql
as $$
declare
  delta       numeric(12,2);
  current_qty numeric(12,2);
begin
  if new.movement_type = 'in' then
    delta := abs(new.quantity);
  elsif new.movement_type = 'out' then
    delta := -abs(new.quantity);
  else
    -- adjustment: usa el signo enviado por quantity
    delta := new.quantity;
  end if;

  insert into public.inventory_stock (product_id, location_id, quantity, updated_at)
  values (new.product_id, new.location_id, 0, now())
  on conflict (product_id, location_id) do nothing;

  select quantity
    into current_qty
  from public.inventory_stock
  where product_id = new.product_id
    and location_id = new.location_id
  for update;

  if current_qty + delta < 0 then
    raise exception 'Stock insuficiente para producto % en ubicación %', new.product_id, new.location_id;
  end if;

  update public.inventory_stock
     set quantity   = quantity + delta,
         updated_at = now()
   where product_id = new.product_id
     and location_id = new.location_id;

  return new;
end;
$$;

drop trigger if exists trg_inventory_apply_movement on public.inventory_movements;
create trigger trg_inventory_apply_movement
after insert on public.inventory_movements
for each row
execute function public.fn_inventory_apply_movement();

-- =====================================================
-- FUNCIÓN + TRIGGERS DE updated_at
-- =====================================================

create or replace function public.fn_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_inventory_categories_updated_at on public.inventory_categories;
create trigger trg_inventory_categories_updated_at
before update on public.inventory_categories
for each row execute function public.fn_set_updated_at();

drop trigger if exists trg_inventory_suppliers_updated_at on public.inventory_suppliers;
create trigger trg_inventory_suppliers_updated_at
before update on public.inventory_suppliers
for each row execute function public.fn_set_updated_at();

drop trigger if exists trg_inventory_locations_updated_at on public.inventory_locations;
create trigger trg_inventory_locations_updated_at
before update on public.inventory_locations
for each row execute function public.fn_set_updated_at();

drop trigger if exists trg_inventory_products_updated_at on public.inventory_products;
create trigger trg_inventory_products_updated_at
before update on public.inventory_products
for each row execute function public.fn_set_updated_at();

-- =====================================================
-- RLS (ROW LEVEL SECURITY) + POLÍTICAS
-- =====================================================

alter table public.inventory_categories enable row level security;
alter table public.inventory_suppliers enable row level security;
alter table public.inventory_locations enable row level security;
alter table public.inventory_products enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.inventory_stock enable row level security;

drop policy if exists p_inventory_categories_auth_all on public.inventory_categories;
create policy p_inventory_categories_auth_all
on public.inventory_categories
for all
to authenticated
using (true)
with check (true);

drop policy if exists p_inventory_suppliers_auth_all on public.inventory_suppliers;
create policy p_inventory_suppliers_auth_all
on public.inventory_suppliers
for all
to authenticated
using (true)
with check (true);

drop policy if exists p_inventory_locations_auth_all on public.inventory_locations;
create policy p_inventory_locations_auth_all
on public.inventory_locations
for all
to authenticated
using (true)
with check (true);

drop policy if exists p_inventory_products_auth_all on public.inventory_products;
create policy p_inventory_products_auth_all
on public.inventory_products
for all
to authenticated
using (true)
with check (true);

drop policy if exists p_inventory_movements_auth_all on public.inventory_movements;
create policy p_inventory_movements_auth_all
on public.inventory_movements
for all
to authenticated
using (true)
with check (true);

drop policy if exists p_inventory_stock_auth_all on public.inventory_stock;
create policy p_inventory_stock_auth_all
on public.inventory_stock
for all
to authenticated
using (true)
with check (true);

-- =====================================================
-- DATOS DE EJEMPLO
-- =====================================================

-- Categorías
insert into public.inventory_categories (id, name, description) values
  ('a1000000-0000-0000-0000-000000000001', 'Armazones',        'Monturas para lentes oftálmicos y solares'),
  ('a1000000-0000-0000-0000-000000000002', 'Lentes Oftálmicos', 'Lentes con graduación y neutros'),
  ('a1000000-0000-0000-0000-000000000003', 'Lentes de Contacto','Lentes de contacto blandos y rígidos'),
  ('a1000000-0000-0000-0000-000000000004', 'Soluciones',        'Líquidos de limpieza y conservación'),
  ('a1000000-0000-0000-0000-000000000005', 'Accesorios',        'Estuches, cadenas, paños y herramientas')
on conflict (name) do nothing;

-- Proveedores
insert into public.inventory_suppliers (id, legal_name, trade_name, tax_id, email, phone) values
  ('b2000000-0000-0000-0000-000000000001', 'Luxottica de México S.A. de C.V.', 'Luxottica',    'LMX840101AAA', 'ventas@luxottica.mx', '+52 55 5000-1111'),
  ('b2000000-0000-0000-0000-000000000002', 'Safilo Group México S.A.',          'Safilo',       'SGM920301BBB', 'pedidos@safilo.mx',   '+52 55 5000-2222'),
  ('b2000000-0000-0000-0000-000000000003', 'Essilor de México S.A. de C.V.',    'Essilor',      'EMX870601CCC', 'lentes@essilor.mx',   '+52 55 5000-3333'),
  ('b2000000-0000-0000-0000-000000000004', 'CooperVision México',               'CooperVision', 'CVM010101DDD', 'contacto@cooper.mx',  '+52 55 5000-4444')
on conflict do nothing;

-- Ubicaciones / almacenes
insert into public.inventory_locations (id, code, name, description) values
  ('c3000000-0000-0000-0000-000000000001', 'ALM-CENTRAL', 'Almacén Central',      'Bodega principal de la óptica'),
  ('c3000000-0000-0000-0000-000000000002', 'VIT-01',      'Vitrina 1 – Armazones','Exhibidor frontal, armazones adulto'),
  ('c3000000-0000-0000-0000-000000000003', 'VIT-02',      'Vitrina 2 – Solar',    'Exhibidor lentes solares'),
  ('c3000000-0000-0000-0000-000000000004', 'LAB',         'Laboratorio',          'Área de corte y montaje de lentes')
on conflict (code) do nothing;

-- Productos
insert into public.inventory_products (id, sku, name, description, category_id, supplier_id, unit, cost, price, min_stock, max_stock) values
  ('d4000000-0000-0000-0000-000000000001', 'ARM-RAY-001', 'Ray-Ban RB5154 Negro',          'Armazón clubmaster acetato negro',   'a1000000-0000-0000-0000-000000000001', 'b2000000-0000-0000-0000-000000000001', 'pieza',   850.00, 1750.00,  3, 20),
  ('d4000000-0000-0000-0000-000000000002', 'ARM-OAK-001', 'Oakley OX8046 Gris',            'Armazón metálico para hombre',       'a1000000-0000-0000-0000-000000000001', 'b2000000-0000-0000-0000-000000000001', 'pieza',   950.00, 1950.00,  3, 15),
  ('d4000000-0000-0000-0000-000000000003', 'LEN-ESS-001', 'Essilor Varilux C Serie',       'Lente progresivo alta definición',   'a1000000-0000-0000-0000-000000000002', 'b2000000-0000-0000-0000-000000000003', 'par',    1200.00, 3200.00,  5, 30),
  ('d4000000-0000-0000-0000-000000000004', 'LEN-ESS-002', 'Essilor Crizal Forte UV',       'Lente monofocal antirreflejante',    'a1000000-0000-0000-0000-000000000002', 'b2000000-0000-0000-0000-000000000003', 'par',     650.00, 1800.00,  5, 40),
  ('d4000000-0000-0000-0000-000000000005', 'LC-CVI-001',  'CooperVision Biofinity',        'Lente de contacto mensual silicona', 'a1000000-0000-0000-0000-000000000003', 'b2000000-0000-0000-0000-000000000004', 'caja',    280.00,  520.00, 10, 60),
  ('d4000000-0000-0000-0000-000000000006', 'LC-CVI-002',  'CooperVision 1 Day Clariti',    'Lente de contacto diario',           'a1000000-0000-0000-0000-000000000003', 'b2000000-0000-0000-0000-000000000004', 'caja',    320.00,  580.00, 10, 60),
  ('d4000000-0000-0000-0000-000000000007', 'SOL-CVI-001', 'Solución SOLO-care Aqua 360ml', 'Solución multipropósito',            'a1000000-0000-0000-0000-000000000004', 'b2000000-0000-0000-0000-000000000004', 'botella',  85.00,  165.00, 12, 80),
  ('d4000000-0000-0000-0000-000000000008', 'ACC-EST-001', 'Estuche rígido universal',      'Estuche con limpiador y paño',       'a1000000-0000-0000-0000-000000000005', null,                                   'pieza',    45.00,   95.00,  8, 50)
on conflict (sku) do nothing;

-- Stock inicial (entradas al Almacén Central via movimientos)
insert into public.inventory_movements (product_id, location_id, movement_type, quantity, unit_cost, note) values
  ('d4000000-0000-0000-0000-000000000001', 'c3000000-0000-0000-0000-000000000001', 'in', 10, 850.00,  'Carga inicial de inventario'),
  ('d4000000-0000-0000-0000-000000000002', 'c3000000-0000-0000-0000-000000000001', 'in',  8, 950.00,  'Carga inicial de inventario'),
  ('d4000000-0000-0000-0000-000000000003', 'c3000000-0000-0000-0000-000000000001', 'in', 20, 1200.00, 'Carga inicial de inventario'),
  ('d4000000-0000-0000-0000-000000000004', 'c3000000-0000-0000-0000-000000000001', 'in', 25,  650.00, 'Carga inicial de inventario'),
  ('d4000000-0000-0000-0000-000000000005', 'c3000000-0000-0000-0000-000000000001', 'in', 30,  280.00, 'Carga inicial de inventario'),
  ('d4000000-0000-0000-0000-000000000006', 'c3000000-0000-0000-0000-000000000001', 'in', 30,  320.00, 'Carga inicial de inventario'),
  ('d4000000-0000-0000-0000-000000000007', 'c3000000-0000-0000-0000-000000000001', 'in', 40,   85.00, 'Carga inicial de inventario'),
  ('d4000000-0000-0000-0000-000000000008', 'c3000000-0000-0000-0000-000000000001', 'in', 25,   45.00, 'Carga inicial de inventario');

-- Traslado de armazones desde Almacén Central a Vitrina 1
insert into public.inventory_movements (product_id, location_id, movement_type, quantity, note) values
  ('d4000000-0000-0000-0000-000000000001', 'c3000000-0000-0000-0000-000000000001', 'out', 5, 'Traslado a Vitrina 1'),
  ('d4000000-0000-0000-0000-000000000002', 'c3000000-0000-0000-0000-000000000001', 'out', 4, 'Traslado a Vitrina 1'),
  ('d4000000-0000-0000-0000-000000000001', 'c3000000-0000-0000-0000-000000000002', 'in',  5, 'Recepción desde Almacén Central'),
  ('d4000000-0000-0000-0000-000000000002', 'c3000000-0000-0000-0000-000000000002', 'in',  4, 'Recepción desde Almacén Central');
