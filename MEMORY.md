# MEMORY.md — Conocimiento durable del proyecto

Contexto de largo plazo sobre **Dirty Road**: qué es, cómo está construido, qué
decisiones se tomaron y qué queda pendiente. Para instrucciones operativas
(comandos, reglas, mapa de archivos) ver `AGENTS.md`.

---

## 1. Visión del juego

**Dirty Road** es un *survival action* top-down/2D **infinito** donde el jugador
defiende un **Árbol vivo** —último símbolo de un ecosistema sano— de oleadas
interminables de enemigos que representan **problemas ambientales reales**.

- **No hay final, ni pantalla de victoria, ni "jefe final de la contaminación".**
  La contaminación es sistémica y cíclica: solo se gestiona, se ralentiza y se
  mantiene vivo el ecosistema el mayor tiempo posible.
- Jugador protagonista: **Renata** / **Quark** (el nodo jugable).
- Contexto académico: **Articulación SENA (Desarrollo de Software)** con la
  **I.E. Técnico Industrial "Julio Flórez"** (Sistemas Informáticos). Todos los derechos reservados (propietaria).

**Pilares de diseño (del GDD):**

1. *Aprender jugando, no leyendo*: datos vía feedback de combate y popups cortos
   (nunca bloqueantes, ≤ 3-4 s).
2. *Infinito, no repetitivo*: el mundo evoluciona (índice de contaminación,
   eventos, mutadores) para que la hora 3 se sienta distinta de la hora 1.
3. *Habilidad sobre grind*: progresión por maestría (timing de dash, posición,
   rutas de combo) y desbloqueos cosméticos/informativos, no power creep.
4. *Cada enemigo enseña algo*: cada enemigo/jefe mapea 1:1 a un problema real.
5. *El mundo reacciona a ti*: el estado visual/sonoro es un panel vivo del
   ecosistema.

---

## 2. Arquitectura y contratos

### Autoloads (orden importa)

| Autoload | Script | Responsabilidad |
| :--- | :--- | :--- |
| `EducationManager` | `scripts/education/EducationManager.gd` | Popups educativos, descubrimientos, mensajes de oleada/muerte. |
| `SaveManager` | `scripts/save_manager.gd` | **Fuente única de stats** y persistencia por slots. |
| `BiomasaManager` | `ecenes/players/quark/BiomasaManager.gd` | Contador de biomasa (sin tope), costo de súper. |
| `MejorasManager` | `scripts/mejoras_manager.gd` | Aplica las cartas/mejoras a los stats de `SaveManager`. |
| `AudioManager` | `scripts/audio_manager.gd` | Buses y SFX generados por código; volúmenes desde ajustes. |

> ⚠️ `SaveManager` **debe** ir antes que `BiomasaManager` en la lista de Autoload.

### Contratos clave

- **Stats finales** viven en `SaveManager.stats` (`jugador`, `arbol`, …) =
  base + mejoras. Jugador y Árbol **leen de ahí**.
- **Daño**: enemigos llaman `recibir_danio(cantidad)`; los nodos se buscan por
  grupos (`jugador`, `enemi`, `arbol`, `player`, `fire_player`).
- **Biomasa**: `BiomasaManager.contador` es un **costo, no un tope**
  (`COSTO_SUPER = 10`). Se puede acumular de más y lo sobrante se conserva.
- **Puntos de escalado**: el WaveManager aplica vida/speed/damage **antes** de
  `add_child`; inyecta referencias de jugador y árbol por grupos (con caché).

### Persistencia

- Partida por slots (máx. 5): `user://partida_1..5.save`.
- Metadatos de slots: `user://slots.json` (oleada, etapa, biomasa, fecha, tiempo).
- Ajustes globales: `user://ajustes.save` (no se borran con "Nueva partida").

---

## 3. Modelo de contenido

### Etapas y oleadas

- **10 etapas × 10 oleadas.** Cada etapa tiene **3 enemigos normales + 1 jefe**
  = **30 normales + 10 jefes** (etapa 1 existía a mano; etapas 2–10 las genera
  `tools/generar_enemigos.gd`: 27 normales + 9 jefes).
- La **última oleada de cada etapa es de jefe**: no tiene reloj, solo cierra al
  morir el jefe. Los escoltas salen del pool normal, con tope `jefe_escoltas`.
- `heredar_enemigos_anteriores = true`: las etapas acumulan enemigos previos.
- `EnemigoOleadaConfig` define la ventana de aparición por enemigo
  (`oleada_minima`, `oleada_maxima` con `0 = sin límite`, `peso`, `max_simultaneos`).

### Fórmulas de escalado (WaveManager)

```
Vida     = base × etapa.mult_vida × cfg.mult_vida × (1 + (oleada−1) × escalado_vida)
Daño     = base × etapa.mult_danio × (1 + (oleada−1) × escalado_danio)
Velocidad= base × etapa.mult_velocidad          (no escala por oleada)
Duración = base × (1 + aumento_micro × (N−1)) × (1 + aumento_macro × etapa)
```

- `tiempo_entre_spawns` es **el knob de presión** (menor valor = más enemigos).
- Por defecto: `escalado_vida_por_oleada = 0.07`, `escalado_danio_por_oleada = 0.04`,
  `aumento_duracion_por_oleada = 0.10`, `tiempo_maximo_oleada = 40 s`,
  `tiempo_descanso = 5 s`, `oleadas_por_etapa = 10`.

### Arquetipos de enemigo (`TIPO_DEF` en `tools/generar_enemigos.gd`)

| Tipo | Vida | Vel | Daño | Contacto |
| :--- | --: | --: | --: | :--- |
| enjambre | 22 | 150 | 10 | sí |
| melee | 65 | 80 | 18 | no |
| rango | 26 | 95 | 9 | no |
| torreta | 90 | 60 | 12 | no |
| embestida | 80 | 75 | 22 | sí |

### Temas de las 10 etapas

1. Contaminación del suelo y el aire · 2. Basura y vertederos · 3. Océanos y
plástico · 4. Contaminación industrial · 5. Lluvia ácida · 6. Residuos
electrónicos · 7. Energía nuclear y radiación · 8. Pesticidas y agricultura ·
9. Deforestación · 10. Cambio climático.

### Jugador

- **`quark`** es el jugador principal; componentes creados por código en `_ready`:
  `DashComponent`, `AnimacionQuark`, `EfectoRegeneracion`, `FlechaArbol`,
  `SuperMeteoritos` (lluvia de meteoritos), `ContadorRespawn`, `SelectorObjetivo`,
  `EnemigosUtil`.
- Clases adicionales en assets/carpetas: `aura`, `cronos`, `flora`, `geo`.
- Balance de referencia (oleada 1): DPS base ≈ 17 (10 daño / 0.6 s) + 5 % crítico;
  jugador 100 HP + regeneración 2 HP/s tras 5 s + i-frames de dash
  (`velocidad_dash 600`, `cooldown 0.8`, `invulnerable_en_dash = true`).

### Escenarios por etapa

- "Mismo valle, distinta piel": **no se genera terreno nuevo**. La etapa 1 deja el
  `valle` original intacto; las demás **recolorean** la geometría existente con la
  paleta del `TemaEtapa` (mismos límites/colisiones) y añaden props temáticos.
- `GestorEtapa` aporta tinte de ambiente, partículas, banner "ETAPA N · TEMA" y
  peligro característico (zonas de daño temáticas).

---

## 4. Sistema educativo (pilar, no extra)

- Basado en **Teoría del Aprendizaje Significativo + Gamificación**.
- `EducationManager` crea el popup en `_ready()`, detecta settings por grupo/tipo y
  usa `EducationDataStages` si no hay etapas embebidas. Es tolerante a fallos:
  **nunca crashea por propiedades ausentes** (usa `.get()`), y resuelve ids
  normalizando tildes/espacios/guiones + alias por nombre visible.
- Datos en `scripts/education/education_data_stages.gd` (temas, datos, muertes,
  enemigos con `represents` y `facts`). Datos generales en `education_data_general.gd`.
- API para WaveManager/jugador: `set_data`, `start_run`, `stop_run`,
  `on_stage_started`, `on_wave_started/ended`, `on_enemy_encountered`,
  `on_boss_defeated`, `show_wave_break/death/survival_fact`, `get_discovered`.
- `EducationPopup` v6.1: variantes `WAVE_BREAK`, `DEATH`, `ENEMY_CARD`, `SURVIVAL`;
  estilos `CARD`/`SUBTITLES`. Duración default 3.5 s.
- **Arranque esperado**: la primera oleada de la partida espera a que terminen los
  mensajes iniciales de `EducationManager` (señal `liberar_arranque()` o timeout).

---

## 5. Mejoras / cartas

- `MejorasManager` mapea `id_carta → Array de [ruta_stat, op, valor]`:
  - `pct` → `stat *= (1 + valor)` (p. ej. 0.20 = +20 %)
  - `add` → `stat += valor`
  - `mult` → `stat *= valor`
- **Acumulable**: cada compra reaplica su delta (no hay mejoras "únicas").
- Definición de cartas en `ecenes/cards/` (`CartasConfig.gd`, `MejorasConfig.gd`).

---

## 6. Web (landing)

- Astro 7 + React 19 + Tailwind 4 + `lucide-react` y `marked`.
- Secciones en `web/src/components/sections/` (`Hero`, `QueEs`, `Problema`,
  `Objetivos`, `Mecanicas`, `Etapas`, `MarcoTeorico`, `Galeria`, `Metodologia`,
  `Equipo`, `Descargar`, `Footer`).
- **Datos de etapas duplicados** en `web/src/lib/etapas.ts` (espejo manual de
  `education_data_stages.gd`). Al cambiar temas/enemigos en el juego, **sincroniza
  ambos**.
- `web/src/lib/github.ts` consulta estadísticas de GitHub; `apa.ts` para citas.

---

## 7. Estado actual

- Versión en `project.godot`: **`10.0.0 beta`**; features Godot `4.7`, `C#`,
  `Forward Plus`. Motor de física 3D: Jolt.
- Rama activa: `feature/10-update-wavemanager-enemis`. Existen ramas por área:
  `feature/enemies`, `feature/players`, `feature/ui-init`, `feature/education`,
  `feature/docs`, `feature/web`, `feature-upgrades`, `main`.
- APK más reciente subido: `apk/dirtyRoad_V10.1.1.apk` (los APK **no** se versionan).
- Escena principal: `ui/intro/intro.tscn`.
- Addons presentes: `godot_rl_agents` (RL), `phantom_camera` (cámara),
  `godotty` (terminal). Solo `phantom_camera` y `godot_rl_agents` están habilitados
  en `project.godot`; verificar si siguen teniendo uso en gameplay.

---

## 8. Pendientes / deuda técnica conocida

- **`docs/DirtyRoad_GDD.md` está incompleto**: solo cubre "Core Vision" y el
  encabezado de "Core Loop". Completarlo con loop, sistemas, economía y UX.
- **Mejoras con hooks pendientes** (se guardan pero aún no las consume ninguna
  mecánica): `bloquedehieloseco` (congelar), `hachaconfiscada` (danio_elite),
  `reddelimpiezaoceanica` (danio_acuaticos), `fertilizantenatural` (danio_continuo),
  `biopesticida` (danio_toxico), `bombadesemillas` (detonar_prob),
  `panelsolarportatil`, `linternadedinamo`, `hongoluminiscente`, `filtrodecarbon`,
  `raicesprofundas`, `pararrayosreciclado`, `mantaignifuga`, `alarmatemprana`,
  `dronconservacionista`, `semillasdetrueque`.
- **Sincronía web ↔ juego**: `web/src/lib/etapas.ts` se mantiene a mano.
- **Entregables en `docs/drive/`**: una carpeta por documento (`apa/`, `rae/`,
  `folleto/`, `manual/`, `poster/`, `presentacion/`) con las copias vigentes; las
  fuentes editables viven en `docs/`. Ver `docs/drive/README.md`.
- **Congruencia documental**: el RAE (`docs/drive/rae/RAE.docx`) resume el proyecto
  y debe mantenerse alineado con el APA vigente, el póster, la presentación, el
  folleto y el manual. El APA vigente es `docs/drive/apa/APA.docx` (2026 ·
  Godot 4.7 · licencia MIT); `docs/APA.docx` es el de 2025 (histórico) y todavía
  lista controles inexistentes, "Sembrar (Espacio)" e "Inventario (Tab)".
- Limpieza de addons no usados (`godot_rl_agents`, `godotty`) si se confirma que no
  aportan al gameplay.
- `assets/` y `addons/` no están en git: un clon limpio no reproduce el juego
  hasta restaurarlos.

---

## 9. Equipo y marco

- **Juan Felipe Casas Aguilar** — programación principal GDScript, mecánicas,
  integración Godot.
- **Emmanuel Efrén Rosero Sánchez** — diseño de assets y programación GDScript.
- **Miguel Ángel Murcia Galindo** — investigación, revisión teórica/histórica y
  programación GDScript.
- Institución: I.E. Técnico Industrial "Julio Flórez" · Programa: Articulación SENA,
  Técnico en Desarrollo de Software. Licencia **propietaria** (todos los derechos reservados).

---

## 10. Herramientas de agente (MCP)

- **MCP de Godot** (`@coding-solo/godot-mcp`): servidor configurado en
  `opencode.json` (raíz del repo) bajo `mcp.servers.godot`.
  - `GODOT_PATH=/usr/bin/godot`, `DEBUG=true`. Godot del entorno: **4.7.2**.
  - Herramientas `tools.godot.*`: `run_project`, `stop_project`,
    `get_debug_output`, `launch_editor`, `get_godot_version`, `list_projects`,
    `get_project_info`, `create_scene`, `add_node`, `load_sprite`,
    `save_scene`, `export_mesh_library`, `get_uid`, `update_project_uids`.
  - **Uso preferente**: para ejecutar/depurar el juego y capturar errores en vez
    de invocar `godot` a mano. `projectPath` = `<repo>/dirty-road`.
- **Skills de agente** (`.agents/skills/`, en git): `find-skills`,
  `frontend-design` (Anthropic) y `godot-2d-animation`.
  - `frontend-design` → rediseño del micrositio `web/`.
  - `godot-2d-animation` → patrones de animación 2D en Godot (squash & stretch,
    tween lifecycle, un-frame sync).
