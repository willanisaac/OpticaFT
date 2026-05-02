<script>
  export let currentRoute = '/dashboard';
  export let collapsed = false;
  export let onNavigate = (_path) => {};
  export let onToggleCollapse = () => {};

  const navItems = [
    { path: '/dashboard', label: 'Panel', icon: '🏠' },
    { path: '/inventario', label: 'Inventario', icon: '📦' },
    // Añade aquí más páginas cuando las crees:
    // { path: '/pacientes', label: 'Pacientes', icon: '👤' },
    // { path: '/citas',     label: 'Citas',     icon: '📅' },
    // { path: '/reportes',  label: 'Reportes',  icon: '📊' },
  ];
</script>

<style>
  .sidebar {
    position: fixed;
    top: 60px;
    left: 0;
    width: var(--sidebar-width, 220px);
    height: calc(100vh - 60px);
    background:
      radial-gradient(120px 120px at 18% 6%, rgba(102,215,183,0.28), transparent 70%),
      linear-gradient(180deg, #262626 0%, #1F1F1F 55%, #141414 100%);
    display: flex;
    flex-direction: column;
    z-index: 110;
    border-right: 1px solid rgba(255,255,255,0.08);
    box-shadow: 4px 0 18px rgba(0,0,0,0.26);
    padding-top: 0;
    transition: width 0.22s ease;
  }

  nav {
    padding: 0.75rem 0;
    flex: 1;
    overflow-y: auto;
  }

  .nav-section-title {
    color: rgba(255,255,255,0.50);
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    padding: 0.75rem 1.25rem 0.25rem;
    font-weight: 600;
  }

  .nav-label {
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .nav-btn {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    width: 100%;
    background: transparent;
    border: none;
    color: rgba(255,255,255,0.85);
    font-size: 0.9rem;
    padding: 0.65rem 1rem;
    cursor: pointer;
    text-align: left;
    border-left: 3px solid transparent;
    transition: background 0.15s, color 0.15s, border-color 0.15s;
    border-radius: 0 6px 6px 0;
    margin: 1px 0;
  }

  .nav-btn:hover {
    background: rgba(255,255,255,0.11);
    color: #fff;
  }

  .nav-btn.active {
    background: linear-gradient(90deg, rgba(102,215,183,0.22), rgba(102,215,183,0.06));
    color: #66D7B7;
    border-left-color: #66D7B7;
    font-weight: 600;
  }

  .nav-icon {
    font-size: 1rem;
    width: 20px;
    text-align: center;
    flex-shrink: 0;
  }

  .sidebar-footer {
    padding: 0.85rem 0.9rem;
    border-top: 1px solid rgba(255,255,255,0.20);
    color: rgba(255,255,255,0.52);
    font-size: 0.7rem;
    text-align: center;
  }

  .collapse-btn {
    width: 100%;
    background: rgba(255,255,255,0.08);
    border: 1px solid rgba(255,255,255,0.22);
    color: #ffffff;
    border-radius: 8px;
    padding: 0.45rem 0.55rem;
    font-size: 0.75rem;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.18s ease;
  }

  .collapse-btn:hover {
    background: rgba(102,215,183,0.22);
  }

  .sidebar.compact .nav-section-title,
  .sidebar.compact .nav-label,
  .sidebar.compact .footer-version,
  .sidebar.compact .collapse-label {
    opacity: 0;
    width: 0;
    margin: 0;
    overflow: hidden;
    pointer-events: none;
  }

  .sidebar.compact .nav-btn {
    justify-content: center;
    border-left-width: 0;
    border-radius: 8px;
    margin: 2px 0.4rem;
    padding: 0.62rem 0.35rem;
  }

  .sidebar.compact .nav-icon {
    width: auto;
    margin: 0;
  }

  .sidebar.compact .sidebar-footer {
    padding-left: 0.4rem;
    padding-right: 0.4rem;
  }

  .sidebar.compact .collapse-btn {
    padding-left: 0.3rem;
    padding-right: 0.3rem;
  }

  @media (max-width: 860px) {
    .sidebar {
      width: var(--sidebar-width, 78px);
    }
  }
</style>

<aside class="sidebar {collapsed ? 'compact' : ''}" style={`--sidebar-width: ${collapsed ? 78 : 220}px`}>
  <nav>
    <p class="nav-section-title">Menú</p>
    {#each navItems as item}
      <button
        class="nav-btn {currentRoute === item.path ? 'active' : ''}"
        on:click={() => onNavigate(item.path)}
        title={collapsed ? item.label : ''}
      >
        <span class="nav-icon">{item.icon}</span>
        <span class="nav-label">{item.label}</span>
      </button>
    {/each}
  </nav>

  <div class="sidebar-footer">
    <button class="collapse-btn" on:click={onToggleCollapse}>
      <span aria-hidden="true">{collapsed ? '⟩' : '⟨'}</span>
      <span class="collapse-label">&nbsp;{collapsed ? 'Expandir' : 'Colapsar'}</span>
    </button>
    <div class="footer-version">v0.1.0</div>
  </div>
</aside>
