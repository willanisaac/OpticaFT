<script>
  import { onMount } from 'svelte';
  import { supabase } from '../lib/supabaseClient.js';

  let loading = true;
  let busy = false;
  let error = null;
  let notice = '';
  let activeTab = 'overview';
  let adminEntity = 'categories';

  let summary = { totalProducts: 0, lowStock: 0, totalValue: 0 };
  let items = [];
  let movements = [];

  let categories = [];
  let suppliers = [];
  let locations = [];
  let products = [];

  let categoryEditId = null;
  let supplierEditId = null;
  let locationEditId = null;
  let productEditId = null;

  let categoryForm = { name: '', description: '' };
  let supplierForm = { legal_name: '', trade_name: '', tax_id: '', email: '', phone: '', address: '' };
  let locationForm = { code: '', name: '', description: '' };
  let productForm = {
    sku: '',
    name: '',
    description: '',
    category_id: '',
    supplier_id: '',
    unit: 'pieza',
    cost: 0,
    price: 0,
    min_stock: 0,
    max_stock: '',
    is_active: true
  };

  const currency = new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN'
  });

  function stockStatus(item) {
    return item.stock <= item.min ? 'Crítico' : 'Disponible';
  }

  function movementLabel(type) {
    return { in: 'Entrada', out: 'Salida', adjustment: 'Ajuste' }[type] ?? type;
  }

  function normalizeNullable(value) {
    if (value === null || value === undefined) return null;
    const text = String(value).trim();
    return text.length ? text : null;
  }

  function toNumber(value, fallback = 0) {
    const n = Number(value);
    return Number.isFinite(n) ? n : fallback;
  }

  function resetCategoryForm() {
    categoryEditId = null;
    categoryForm = { name: '', description: '' };
  }

  function resetSupplierForm() {
    supplierEditId = null;
    supplierForm = { legal_name: '', trade_name: '', tax_id: '', email: '', phone: '', address: '' };
  }

  function resetLocationForm() {
    locationEditId = null;
    locationForm = { code: '', name: '', description: '' };
  }

  function resetProductForm() {
    productEditId = null;
    productForm = {
      sku: '',
      name: '',
      description: '',
      category_id: '',
      supplier_id: '',
      unit: 'pieza',
      cost: 0,
      price: 0,
      min_stock: 0,
      max_stock: '',
      is_active: true
    };
  }

  async function withBusy(task, okMessage = '') {
    try {
      busy = true;
      error = null;
      await task();
      if (okMessage) notice = okMessage;
      await refreshAll();
    } catch (e) {
      notice = '';
      error = e.message;
    } finally {
      busy = false;
    }
  }

  onMount(async () => {
    await refreshAll();
    loading = false;
  });

  async function refreshAll() {
    try {
      await Promise.all([
        loadStock(),
        loadMovements(),
        loadCategories(),
        loadSuppliers(),
        loadLocations(),
        loadProducts()
      ]);
    } catch (e) {
      notice = '';
      error = e.message;
    }
  }

  async function loadStock() {
    const { data, error: err } = await supabase
      .from('inventory_stock')
      .select(`
        quantity,
        inventory_products (
          sku, name, min_stock, price, cost,
          inventory_categories ( name )
        ),
        inventory_locations ( name )
      `)
      .order('quantity', { ascending: true });

    if (err) throw new Error(err.message);

    items = (data ?? []).map((row) => ({
      sku: row.inventory_products?.sku ?? '—',
      name: row.inventory_products?.name ?? '—',
      category: row.inventory_products?.inventory_categories?.name ?? '—',
      location: row.inventory_locations?.name ?? '—',
      stock: row.quantity,
      min: row.inventory_products?.min_stock ?? 0,
      price: row.inventory_products?.price ?? 0,
      cost: row.inventory_products?.cost ?? 0
    }));

    const productSkus = new Set(items.map((i) => i.sku));
    summary.totalProducts = productSkus.size;
    summary.lowStock = items.filter((i) => i.stock <= i.min).length;
    summary.totalValue = items.reduce((acc, i) => acc + i.stock * i.cost, 0);
  }

  async function loadMovements() {
    const { data, error: err } = await supabase
      .from('inventory_movements')
      .select(`
        moved_at, movement_type, quantity, note,
        inventory_products ( sku ),
        inventory_locations ( name )
      `)
      .order('moved_at', { ascending: false })
      .limit(20);

    if (err) throw new Error(err.message);

    movements = (data ?? []).map((row) => ({
      date: row.moved_at?.slice(0, 10) ?? '—',
      type: movementLabel(row.movement_type),
      sku: row.inventory_products?.sku ?? '—',
      location: row.inventory_locations?.name ?? '—',
      qty: row.quantity,
      note: row.note ?? ''
    }));
  }

  async function loadCategories() {
    const { data, error: err } = await supabase
      .from('inventory_categories')
      .select('id, name, description')
      .order('name', { ascending: true });
    if (err) throw new Error(err.message);
    categories = data ?? [];
  }

  async function loadSuppliers() {
    const { data, error: err } = await supabase
      .from('inventory_suppliers')
      .select('id, legal_name, trade_name, tax_id, email, phone, address')
      .order('legal_name', { ascending: true });
    if (err) throw new Error(err.message);
    suppliers = data ?? [];
  }

  async function loadLocations() {
    const { data, error: err } = await supabase
      .from('inventory_locations')
      .select('id, code, name, description')
      .order('name', { ascending: true });
    if (err) throw new Error(err.message);
    locations = data ?? [];
  }

  async function loadProducts() {
    const { data, error: err } = await supabase
      .from('inventory_products')
      .select(`
        id, sku, name, description, category_id, supplier_id, unit,
        cost, price, min_stock, max_stock, is_active,
        inventory_categories ( name ),
        inventory_suppliers ( legal_name )
      `)
      .order('name', { ascending: true });
    if (err) throw new Error(err.message);
    products = data ?? [];
  }

  async function saveCategory() {
    const payload = {
      name: categoryForm.name.trim(),
      description: normalizeNullable(categoryForm.description)
    };

    if (!payload.name) {
      error = 'La categoría requiere nombre.';
      return;
    }

    await withBusy(async () => {
      if (categoryEditId) {
        const { error: err } = await supabase.from('inventory_categories').update(payload).eq('id', categoryEditId);
        if (err) throw new Error(err.message);
      } else {
        const { error: err } = await supabase.from('inventory_categories').insert(payload);
        if (err) throw new Error(err.message);
      }
      resetCategoryForm();
    }, 'Categoría guardada.');
  }

  function editCategory(row) {
    categoryEditId = row.id;
    categoryForm = { name: row.name ?? '', description: row.description ?? '' };
  }

  async function deleteCategory(id) {
    if (!confirm('¿Eliminar esta categoría?')) return;
    await withBusy(async () => {
      const { error: err } = await supabase.from('inventory_categories').delete().eq('id', id);
      if (err) throw new Error(err.message);
      if (categoryEditId === id) resetCategoryForm();
    }, 'Categoría eliminada.');
  }

  async function saveSupplier() {
    const payload = {
      legal_name: supplierForm.legal_name.trim(),
      trade_name: normalizeNullable(supplierForm.trade_name),
      tax_id: normalizeNullable(supplierForm.tax_id),
      email: normalizeNullable(supplierForm.email),
      phone: normalizeNullable(supplierForm.phone),
      address: normalizeNullable(supplierForm.address)
    };

    if (!payload.legal_name) {
      error = 'El proveedor requiere razón social.';
      return;
    }

    await withBusy(async () => {
      if (supplierEditId) {
        const { error: err } = await supabase.from('inventory_suppliers').update(payload).eq('id', supplierEditId);
        if (err) throw new Error(err.message);
      } else {
        const { error: err } = await supabase.from('inventory_suppliers').insert(payload);
        if (err) throw new Error(err.message);
      }
      resetSupplierForm();
    }, 'Proveedor guardado.');
  }

  function editSupplier(row) {
    supplierEditId = row.id;
    supplierForm = {
      legal_name: row.legal_name ?? '',
      trade_name: row.trade_name ?? '',
      tax_id: row.tax_id ?? '',
      email: row.email ?? '',
      phone: row.phone ?? '',
      address: row.address ?? ''
    };
  }

  async function deleteSupplier(id) {
    if (!confirm('¿Eliminar este proveedor?')) return;
    await withBusy(async () => {
      const { error: err } = await supabase.from('inventory_suppliers').delete().eq('id', id);
      if (err) throw new Error(err.message);
      if (supplierEditId === id) resetSupplierForm();
    }, 'Proveedor eliminado.');
  }

  async function saveLocation() {
    const payload = {
      code: locationForm.code.trim(),
      name: locationForm.name.trim(),
      description: normalizeNullable(locationForm.description)
    };

    if (!payload.code || !payload.name) {
      error = 'La ubicación requiere código y nombre.';
      return;
    }

    await withBusy(async () => {
      if (locationEditId) {
        const { error: err } = await supabase.from('inventory_locations').update(payload).eq('id', locationEditId);
        if (err) throw new Error(err.message);
      } else {
        const { error: err } = await supabase.from('inventory_locations').insert(payload);
        if (err) throw new Error(err.message);
      }
      resetLocationForm();
    }, 'Ubicación guardada.');
  }

  function editLocation(row) {
    locationEditId = row.id;
    locationForm = {
      code: row.code ?? '',
      name: row.name ?? '',
      description: row.description ?? ''
    };
  }

  async function deleteLocation(id) {
    if (!confirm('¿Eliminar esta ubicación?')) return;
    await withBusy(async () => {
      const { error: err } = await supabase.from('inventory_locations').delete().eq('id', id);
      if (err) throw new Error(err.message);
      if (locationEditId === id) resetLocationForm();
    }, 'Ubicación eliminada.');
  }

  async function saveProduct() {
    const payload = {
      sku: productForm.sku.trim(),
      name: productForm.name.trim(),
      description: normalizeNullable(productForm.description),
      category_id: normalizeNullable(productForm.category_id),
      supplier_id: normalizeNullable(productForm.supplier_id),
      unit: normalizeNullable(productForm.unit) ?? 'pieza',
      cost: toNumber(productForm.cost, 0),
      price: toNumber(productForm.price, 0),
      min_stock: toNumber(productForm.min_stock, 0),
      max_stock: productForm.max_stock === '' ? null : toNumber(productForm.max_stock, 0),
      is_active: !!productForm.is_active
    };

    if (!payload.sku || !payload.name) {
      error = 'El producto requiere SKU y nombre.';
      return;
    }

    await withBusy(async () => {
      if (productEditId) {
        const { error: err } = await supabase.from('inventory_products').update(payload).eq('id', productEditId);
        if (err) throw new Error(err.message);
      } else {
        const { error: err } = await supabase.from('inventory_products').insert(payload);
        if (err) throw new Error(err.message);
      }
      resetProductForm();
    }, 'Producto guardado.');
  }

  function editProduct(row) {
    productEditId = row.id;
    productForm = {
      sku: row.sku ?? '',
      name: row.name ?? '',
      description: row.description ?? '',
      category_id: row.category_id ?? '',
      supplier_id: row.supplier_id ?? '',
      unit: row.unit ?? 'pieza',
      cost: row.cost ?? 0,
      price: row.price ?? 0,
      min_stock: row.min_stock ?? 0,
      max_stock: row.max_stock ?? '',
      is_active: row.is_active ?? true
    };
  }

  async function deleteProduct(id) {
    if (!confirm('¿Eliminar este producto?')) return;
    await withBusy(async () => {
      const { error: err } = await supabase.from('inventory_products').delete().eq('id', id);
      if (err) throw new Error(err.message);
      if (productEditId === id) resetProductForm();
    }, 'Producto eliminado.');
  }
</script>

<style>
  .inventory-page {
    padding: 1.25rem;
    display: grid;
    gap: 1rem;
  }

  .header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
  }

  .title {
    margin: 0;
    font-size: 1.35rem;
    color: var(--dark);
  }

  .subtitle {
    margin: 0.2rem 0 0;
    color: rgba(81, 62, 55, 0.8);
    font-size: 0.9rem;
  }

  .tabs {
    display: flex;
    gap: 0.55rem;
    flex-wrap: wrap;
  }

  .tab-btn {
    border: 1px solid rgba(31, 31, 31, 0.18);
    background: #fff;
    color: #2b2b2b;
    border-radius: 999px;
    padding: 0.45rem 0.85rem;
    font-size: 0.82rem;
    font-weight: 600;
    cursor: pointer;
  }

  .tab-btn.active {
    background: #66D7B7;
    border-color: #55c4a5;
    color: #0f3f32;
  }

  .alert {
    margin: 0;
    border-radius: 8px;
    padding: 0.6rem 0.75rem;
    font-size: 0.86rem;
  }

  .alert.error {
    background: rgba(192, 57, 43, 0.12);
    border: 1px solid rgba(192, 57, 43, 0.28);
    color: #8d2b1e;
  }

  .alert.notice {
    background: rgba(102, 215, 183, 0.18);
    border: 1px solid rgba(102, 215, 183, 0.35);
    color: #155243;
  }

  .summary-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 0.75rem;
  }

  .summary-card {
    background: #fff;
    border: 1px solid rgba(102, 215, 183, 0.35);
    border-radius: 10px;
    padding: 0.9rem 1rem;
  }

  .summary-label {
    margin: 0;
    color: rgba(31, 31, 31, 0.6);
    font-size: 0.8rem;
  }

  .summary-value {
    margin: 0.4rem 0 0;
    font-size: 1.35rem;
    font-weight: 700;
    color: var(--dark);
  }

  .panel {
    background: #fff;
    border: 1px solid rgba(102, 215, 183, 0.30);
    border-radius: 12px;
    overflow: hidden;
  }

  .panel-title {
    margin: 0;
    padding: 0.85rem 1rem;
    background: rgba(102, 215, 183, 0.10);
    color: var(--dark);
    font-size: 0.95rem;
    border-bottom: 1px solid rgba(102, 215, 183, 0.20);
  }

  .table-wrap {
    overflow-x: auto;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    min-width: 720px;
  }

  th,
  td {
    padding: 0.7rem 0.9rem;
    text-align: left;
    border-bottom: 1px solid #ececec;
    font-size: 0.86rem;
  }

  th {
    background: #fafafa;
    color: rgba(81, 62, 55, 0.9);
    font-weight: 600;
  }

  .badge {
    display: inline-flex;
    align-items: center;
    padding: 0.18rem 0.55rem;
    border-radius: 999px;
    font-size: 0.74rem;
    font-weight: 600;
  }

  .badge.ok {
    background: rgba(102, 215, 183, 0.25);
    color: #1a6a52;
  }

  .badge.warn {
    background: rgba(255, 99, 71, 0.18);
    color: #8a2f1b;
  }

  .panel-body {
    padding: 0.9rem 1rem 1rem;
    display: grid;
    gap: 0.75rem;
  }

  .form-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
    gap: 0.7rem;
  }

  .field {
    display: grid;
    gap: 0.22rem;
  }

  .field.full {
    grid-column: 1 / -1;
  }

  .field-label {
    font-size: 0.78rem;
    font-weight: 600;
    color: rgba(31, 31, 31, 0.78);
  }

  input,
  select,
  textarea {
    border: 1px solid rgba(31, 31, 31, 0.18);
    border-radius: 8px;
    padding: 0.46rem 0.58rem;
    font-size: 0.86rem;
    font-family: inherit;
  }

  textarea {
    min-height: 72px;
    resize: vertical;
  }

  .actions {
    display: flex;
    flex-wrap: wrap;
    gap: 0.45rem;
  }

  .btn {
    border: 1px solid rgba(31, 31, 31, 0.16);
    background: #fff;
    border-radius: 8px;
    padding: 0.4rem 0.65rem;
    font-size: 0.8rem;
    cursor: pointer;
  }

  .btn.primary {
    background: #66D7B7;
    border-color: #55c4a5;
    color: #0f3f32;
    font-weight: 700;
  }

  .btn.danger {
    border-color: rgba(192, 57, 43, 0.30);
    color: #8d2b1e;
    background: #fff5f2;
  }

  .btn:disabled {
    opacity: 0.55;
    cursor: not-allowed;
  }

  .inline-actions {
    display: inline-flex;
    gap: 0.35rem;
  }

  .admin-toolbar {
    display: flex;
    gap: 0.75rem;
    align-items: end;
  }

  .admin-selector {
    min-width: 260px;
  }
</style>

<div class="inventory-page">
  <div class="header">
    <div>
      <h1 class="title">Control de inventario</h1>
      <p class="subtitle">Vista operativa + administración de catálogo del inventario</p>
    </div>
    <button class="btn" on:click={refreshAll} disabled={busy || loading}>Recargar</button>
  </div>

  <div class="tabs">
    <button
      class="tab-btn {activeTab === 'overview' ? 'active' : ''}"
      on:click={() => (activeTab = 'overview')}
    >
      Ver inventario
    </button>
    <button
      class="tab-btn {activeTab === 'admin' ? 'active' : ''}"
      on:click={() => (activeTab = 'admin')}
    >
      Administración
    </button>
  </div>

  {#if error}
    <p class="alert error">{error}</p>
  {/if}
  {#if notice}
    <p class="alert notice">{notice}</p>
  {/if}

  {#if loading}
    <p style="color: var(--dark); opacity: 0.6;">Cargando datos…</p>
  {:else}
    {#if activeTab === 'overview'}
      <section class="summary-grid">
        <article class="summary-card">
          <p class="summary-label">Productos registrados</p>
          <p class="summary-value">{summary.totalProducts}</p>
        </article>
        <article class="summary-card">
          <p class="summary-label">Productos en stock crítico</p>
          <p class="summary-value">{summary.lowStock}</p>
        </article>
        <article class="summary-card">
          <p class="summary-label">Valor total inventario</p>
          <p class="summary-value">{currency.format(summary.totalValue)}</p>
        </article>
      </section>

      <section class="panel">
        <h2 class="panel-title">Stock por producto</h2>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>SKU</th>
                <th>Producto</th>
                <th>Categoría</th>
                <th>Ubicación</th>
                <th>Stock</th>
                <th>Mínimo</th>
                <th>Estado</th>
              </tr>
            </thead>
            <tbody>
              {#each items as item}
                <tr>
                  <td>{item.sku}</td>
                  <td>{item.name}</td>
                  <td>{item.category}</td>
                  <td>{item.location}</td>
                  <td>{item.stock}</td>
                  <td>{item.min}</td>
                  <td>
                    <span class="badge {stockStatus(item) === 'Crítico' ? 'warn' : 'ok'}">
                      {stockStatus(item)}
                    </span>
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      </section>

      <section class="panel">
        <h2 class="panel-title">Movimientos recientes</h2>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Fecha</th>
                <th>Tipo</th>
                <th>SKU</th>
                <th>Ubicación</th>
                <th>Cantidad</th>
                <th>Observación</th>
              </tr>
            </thead>
            <tbody>
              {#each movements as movement}
                <tr>
                  <td>{movement.date}</td>
                  <td>{movement.type}</td>
                  <td>{movement.sku}</td>
                  <td>{movement.location}</td>
                  <td>{movement.qty}</td>
                  <td>{movement.note}</td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      </section>
    {:else}
      <section class="panel">
        <h2 class="panel-title">Administración</h2>
        <div class="panel-body">
          <div class="admin-toolbar">
            <div class="field admin-selector">
              <span class="field-label">Tabla a administrar</span>
              <select bind:value={adminEntity}>
                <option value="categories">Categorías</option>
                <option value="suppliers">Proveedores</option>
                <option value="locations">Ubicaciones</option>
                <option value="products">Productos</option>
              </select>
            </div>
          </div>

          {#if adminEntity === 'categories'}
            <div class="form-grid">
              <div class="field">
                <span class="field-label">Nombre</span>
                <input bind:value={categoryForm.name} />
              </div>
              <div class="field full">
                <span class="field-label">Descripción</span>
                <textarea bind:value={categoryForm.description}></textarea>
              </div>
            </div>
            <div class="actions">
              <button class="btn primary" on:click={saveCategory} disabled={busy}>
                {categoryEditId ? 'Actualizar' : 'Crear'} categoría
              </button>
              {#if categoryEditId}
                <button class="btn" on:click={resetCategoryForm} disabled={busy}>Cancelar</button>
              {/if}
            </div>
            <div class="table-wrap">
              <table>
                <thead>
                  <tr><th>Nombre</th><th>Descripción</th><th>Acciones</th></tr>
                </thead>
                <tbody>
                  {#each categories as row}
                    <tr>
                      <td>{row.name}</td>
                      <td>{row.description || '—'}</td>
                      <td>
                        <span class="inline-actions">
                          <button class="btn" on:click={() => editCategory(row)} disabled={busy}>Editar</button>
                          <button class="btn danger" on:click={() => deleteCategory(row.id)} disabled={busy}>Eliminar</button>
                        </span>
                      </td>
                    </tr>
                  {/each}
                </tbody>
              </table>
            </div>
          {:else if adminEntity === 'suppliers'}
            <div class="form-grid">
              <div class="field"><span class="field-label">Razón social</span><input bind:value={supplierForm.legal_name} /></div>
              <div class="field"><span class="field-label">Nombre comercial</span><input bind:value={supplierForm.trade_name} /></div>
              <div class="field"><span class="field-label">RFC</span><input bind:value={supplierForm.tax_id} /></div>
              <div class="field"><span class="field-label">Email</span><input bind:value={supplierForm.email} /></div>
              <div class="field"><span class="field-label">Teléfono</span><input bind:value={supplierForm.phone} /></div>
              <div class="field full"><span class="field-label">Dirección</span><textarea bind:value={supplierForm.address}></textarea></div>
            </div>
            <div class="actions">
              <button class="btn primary" on:click={saveSupplier} disabled={busy}>
                {supplierEditId ? 'Actualizar' : 'Crear'} proveedor
              </button>
              {#if supplierEditId}
                <button class="btn" on:click={resetSupplierForm} disabled={busy}>Cancelar</button>
              {/if}
            </div>
            <div class="table-wrap">
              <table>
                <thead>
                  <tr><th>Razón social</th><th>Contacto</th><th>Acciones</th></tr>
                </thead>
                <tbody>
                  {#each suppliers as row}
                    <tr>
                      <td>{row.legal_name}</td>
                      <td>{row.email || '—'} / {row.phone || '—'}</td>
                      <td>
                        <span class="inline-actions">
                          <button class="btn" on:click={() => editSupplier(row)} disabled={busy}>Editar</button>
                          <button class="btn danger" on:click={() => deleteSupplier(row.id)} disabled={busy}>Eliminar</button>
                        </span>
                      </td>
                    </tr>
                  {/each}
                </tbody>
              </table>
            </div>
          {:else if adminEntity === 'locations'}
            <div class="form-grid">
              <div class="field"><span class="field-label">Código</span><input bind:value={locationForm.code} /></div>
              <div class="field"><span class="field-label">Nombre</span><input bind:value={locationForm.name} /></div>
              <div class="field full"><span class="field-label">Descripción</span><textarea bind:value={locationForm.description}></textarea></div>
            </div>
            <div class="actions">
              <button class="btn primary" on:click={saveLocation} disabled={busy}>
                {locationEditId ? 'Actualizar' : 'Crear'} ubicación
              </button>
              {#if locationEditId}
                <button class="btn" on:click={resetLocationForm} disabled={busy}>Cancelar</button>
              {/if}
            </div>
            <div class="table-wrap">
              <table>
                <thead>
                  <tr><th>Código</th><th>Nombre</th><th>Descripción</th><th>Acciones</th></tr>
                </thead>
                <tbody>
                  {#each locations as row}
                    <tr>
                      <td>{row.code}</td>
                      <td>{row.name}</td>
                      <td>{row.description || '—'}</td>
                      <td>
                        <span class="inline-actions">
                          <button class="btn" on:click={() => editLocation(row)} disabled={busy}>Editar</button>
                          <button class="btn danger" on:click={() => deleteLocation(row.id)} disabled={busy}>Eliminar</button>
                        </span>
                      </td>
                    </tr>
                  {/each}
                </tbody>
              </table>
            </div>
          {:else}
            <div class="form-grid">
              <div class="field"><span class="field-label">SKU</span><input bind:value={productForm.sku} /></div>
              <div class="field"><span class="field-label">Nombre</span><input bind:value={productForm.name} /></div>
              <div class="field">
                <span class="field-label">Categoría</span>
                <select bind:value={productForm.category_id}>
                  <option value="">Sin categoría</option>
                  {#each categories as c}
                    <option value={c.id}>{c.name}</option>
                  {/each}
                </select>
              </div>
              <div class="field">
                <span class="field-label">Proveedor</span>
                <select bind:value={productForm.supplier_id}>
                  <option value="">Sin proveedor</option>
                  {#each suppliers as s}
                    <option value={s.id}>{s.legal_name}</option>
                  {/each}
                </select>
              </div>
              <div class="field"><span class="field-label">Unidad</span><input bind:value={productForm.unit} /></div>
              <div class="field"><span class="field-label">Costo</span><input type="number" step="0.01" bind:value={productForm.cost} /></div>
              <div class="field"><span class="field-label">Precio</span><input type="number" step="0.01" bind:value={productForm.price} /></div>
              <div class="field"><span class="field-label">Stock mínimo</span><input type="number" step="0.01" bind:value={productForm.min_stock} /></div>
              <div class="field"><span class="field-label">Stock máximo</span><input type="number" step="0.01" bind:value={productForm.max_stock} /></div>
              <div class="field">
                <span class="field-label">Activo</span>
                <input type="checkbox" bind:checked={productForm.is_active} />
              </div>
              <div class="field full"><span class="field-label">Descripción</span><textarea bind:value={productForm.description}></textarea></div>
            </div>
            <div class="actions">
              <button class="btn primary" on:click={saveProduct} disabled={busy}>
                {productEditId ? 'Actualizar' : 'Crear'} producto
              </button>
              {#if productEditId}
                <button class="btn" on:click={resetProductForm} disabled={busy}>Cancelar</button>
              {/if}
            </div>
            <div class="table-wrap">
              <table>
                <thead>
                  <tr><th>SKU</th><th>Producto</th><th>Categoría</th><th>Proveedor</th><th>Estado</th><th>Acciones</th></tr>
                </thead>
                <tbody>
                  {#each products as row}
                    <tr>
                      <td>{row.sku}</td>
                      <td>{row.name}</td>
                      <td>{row.inventory_categories?.name || '—'}</td>
                      <td>{row.inventory_suppliers?.legal_name || '—'}</td>
                      <td>{row.is_active ? 'Activo' : 'Inactivo'}</td>
                      <td>
                        <span class="inline-actions">
                          <button class="btn" on:click={() => editProduct(row)} disabled={busy}>Editar</button>
                          <button class="btn danger" on:click={() => deleteProduct(row.id)} disabled={busy}>Eliminar</button>
                        </span>
                      </td>
                    </tr>
                  {/each}
                </tbody>
              </table>
            </div>
          {/if}
        </div>
      </section>
    {/if}

  {/if}
</div>
