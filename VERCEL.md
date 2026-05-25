# Subir Atelier a Vercel

Atelier es un sitio estatico: `index.html` + `vercel.json`. No requiere build.

## Opcion recomendada: GitHub + Vercel

1. Crea un repositorio en GitHub.
2. Sube estos archivos:
   - `index.html`
   - `vercel.json`
   - `supabase-schema.sql`
   - `SUPABASE.md`
3. Entra a Vercel.
4. Crea un `New Project`.
5. Importa el repositorio desde GitHub.
6. En `Build & Output Settings` usa:
   - Framework Preset: `Other`
   - Build Command: vacio
   - Output Directory: vacio
7. Pulsa `Deploy`.

Vercel te dara una URL tipo `https://atelier-xxxx.vercel.app`.

## Despues de desplegar

1. Abre la URL de Vercel.
2. Entra a `Configuracion`.
3. Activa Supabase.
4. Inicia sesion con tu email.
5. Usa `Entrar / actualizar` para cargar tu espacio de trabajo.

## Opcion alternativa: Vercel CLI

Desde esta carpeta:

```powershell
npm i -g vercel
vercel
```

Cuando pregunte por la configuracion, elige proyecto estatico / sin framework.
