import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';

export default defineConfig(({ mode }) => {
  // Carga las variables de entorno desde .env
  const env = loadEnv(mode, process.cwd(), '')
  
  return {
    plugins: [svelte()],
    base: '/vexal/',
    server: {
      port: 3000,
      open: true,
      allowedHosts: [
        'kapisg.com',
        'kapisg.com/vexal'
      ]
    },
    define: {
      // Expone las variables de entorno al código del cliente
      'import.meta.env.VITE_SUPABASE_URL': JSON.stringify(env.VITE_SUPABASE_URL),
      'import.meta.env.VITE_SUPABASE_ANON_KEY': JSON.stringify(env.VITE_SUPABASE_ANON_KEY),
    }
  }
})