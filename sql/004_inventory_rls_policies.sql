-- =====================================================
-- MIGRACIÓN: políticas RLS para módulos de inventario
-- Soluciona: "new row violates row-level security policy"
-- =====================================================

begin;

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

commit;
