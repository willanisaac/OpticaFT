# OpticaFT — Svelte minimal starter

Pequeña app Svelte minimal para comenzar a editar.

Comandos:

```bash
npm install
npm run dev
```

Supabase setup:

1. Create a `.env` file with the following (replace values):

```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

2. Start the dev server:

```bash
npm run dev
```


Auditoría de seguridad:

```bash
npm audit
npm audit fix
```

Archivos principales:
- `src/App.svelte` — componente principal
- `src/main.js` — punto de entrada
- `index.html` — HTML base
