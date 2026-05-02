<script>
  import { supabase } from '../lib/supabaseClient.js';

  let userEmail = '';

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
</style>

<div class="dash">

</div>
