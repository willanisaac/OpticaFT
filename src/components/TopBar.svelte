<script>
  import vexalLogo from '../assets/vexal.png';

  export let userEmail = '';
  export let onSignOut = () => {};

  let searchQuery = '';
</script>

<style>
  .topbar {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    height: 60px;
    background: linear-gradient(90deg, #ffffff 0%, #ffffff 8%, #66D7B7 34%, #1F1F1F 100%);
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 1.5rem;
    gap: 1rem;
    z-index: 210;
    border-bottom: 1px solid rgba(255,255,255,0.45);
    box-shadow: 0 8px 20px rgba(31,31,31,0.22);
  }

  .topbar-left {
    display: flex;
    align-items: center;
    gap: 0.6rem;
  }

  .brand-chip {
    display: inline-flex;
    align-items: center;
    gap: 0.55rem;
    background: rgba(255,255,255,0.70);
    border: 1px solid #ffffff;
    border-radius: 999px;
    padding: 0.24rem 0.7rem 0.24rem 0.3rem;
    backdrop-filter: blur(4px);
  }

  .brand-logo {
    width: auto;
    height: 32px;
    object-fit: contain;
    border-radius: 0;
    border: none;
    display: block;
  }

  .search-wrapper {
    flex: 1;
    max-width: 420px;
    display: flex;
    align-items: center;
    background: rgba(255,255,255,0.16);
    border: 1px solid rgba(255,255,255,0.35);
    border-radius: 8px;
    padding: 0 0.75rem;
    gap: 0.5rem;
  }

  .search-icon {
    color: rgba(255,255,255,0.85);
    font-size: 0.9rem;
    flex-shrink: 0;
  }

  .search-input {
    background: transparent;
    border: none;
    outline: none;
    color: #ffffff;
    font-size: 0.875rem;
    width: 100%;
    padding: 0.4rem 0;
  }

  .search-input::placeholder {
    color: rgba(255,255,255,0.70);
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
    color: #ffffff;
    font-size: 0.875rem;
  }

  .user-avatar {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    background: #ffffff;
    color: #1F1F1F;
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
    color: #ffffff;
    border-radius: 6px;
    padding: 0.3rem 0.85rem;
    font-size: 0.8rem;
    cursor: pointer;
    transition: background 0.18s, color 0.18s;
    white-space: nowrap;
    font-weight: 600;
  }

  .signout-btn:hover {
    background: #ffffff;
    color: #1F1F1F;
  }

  @media (max-width: 860px) {
    .topbar {
      padding: 0 0.8rem;
      gap: 0.55rem;
    }

    .search-wrapper {
      max-width: none;
      min-width: 0;
    }

    .user-email {
      display: none;
    }

    .signout-btn {
      padding: 0.28rem 0.65rem;
      font-size: 0.74rem;
    }
  }

  @media (max-width: 560px) {
    .search-wrapper {
      display: none;
    }

    .brand-chip {
      padding-right: 0.45rem;
    }
  }
</style>

<header class="topbar">
  <div class="topbar-left">
    <div class="brand-chip">
      <img class="brand-logo" src={vexalLogo} alt="VEXAL" />
    </div>
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
