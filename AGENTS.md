# AGENTS.md — Guía operativa para agentes

Este repositorio **Dirty Road** contiene **dos subproyectos independientes**. No hay
`package.json` ni build system en la raíz: cada subproyecto se construye aparte.

| Ruta | Qué es | Stack |
| :--- | :--- | :--- |
| `dirty-road/` | **El juego** (núcleo del proyecto) | Godot 4.7, GDScript (+ C# habilitado) |
| `web/` | Landing/micrositio en español | Astro 7 + React 19 + Tailwind 4 |
| `docs/` | `DirtyRoad_GDD.md` (incompleto), `APA.docx` (2025, histórico) y los entregables en `docs/drive/` (`apa/`, `rae/`, `folleto/`, `manual/`, `poster/`, `presentacion/`) | — |
| `apk/` | Builds Android exportados (no versionados) | — |

Antes de trabajar, lee también `MEMORY.md` (arquitectura, fórmulas y estado actual).

---

## Comandos

### Juego (ejecutar desde `dirty-road/`)

```sh
# Generar/regenerar escenas de enemigos y recursos EtapaConfig
godot --headless --script res://tools/generar_enemigos.gd

# Verificar que los enemigos/etapas estén consistentes
godot --headless --script res://tools/verificar_enemigos.gd
```

- Escena principal: `ui/intro/intro.tscn` (definida en `project.godot` como `run/main_scene`).
- `project.godot` se edita preferiblemente desde el editor de Godot, no a mano.
- Export Android configurado en `export_presets.cfg` (package `com.l1t3Sg.dirtyroad`).

### Web (ejecutar desde `web/`)

```sh
npm run dev        # dev server en localhost:4321
npm run build      # build de producción en ./dist
npm run preview    # previsualizar el build
```

El dev server debe levantarse en **background**:

```sh
astro dev --background
astro dev stop | status | logs
```

Ver `web/AGENTS.md` para más detalle (es la guía de Astro del subproyecto web).

---

## Reglas duras (no romper)

1. **`WaveManager` (`scripts/wave_manager.gd`) es la ÚNICA fuente de verdad** de
   oleadas, spawns y escalado. No dupliques esa lógica en escenas ni en el jugador.
   El reloj manda: matar enemigos **no** adelanta la oleada.
2. **`SaveManager` (`scripts/save_manager.gd`) es la única fuente de los stats
   guardados.** El Jugador y el Árbol leen de `SaveManager.stats`, nunca se
   asignan valores a mano. Las mejoras se aplican vía `MejorasManager`.
3. **No renombres `mult_vida`, `mult_velocidad` ni `mult_danio`** en `EtapaConfig`:
   el WaveManager los lee por nombre exacto.
4. **No edites archivos `*.uid`** (los genera Godot). Tampoco modifiques `addons/`
   ni `assets/`: **están en `.gitignore` y no se versionan**.
5. **Orden de autoloads fijo**: `SaveManager` debe ir **antes** que `BiomasaManager`
   (este último lee `SaveManager` al arrancar). Orden actual: `EducationManager`,
   `SaveManager`, `BiomasaManager`, `MejorasManager`, `AudioManager`.
6. **Contrato de daño**: los enemigos nuevos llaman a `recibir_danio(cantidad)`.
   Los nodos se resuelven **por grupos**, no por rutas rígidas:
   `jugador`, `enemi`, `arbol`, `player`, `fire_player`.
7. `assets/` y `addons/` no están en git: si un cambio depende de un asset,
   **no asumas que existe en un clon limpio**.

---

## Mapa "dónde mirar" por tarea

| Quiero tocar… | Archivos/rutas clave |
| :--- | :--- |
| Oleadas, spawns, escalado | `scripts/wave_manager.gd` |
| Etapas (temas, multiplicadores, jefe) | `scripts/etapa_config.gd`, `ecenes/enemies/etapas/etapa_*.tres` |
| Ventana de oleadas por enemigo | `scripts/enemigo_oleada_config.gd` (`oleada_minima/maxima`, `peso`) |
| Generar enemigos/jefes en masa | `tools/generar_enemigos.gd` (tablas `NORMALES`, `TIPO_DEF`) |
| Capturas y trailers (herramientas) | `tools/modo_captura.gd`, `tools/reproductor_trailer.gd`, `tools/trailers/*.json`, `tools/grabar_trailer.sh`, `tools/generar_trailers.sh`, `tools/README.md` |
| Enemigo base y comportamientos | `ecenes/enemies/class/`, `.../comportamientos/` |
| Jefe (ataques) | `ecenes/enemies/class/BossAttackComponent.gd`, `proyectil_jefe.gd` |
| Contenido educativo | `scripts/education/` (`EducationManager`, `education_data_stages.gd`) |
| Tarjetas y mejoras | `ecenes/cards/`, `scripts/mejoras_manager.gd` |
| Jugador / combate | `ecenes/players/quark/` (principal) + `aura/cronos/flora/geo` |
| Escenario por etapa | `ecenes/etapas/gestor_etapa.gd`, `escenario_etapa.gd`, `tema_etapa.gd` |
| UI | `ui/` (`main/`, `intro/`, `dead/`, `ajustes/`, `slots/`, `controles/`) |
| Web (secciones) | `web/src/components/sections/`, `web/src/lib/etapas.ts` |

---

## Convenciones de código

- **Idioma mixto**: predominio del español en el juego (`enemi`, `oleada`, `biomasa`,
  `dano`, `mejoras`). Mantén el idioma y el estilo del archivo que editas.
- `class_name` en **PascalCase**; nombres de archivo en **snake_case**.
- Cabeceras de bloque con la convención del autor:
  `## ══════════════════════════════════════════════════════════`.
- Comenta el **por qué** y los contratos (el autor documenta fórmulas y supuestos
  en la cabecera de cada script). Sigue ese patrón.
- Input actions del proyecto: `super`, `mega`, `debug_kill` (tecla K), `debug`.
- Debug del sistema educativo (solo builds debug): **F9** mensaje de prueba,
  **F10** invertir posición, **F11** ciclar estilo del popup.

---

## Atajos de debug útiles

- `EducationManager`: F9 muestra una carta de prueba del popup.
- `WaveManager`: exporta `debug_activo`, `debug_oleada_inicial`,
  `debug_no_guardar`, `debug_spawnear_enemigos` para arrancar en una oleada concreta
  sin ensuciar el guardado.
- `BiomasaManager`: `DEBUG` y `AUTOTEST_AL_INICIAR` imprimen quién cambia el
  contador y corren un autodiagnóstico al cargar cada escena.

---

## MCP de Godot (OpenCode)

El servidor MCP **`godot`** (`@coding-solo/godot-mcp`) está configurado en
`opencode.json` (raíz del repo) y se conecta solo. Expone herramientas
`tools.godot.*` para lanzar/ejecutar el juego y leer su salida.

- Config: `opencode.json` → `mcp.servers.godot` (`GODOT_PATH=/usr/bin/godot`,
  `DEBUG=true`).
- **Úsalo siempre que necesites ejecutar o depurar el juego**, en lugar de
  invocar `godot` a mano cuando la tarea lo permita:
  - `get_godot_version` / `get_project_info` — versión y estructura del proyecto.
  - `run_project` / `stop_project` / `get_debug_output` — ejecutar y capturar
    errores y `print()`s.
  - `launch_editor` — abrir el editor de un proyecto.
  - `list_projects` — localizar proyectos Godot en un directorio.
  - `create_scene` / `add_node` / `load_sprite` / `save_scene` — edición de escenas.
  - `get_uid` / `update_project_uids` — UIDs (Godot 4.4+).
- El proyecto Godot vive en `dirty-road/`: pasa siempre
  `projectPath: "<repo>/dirty-road"`.
- Comprobar el estado: `opencode mcp list` (debe aparecer `godot connected`).

---

## Flujo de trabajo con git

- Ramas por feature: `feature/<tema>` (p. ej. `feature/10-update-wavemanager-enemis`).
- **Commits muy atómicos**: un commit = un cambio lógico y aislado (una mecánica,
  un fix, un asset, un ajuste). No mezcles temas distintos en el mismo commit; si
  tocaste varias cosas, sepáralas en varios commits.
- Formato del mensaje: `<prefijo>: <descripción corta>`.
  - `choire:` — tareas de mantenimiento/limpieza (variantes vistas: `chorie:`).
  - `feature:` — nueva funcionalidad.
  - `fix:` — corrección de errores.
  - `add:` — añadir contenido/archivos concretos.
- Descripción corta **en inglés** (estilo del historial: `feature: add the new enemies`, `fix: the name in the cards`).
- **Nunca** comitees `apk/`, `assets/`, `addons/`, `.godot/` ni los `.aider*`.
