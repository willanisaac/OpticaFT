<script>
  import { onMount } from 'svelte';
  import Auth from './pages/Auth.svelte';
  import Dashboard from './pages/Dashboard.svelte';
  import TopBar from './components/TopBar.svelte';
  import SideBar from './components/SideBar.svelte';
  import { supabase } from './lib/supabaseClient.js';

  let currentRoute = '/';
  let CurrentComponent = Auth;
  let userEmail = '';

  const AUTH_ROUTES = ['/auth'];
  $: showShell = !AUTH_ROUTES.includes(currentRoute);

  function normalizePath(pathname) {
    if (!pathname || pathname === '/') return '/auth';
    if (pathname.length > 1 && pathname.endsWith('/')) return pathname.slice(0, -1);
    return pathname;
  }

  function resolveComponent(pathname) {
    switch (pathname) {
      case '/auth':      return Auth;
      case '/dashboard': return Dashboard;
      default:           return Auth;
    }
  }

  function navigate(path) {
    window.history.pushState(null, '', path);
    syncRoute();
  }

  function syncRoute({ replace = false } = {}) {
    const normalized = normalizePath(window.location.pathname);
    currentRoute = normalized;
    CurrentComponent = resolveComponent(normalized);
    if (replace && window.location.pathname !== normalized) {
      window.history.replaceState(null, '', normalized);
    }
  }

  async function handleSignOut() {
    try { await supabase.auth.signOut(); } catch (_) {}
    navigate('/auth');
  }

  onMount(async () => {
    syncRoute({ replace: true });
    window.addEventListener('popstate', syncRoute);

    // Load logged-in user email
    try {
      const { data } = await supabase.auth.getUser();
      if (data?.user) userEmail = data.user.email || '';
    } catch (_) {}

    // Keep userEmail in sync when auth state changes
    supabase.auth.onAuthStateChange((_event, session) => {
      userEmail = session?.user?.email || '';
    });

    return () => window.removeEventListener('popstate', syncRoute);
  });
</script>

<style>

  .shell-content {
    margin-left: 220px;
    padding-top: 56px;
    flex: 1;
    min-height: 100vh;
    box-sizing: border-box;
  }
</style>

{#if showShell}
  <SideBar {currentRoute} onNavigate={navigate} />
  <TopBar {userEmail} onSignOut={handleSignOut} />
  <div class="shell-content">
    <svelte:component this={CurrentComponent} />
  </div>
{:else}
  <svelte:component this={CurrentComponent} />
{/if}
