# Dirty Road — Landing

Micrositio/landing en español del videojuego educativo **Dirty Road**.
Stack: **Astro 7 + React 19 (islas) + Tailwind 4**.

La página es estática (una sola ruta) y ensambla secciones independientes; los
datos del juego y del documento académico viven en `src/lib/`.

## Comandos

Ejecutar desde `web/`:

| Comando | Acción |
| :--- | :--- |
| `npm install` | Instala dependencias |
| `npm run dev` | Dev server en `localhost:4321` |
| `npm run build` | Build de producción en `./dist` |
| `npm run preview` | Previsualiza el build |
| `npm run check` | Chequeo de tipos de Astro (`astro check`) |

El dev server debe levantarse en background:

```sh
astro dev --background
astro dev stop | status | logs
```

## Estructura

```text
src/
├── components/
│   ├── sections/      # Secciones de la landing (Hero, QueEs, Etapas, Descargar, …)
│   ├── ui/            # Primitivas (Reveal, SectionHeading)
│   ├── Changelog.tsx  # Isla: changelog de la última release de GitHub
│   ├── DownloadButton.tsx / GitHubStats.tsx
│   ├── FondoShader.tsx  # Fondo WebGL (fallback CSS)
│   └── Navbar.astro
├── layouts/BaseLayout.astro  # <head>, SEO/OG canónicas, script de Reveal
├── lib/
│   ├── etapas.ts      # Datos de las 10 etapas
│   ├── apa.ts         # Textos del documento académico
│   └── github.ts      # API de GitHub (releases, stats, detección de SO)
├── pages/index.astro  # Ensambla las secciones
└── styles/global.css  # Sistema visual ("Bitácora del último ecosistema")
```

`index.astro` solo ensambla: cada sección vive en su propio archivo.

## Descargas

El botón de descarga consume la API pública de GitHub
(`l1teSG/dirty-road-godot`) y detecta el SO del visitante para resaltar el asset
correspondiente. Hoy la release publica únicamente el **APK de Android**, por lo
que el botón se etiqueta como tal aunque el visitante use escritorio.

## SEO

- `site` configurado en `astro.config.mjs` (`https://dirty-road-official.netlify.app`).
- Sitemap generado con `@astrojs/sitemap` + `public/robots.txt`.
- `<link rel="canonical">` y metadatos OG/Twitter con URLs absolutas en `BaseLayout.astro`.
