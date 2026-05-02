<script>
  import { supabase } from '../lib/supabaseClient.js';

  let userEmail = '';
  const modules = [
    { name: 'Inventario', icon: '📦', enabled: true, path: '/inventario' },
    { name: 'Pacientes', icon: '🧑‍⚕️', enabled: false },
    { name: 'Clientes', icon: '👥', enabled: false },
    { name: 'Citas', icon: '📅', enabled: false },
    { name: 'Facturación', icon: '🧾', enabled: false },
    { name: 'Analítica de datos', icon: '📊', enabled: false }
  ];

  async function loadUser() {
    try {
      const { data, error } = await supabase.auth.getUser();
      if (data?.user) userEmail = data.user.email || '';
    } catch (e) {
      // ignore — show generic view
    }
  }


  loadUser();

  function openModule(module) {
    if (!module.enabled || !module.path) return;
    window.location.assign(`.${module.path}`);
  }

</script>

<style>
  .dash {
    padding: 2rem;
    font-family: system-ui, -apple-system, 'Segoe UI', Roboto, Arial;
  }

  .title {
    margin: 0 0 0.35rem;
    font-size: clamp(1.35rem, 2.6vw, 1.9rem);
    color: #1F1F1F;
  }

  .subtitle {
    margin: 0 0 1.5rem;
    color: #4b4b4b;
    font-size: 0.95rem;
  }

  .cards-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
  }

  .module-card {
    border: 1px solid #e8ecec;
    background: #f7f9f9;
    border-radius: 14px;
    padding: 1rem;
    min-height: 120px;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    align-items: flex-start;
    opacity: 0.72;
    cursor: not-allowed;
  }

  .module-card.enabled {
    opacity: 1;
    cursor: pointer;
    background: #ffffff;
    border-color: #cbe9df;
    box-shadow: 0 8px 18px rgba(102, 215, 183, 0.14);
  }

  .module-card.enabled:hover {
    transform: translateY(-1px);
    box-shadow: 0 10px 20px rgba(102, 215, 183, 0.2);
  }

  .module-icon {
    font-size: 1.35rem;
  }

  .module-name {
    margin: 0.6rem 0 0.25rem;
    font-size: 1rem;
    font-weight: 650;
    color: #1F1F1F;
  }

  .module-state {
    margin: 0;
    font-size: 0.78rem;
    color: #5f6a6a;
    background: #edf1f1;
    border: 1px solid #dde4e4;
    border-radius: 999px;
    padding: 0.2rem 0.55rem;
  }

  .module-state.active {
    color: #0e5d45;
    background: #dff4ec;
    border-color: #bde5d5;
  }
</style>

<div class="dash">
  <h1 class="title">Panel principal</h1>
  <p class="subtitle">Selecciona un módulo para continuar (en preparación).</p>

  <div class="cards-grid">
    {#each modules as module}
      <button
        class="module-card {module.enabled ? 'enabled' : ''}"
        disabled={!module.enabled}
        aria-disabled={!module.enabled}
        title={module.enabled ? `Abrir ${module.name}` : 'Próximamente'}
        on:click={() => openModule(module)}
      >
        <span class="module-icon" aria-hidden="true">{module.icon}</span>
        <div>
          <p class="module-name">{module.name}</p>
          <p class="module-state {module.enabled ? 'active' : ''}">
            {module.enabled ? 'Disponible' : 'Deshabilitado'}
          </p>
        </div>
      </button>
    {/each}
  </div>

</div>
