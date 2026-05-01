<script>
  import { supabase } from '../lib/supabaseClient.js';

  async function loadUser() {
    try {
      const { data, error } = await supabase.auth.getUser();
      if (data?.user) userEmail = data.user.email || '';
    } catch (e) {
      // ignore — show generic view
    }
  }


  loadUser();

</script>

<style>
  .dash { padding: 2rem; font-family: system-ui, -apple-system, 'Segoe UI', Roboto, Arial; }
  .card { background: white; padding: 1.5rem; border-radius: 8px; box-shadow: 0 8px 24px rgba(0,0,0,0.08); max-width:720px; }
  .actions { margin-top:1rem; }
</style>

<div class="dash">

</div>
