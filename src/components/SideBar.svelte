<script>
  export let currentRoute = '/dashboard';
  export let onNavigate = (_path) => {};

  const navItems = [
    { path: '/dashboard', label: 'Panel', icon: '🏠' },
    // Añade aquí más páginas cuando las crees:
    // { path: '/pacientes', label: 'Pacientes', icon: '👤' },
    // { path: '/citas',     label: 'Citas',     icon: '📅' },
    // { path: '/reportes',  label: 'Reportes',  icon: '📊' },
  ];
</script>

<style>
  .sidebar {
    position: fixed;
    top: 0;
    left: 0;
    width: 220px;
    height: 100vh;
    background: linear-gradient(180deg, var(--primary, #02d3ce) 0%, var(--secondary, #a5ba07) 100%);
    display: flex;
    flex-direction: column;
    z-index: 110;
    border-right: none;
    box-shadow: 2px 0 12px rgba(2,211,206,0.15);
    padding-top: 0;
  }

  .sidebar-brand {
    height: 56px;
    display: flex;
    align-items: center;
    padding: 0 1.25rem;
    background: rgba(0,0,0,0.12);
    border-bottom: 1px solid rgba(255,255,255,0.20);
    gap: 0.6rem;
  }

  .brand-dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    background: var(--secondary, #a5ba07);
    flex-shrink: 0;
  }

  .brand-name {
    color: #fff;
    font-weight: 700;
    font-size: 1rem;
    letter-spacing: 0.04em;
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

  .nav-btn {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    width: 100%;
    background: transparent;
    border: none;
    color: rgba(255,255,255,0.85);
    font-size: 0.9rem;
    padding: 0.65rem 1.25rem;
    cursor: pointer;
    text-align: left;
    border-left: 3px solid transparent;
    transition: background 0.15s, color 0.15s, border-color 0.15s;
    border-radius: 0 6px 6px 0;
    margin: 1px 0;
  }

  .nav-btn:hover {
    background: rgba(255,255,255,0.15);
    color: #fff;
  }

  .nav-btn.active {
    background: rgba(255,255,255,0.22);
    color: #fff;
    border-left-color: #fff;
    font-weight: 600;
  }

  .nav-icon {
    font-size: 1rem;
    width: 20px;
    text-align: center;
    flex-shrink: 0;
  }

  .sidebar-footer {
    padding: 1rem 1.25rem;
    border-top: 1px solid rgba(255,255,255,0.20);
    color: rgba(255,255,255,0.40);
    font-size: 0.7rem;
    text-align: center;
  }
</style>

<aside class="sidebar">
  <div class="sidebar-brand">
    <span class="brand-dot"></span>
    <span class="brand-name">OpticaFT</span>
  </div>

  <nav>
    <p class="nav-section-title">Menú</p>
    {#each navItems as item}
      <button
        class="nav-btn {currentRoute === item.path ? 'active' : ''}"
        on:click={() => onNavigate(item.path)}
      >
        <span class="nav-icon">{item.icon}</span>
        {item.label}
      </button>
    {/each}
  </nav>

  <div class="sidebar-footer">v0.1.0</div>
</aside>
