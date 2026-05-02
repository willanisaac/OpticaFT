<script>
  import { onMount } from 'svelte';
  import Auth from './pages/Auth.svelte';
  import Dashboard from './pages/Dashboard.svelte';
  import Inventory from './pages/Inventory.svelte';
  import TopBar from './components/TopBar.svelte';
  import SideBar from './components/SideBar.svelte';
  import { supabase } from './lib/supabaseClient.js';

  let currentRoute = '/';
  let CurrentComponent = Auth;
  let userEmail = '';
  let isAuthenticated = false;
  let sidebarCollapsed = false;
  const BASE_PATH = (import.meta.env.BASE_URL || '/').replace(/\/+$/, '');

  const AUTH_ROUTES = ['/auth'];
  $: showShell = !AUTH_ROUTES.includes(currentRoute);
  $: sidebarWidth = sidebarCollapsed ? 78 : 220;

  function isProtectedRoute(pathname) {
    return !AUTH_ROUTES.includes(pathname);
  }

  function withBase(path) {
    const normalizedPath = path.startsWith('/') ? path : `/${path}`;
    return BASE_PATH ? `${BASE_PATH}${normalizedPath}` : normalizedPath;
  }

  function stripBase(pathname) {
    if (!pathname) return '/';
    if (!BASE_PATH) return pathname;
    if (pathname === BASE_PATH) return '/';
    return pathname.startsWith(BASE_PATH) ? pathname.slice(BASE_PATH.length) || '/' : pathname;
  }

  function normalizePath(pathname) {
    const withoutBase = stripBase(pathname);
    if (!withoutBase || withoutBase === '/') return '/auth';
    if (withoutBase.length > 1 && withoutBase.endsWith('/')) return withoutBase.slice(0, -1);
    return withoutBase;
  }

  function resolveComponent(pathname) {
    switch (pathname) {
      case '/auth':      return Auth;
      case '/dashboard': return Dashboard;
      case '/inventario': return Inventory;
      default:           return Auth;
    }
  }

  function navigate(path) {
    window.history.pushState(null, '', withBase(path));
    syncRoute();
  }

  function toggleSidebar() {
    sidebarCollapsed = !sidebarCollapsed;
  }

  function syncRoute({ replace = false } = {}) {
    const normalized = normalizePath(window.location.pathname);

    if (isProtectedRoute(normalized) && !isAuthenticated) {
      currentRoute = '/auth';
      CurrentComponent = Auth;
      const authUrl = withBase('/auth');
      if (replace || window.location.pathname !== authUrl) {
        window.history.replaceState(null, '', authUrl);
      }
      return;
    }

    if (normalized === '/auth' && isAuthenticated) {
      currentRoute = '/dashboard';
      CurrentComponent = Dashboard;
      const dashboardUrl = withBase('/dashboard');
      if (replace || window.location.pathname !== dashboardUrl) {
        window.history.replaceState(null, '', dashboardUrl);
      }
      return;
    }

    currentRoute = normalized;
    CurrentComponent = resolveComponent(normalized);
    const targetUrl = withBase(normalized);
    if (replace && window.location.pathname !== targetUrl) {
      window.history.replaceState(null, '', targetUrl);
    }
  }

  async function handleSignOut() {
    try { await supabase.auth.signOut(); } catch (_) {}
    navigate('/auth');
  }

  onMount(async () => {
    // Load auth state before resolving route
    try {
      const { data } = await supabase.auth.getSession();
      const session = data?.session;
      isAuthenticated = !!session;
      userEmail = session?.user?.email || '';
    } catch (_) {}

    syncRoute({ replace: true });
    window.addEventListener('popstate', syncRoute);

    // Keep userEmail in sync when auth state changes
    supabase.auth.onAuthStateChange((_event, session) => {
      isAuthenticated = !!session;
      userEmail = session?.user?.email || '';
      syncRoute({ replace: true });
    });

    return () => window.removeEventListener('popstate', syncRoute);
  });
</script>

<style>
  .shell {
    --topbar-height: 60px;
    min-height: 100vh;
  }

  .shell-content {
    margin-left: var(--sidebar-width, 220px);
    padding-top: var(--topbar-height);
    flex: 1;
    min-height: 100vh;
    box-sizing: border-box;
    transition: margin-left 0.22s ease;
  }

  @media (max-width: 860px) {
    .shell-content {
      margin-left: var(--sidebar-width, 78px);
    }
  }
</style>

{#if showShell}
  <div class="shell" style={`--sidebar-width: ${sidebarWidth}px`}>
  <SideBar
    {currentRoute}
    collapsed={sidebarCollapsed}
    onNavigate={navigate}
    onToggleCollapse={toggleSidebar}
  />
  <TopBar {userEmail} onSignOut={handleSignOut} />
  <div class="shell-content">
    <svelte:component this={CurrentComponent} />
  </div>
  </div>
{:else}
  <svelte:component this={CurrentComponent} />
{/if}
