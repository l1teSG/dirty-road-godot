# Guía de Contribución · Contributing Guide

## 🇪🇸 Español

¡Gracias por tu interés en **Dirty Road**! Antes de contribuir, lee esta guía y
ten en cuenta la naturaleza de licencia del proyecto.

> ⚠️ **Licencia propietaria.** Dirty Road es **software privativo** (todos los
> derechos reservados). **No** se aceptan *pull requests* externos ni el uso,
> copia, modificación o redistribución del código sin autorización **previa y
> por escrito** de los autores. Consulta [`LICENSE`](../LICENSE).
> Las *issues* con reportes de errores, sugerencias y dudas **sí** son
> bienvenidas.

### Cómo reportar

| Quiero… | Dónde |
| :--- | :--- |
| Reportar un error | [Nueva *issue*: Error](https://github.com/l1teSG/dirty-road-godot/issues/new?template=bug_report.yml) |
| Proponer una idea o mejora | [Nueva *issue*: Sugerencia](https://github.com/l1teSG/dirty-road-godot/issues/new?template=feature_request.yml) |
| Reportar una vulnerabilidad | **En privado**: ver [`SECURITY.md`](SECURITY.md) |
| Convivir sanamente | [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) |

### Antes de empezar

1. Lee [`README.md`](../README.md) para la visión general y
   [`AGENTS.md`](../AGENTS.md) para la guía operativa.
2. Consulta [`MEMORY.md`](../MEMORY.md): arquitectura, fórmulas y estado actual.
3. Revisa las *issues* abiertas para no duplicar trabajo.

### Estructura del repositorio

El repositorio contiene **dos subproyectos independientes** (no hay build system
en la raíz):

| Ruta | Qué es | Stack |
| :--- | :--- | :--- |
| `dirty-road/` | El juego | Godot 4.7 · GDScript (+ C#) |
| `web/` | Landing / micrositio | Astro 7 · React 19 · Tailwind 4 |

### Puesta en marcha

**Juego** (desde `dirty-road/`):

```sh
godot --headless --script res://tools/generar_enemigos.gd   # generar escenas/recursos
godot --headless --script res://tools/verificar_enemigos.gd # verificar consistencia
```

Escena principal: `ui/intro/intro.tscn`.

**Web** (desde `web/`):

```sh
npm install
npm run dev      # localhost:4321 (levantar en background)
npm run build    # build de producción en ./dist
npm run preview  # previsualizar el build
```

### Reglas duras (no romper)

1. `WaveManager` (`scripts/wave_manager.gd`) es la **única fuente de verdad** de
   oleadas, spawns y escalado. No dupliques esa lógica.
2. `SaveManager` (`scripts/save_manager.gd`) es la **única fuente de los stats
   guardados**; las mejoras se aplican vía `MejorasManager`.
3. **No renombres** `mult_vida`, `mult_velocidad` ni `mult_danio` en
   `EtapaConfig`: el `WaveManager` los lee por nombre exacto.
4. **No edites** archivos `*.uid` (los genera Godot) ni `addons/` ni `assets/`
   (están en `.gitignore`).
5. Orden de autoloads fijo: `SaveManager` **antes** que `BiomasaManager`.
6. Contrato de daño: los enemigos nuevos implementan `recibir_danio(cantidad)` y
   los nodos se resuelven **por grupos** (`jugador`, `enemi`, `arbol`, `player`,
   `fire_player`).

### Estilo de código

- **Idioma mixto**: predomina el español en el juego (`enemi`, `oleada`,
  `biomasa`, `dano`, `mejoras`). Mantén el idioma y el estilo del archivo.
- `class_name` en **PascalCase**; nombres de archivo en **snake_case**.
- Cabeceras de bloque con la convención del proyecto:
  `## ══════════════════════════════════════════════════════════`.
- Documenta el **por qué** y los contratos en la cabecera del script.
- `project.godot` se edita preferiblemente desde el editor de Godot.

### Flujo de trabajo con Git

- Ramas por *feature*: `feature/<tema>` (p. ej. `feature/10-update-wavemanager-enemis`).
- **Commits atómicos**: un commit = un cambio lógico y aislado.
- Formato: `<prefijo>: <descripción corta>` en **inglés**.
  - `feature:` — nueva funcionalidad.
  - `fix:` — corrección de errores.
  - `add:` — contenido o archivos nuevos.
  - `chore:` — mantenimiento/limpieza (variante vista: `choire:`).
- **Nunca** comitees `apk/`, `assets/`, `addons/`, `.godot/` ni los `.aider*`.

### Antes de abrir un pull request

- [ ] Sale de `main` actualizada y en una rama `feature/<tema>`.
- [ ] Los *commits* son atómicos y con el prefijo correcto.
- [ ] El juego arranca sin errores en la consola de Godot.
- [ ] `godot --headless --script res://tools/verificar_enemigos.gd` pasa.
- [ ] `npm run build` en `web/` termina sin errores (si tocaste la web).
- [ ] No se añadieron archivos ignorados (`apk/`, `assets/`, `addons/`, `.godot/`).
- [ ] La descripción explica **qué** cambia y **por qué**.

Rellena la plantilla de *pull request*; se autocompleta al crear el PR.

---

## 🇬🇧 English

Thanks for your interest in **Dirty Road**! Before contributing, read this guide
and note the project's license.

> ⚠️ **Proprietary license.** Dirty Road is **proprietary software** (all rights
> reserved). External *pull requests* and any use, copy, modification or
> redistribution of the code are **not** accepted without the authors' **prior
> written** authorization. See [`LICENSE`](../LICENSE).
> Issues with bug reports, suggestions and questions **are** welcome.

### How to Report

| I want to… | Where |
| :--- | :--- |
| Report a bug | [New issue: Bug](https://github.com/l1teSG/dirty-road-godot/issues/new?template=bug_report.yml) |
| Propose an idea | [New issue: Feature](https://github.com/l1teSG/dirty-road-godot/issues/new?template=feature_request.yml) |
| Report a vulnerability | **Privately**: see [`SECURITY.md`](SECURITY.md) |
| Be a decent human | [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) |

### Before You Start

1. Read [`README.md`](../README.md) for the big picture and
   [`AGENTS.md`](../AGENTS.md) for the operational guide.
2. Check [`MEMORY.md`](../MEMORY.md): architecture, formulas and current state.
3. Browse open issues to avoid duplicate work.

### Repository Structure

The repository holds **two independent subprojects** (no root build system):

| Path | What it is | Stack |
| :--- | :--- | :--- |
| `dirty-road/` | The game | Godot 4.7 · GDScript (+ C#) |
| `web/` | Landing / microsite | Astro 7 · React 19 · Tailwind 4 |

### Getting Started

**Game** (from `dirty-road/`):

```sh
godot --headless --script res://tools/generar_enemigos.gd   # generate scenes/resources
godot --headless --script res://tools/verificar_enemigos.gd # verify consistency
```

Main scene: `ui/intro/intro.tscn`.

**Web** (from `web/`):

```sh
npm install
npm run dev      # localhost:4321 (run in background)
npm run build    # production build in ./dist
npm run preview  # preview the build
```

### Hard Rules (Do Not Break)

1. `WaveManager` (`scripts/wave_manager.gd`) is the **single source of truth**
   for waves, spawns and scaling. Do not duplicate that logic.
2. `SaveManager` (`scripts/save_manager.gd`) is the **single source of saved
   stats**; upgrades are applied through `MejorasManager`.
3. **Do not rename** `mult_vida`, `mult_velocidad` or `mult_danio` in
   `EtapaConfig`: `WaveManager` reads them by exact name.
4. **Do not edit** `*.uid` files (Godot generates them), `addons/` or `assets/`
   (they are git-ignored).
5. Autoload order is fixed: `SaveManager` **before** `BiomasaManager`.
6. Damage contract: new enemies implement `recibir_danio(cantidad)` and nodes
   are resolved **by groups** (`jugador`, `enemi`, `arbol`, `player`,
   `fire_player`).

### Code Style

- **Mixed language**: Spanish dominates in the game (`enemi`, `oleada`,
  `biomasa`, `dano`, `mejoras`). Keep the file's language and style.
- `class_name` in **PascalCase**; file names in **snake_case**.
- Block headers use the project convention:
  `## ══════════════════════════════════════════════════════════`.
- Document the **why** and the contracts in the script header.
- `project.godot` should preferably be edited from the Godot editor.

### Git Workflow

- Feature branches: `feature/<topic>` (e.g. `feature/10-update-wavemanager-enemis`).
- **Atomic commits**: one commit = one logical, isolated change.
- Format: `<prefix>: <short description>` in **English**.
  - `feature:` — new functionality.
  - `fix:` — bug fix.
  - `add:` — new content or files.
  - `chore:` — maintenance/cleanup (seen variant: `choire:`).
- **Never** commit `apk/`, `assets/`, `addons/`, `.godot/` or `.aider*`.

### Before Opening a Pull Request

- [ ] Branched off an up-to-date `main` as `feature/<topic>`.
- [ ] Commits are atomic and use the correct prefix.
- [ ] The game boots without console errors.
- [ ] `godot --headless --script res://tools/verificar_enemigos.gd` passes.
- [ ] `npm run build` in `web/` succeeds (if you touched the web).
- [ ] No ignored files were added (`apk/`, `assets/`, `addons/`, `.godot/`).
- [ ] The description explains **what** changes and **why**.

Fill in the pull request template; it auto-populates when you open the PR.
