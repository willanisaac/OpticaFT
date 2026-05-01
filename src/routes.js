import Auth from './pages/Auth.svelte';
import Dashboard from './pages/Dashboard.svelte';

// routes object for svelte-spa-router
// Render `Auth` for '/', '/auth' and use it as a fallback for any unknown route.
// This avoids depending on redirects so the UI shows even if a client-side redirect
// or history replace does not run before the app mounts.
const routes = {
  '/auth': Auth,
  '/dashboard': Dashboard,
  '/': Auth,
  '*': Auth
};

export default routes;
