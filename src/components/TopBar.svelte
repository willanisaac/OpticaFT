<script>
  export let userEmail = '';
  export let onSignOut = () => {};

  let searchQuery = '';
</script>

<style>
  .topbar {
    position: fixed;
    top: 0;
    left: 220px;
    right: 0;
    height: 56px;
    background: linear-gradient(135deg, var(--primary, #02d3ce) 0%, var(--secondary, #a5ba07) 100%);
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 1.5rem;
    gap: 1rem;
    z-index: 100;
    border-bottom: none;
    box-shadow: 0 2px 12px rgba(2,211,206,0.18);
  }

  .topbar-left {
    display: flex;
    align-items: center;
    gap: 0.75rem;
  }

  .topbar-title {
    color: #fff;
    font-weight: 700;
    font-size: 1.1rem;
    letter-spacing: 0.02em;
  }

  .search-wrapper {
    flex: 1;
    max-width: 380px;
    display: flex;
    align-items: center;
    background: rgba(255,255,255,0.20);
    border: 1px solid rgba(255,255,255,0.45);
    border-radius: 8px;
    padding: 0 0.75rem;
    gap: 0.5rem;
  }

  .search-icon {
    color: rgba(255,255,255,0.80);
    font-size: 0.9rem;
    flex-shrink: 0;
  }

  .search-input {
    background: transparent;
    border: none;
    outline: none;
    color: #fff;
    font-size: 0.875rem;
    width: 100%;
    padding: 0.4rem 0;
  }

  .search-input::placeholder {
    color: rgba(255,255,255,0.50);
  }

  .topbar-right {
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .user-info {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    color: #fff;
    font-size: 0.875rem;
  }

  .user-avatar {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    background: var(--secondary, #a5ba07);
    color: #fff;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 700;
    font-size: 0.85rem;
    flex-shrink: 0;
  }

  .signout-btn {
    background: transparent;
    border: 1px solid rgba(255,255,255,0.70);
    color: #fff;
    border-radius: 6px;
    padding: 0.3rem 0.85rem;
    font-size: 0.8rem;
    cursor: pointer;
    transition: background 0.18s, color 0.18s;
    white-space: nowrap;
    font-weight: 600;
  }

  .signout-btn:hover {
    background: rgba(255,255,255,0.90);
    color: var(--dark, #513e37);
  }
</style>

<header class="topbar">
  <div class="topbar-left">
    <span class="topbar-title">OpticaFT</span>
  </div>

  <div class="search-wrapper">
    <span class="search-icon">🔍</span>
    <input
      class="search-input"
      type="text"
      placeholder="Buscar..."
      bind:value={searchQuery}
      disabled
    />
  </div>

  <div class="topbar-right">
    {#if userEmail}
      <div class="user-info">
        <div class="user-avatar">{userEmail.charAt(0).toUpperCase()}</div>
        <span class="user-email">{userEmail}</span>
      </div>
    {/if}
    <button class="signout-btn" on:click={onSignOut}>Cerrar sesión</button>
  </div>
</header>
