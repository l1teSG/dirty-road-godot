# 🌿 Dirty Road

> *Survival action 2D infinito y educativo, desarrollado en Godot 4, que usa oleadas de problemas ambientales reales para fomentar la conciencia ecológica en jóvenes mayores de 10 años mediante la gamificación.*

[![Godot](https://img.shields.io/badge/Godot-4.7-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![GDScript](https://img.shields.io/badge/GDScript-✓-355570)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/)
[![Astro](https://img.shields.io/badge/Astro-7-ff5d01?logo=astro&logoColor=white)](https://astro.build/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📖 Sobre el proyecto

**Dirty Road** es un *survival action* top-down/2D **infinito** donde el jugador
defiende un **Árbol vivo** —último símbolo de un ecosistema sano— de oleadas
interminables de enemigos que representan **problemas ambientales reales**.

No hay final, ni pantalla de victoria, ni "jefe final de la contaminación": la
contaminación es sistémica y cíclica, igual que en la realidad. Solo se puede
gestionar, ralentizar y mantener vivo el ecosistema el mayor tiempo posible.
La travesía sigue a **Renata** y al nodo jugable **Quark**.

El proyecto se desarrolla en el marco de la **Articulación SENA (Desarrollo de
Software)** con la **I.E. Técnico Industrial "Julio Flórez"** (Especialidad
Sistemas Informáticos) y se distribuye bajo licencia **MIT**.

### Pilares de diseño (del GDD)

1. **Aprender jugando, no leyendo.** Los datos llegan vía feedback de combate y
   popups cortos (nunca bloqueantes, ≤ 3–4 s).
2. **Infinito, no repetitivo.** El mundo evoluciona (índice de contaminación,
   eventos, mutadores) para que la hora 3 se sienta distinta de la hora 1.
3. **Habilidad sobre grind.** La progresión es por maestría (timing de dash,
   posición, rutas de combo) y desbloqueos cosméticos/informativos, no *power creep*.
4. **Cada enemigo enseña algo.** Cada enemigo y jefe mapea 1:1 a un problema real.
5. **El mundo reacciona a ti.** El estado visual y sonoro es un panel vivo del
   ecosistema.

### Estado del proyecto

- Versión en `project.godot`: **`10.0.0 beta`** (Godot 4.7, `C#`, `Forward Plus`; física 3D con Jolt).
- Escena principal: `ui/intro/intro.tscn`.
- Contenido: 10 etapas × 10 oleadas (30 enemigos normales + 10 jefes).
- Rama activa de desarrollo: `feature/10-update-wavemanager-enemis`.
- APK de referencia (no versionado): `apk/dirtyRoad_V10.1.1.apk`.

---

## ✨ Características y mecánicas

- 🎨 **Diseño visual 2D** con ambientación e interacción fluida, sin recurrir a pixel art.
- 🌱 **Mecánicas sostenibles:** recolección/clasificación de residuos, reciclaje y
  reforestación (siembra de árboles).
- 🤖 **IA enemiga modular:** patrones autónomos, persecución y comportamientos
  intercambiables (`ecenes/enemies/comportamientos/`).
- 👹 **Jefes con ataques propios** (`BossAttackComponent`, `proyectil_jefe.gd`).
- 🗺️ **10 etapas temáticas × 10 oleadas**, con escalado y ventana de aparición
  por enemigo.
- 🎯 **Sistema educativo** integrado al gameplay (Teoría del Aprendizaje
  Significativo + Gamificación).
- 💾 **Partidas por slots** (máx. 5) y ajustes globales persistentes.
- 🃏 **Cartas / mejoras** acumulables que modifican los stats del jugador.
- 📱 **Controles táctiles** para Android, además de teclado/ratón.

---

## 🗂️ Estructura del repositorio

Este repositorio contiene **dos subproyectos independientes**. No hay
`package.json` ni build system en la raíz: cada uno se construye por separado.

| Ruta | Qué es | Stack |
| :--- | :--- | :--- |
| `dirty-road/` | **El juego** (núcleo del proyecto) | Godot 4.7, GDScript (+ C#) |
| `web/` | Landing/micrositio en español | Astro 7 + React 19 + Tailwind 4 |
| `docs/` | `DirtyRoad_GDD.md` y `APA.docx` | — |
| `apk/` | Builds Android exportados (no versionados) | — |

> ⚠️ `assets/` y `addons/` **no están en git** (ver `.gitignore`). Un clon limpio
> no reproduce el juego hasta restaurarlos.

---

## 🚀 Puesta en marcha

### Requisitos

- **Godot Engine 4.7** (con soporte C# / .NET habilitado).
- **Node.js ≥ 22.12** para la web.
- Export Android: plantillas de exportación y SDK configurados en el editor.

### Juego (desde `dirty-road/`)

```sh
# Abrir el proyecto en el editor de Godot
godot --editor project.godot

# Ejecutar el juego (escena principal: ui/intro/intro.tscn)
godot

# Regenerar escenas de enemigos y recursos EtapaConfig
godot --headless --script res://tools/generar_enemigos.gd

# Verificar consistencia de enemigos/etapas
godot --headless --script res://tools/verificar_enemigos.gd
```

- Escena principal definida en `project.godot` (`run/main_scene`): `ui/intro/intro.tscn`.
- Export Android configurado en `export_presets.cfg` (package `com.l1t3Sg.dirtyroad`).

### Web (desde `web/`)

```sh
npm install
npm run dev        # dev server en http://localhost:4321
npm run build      # build de producción en ./dist
npm run preview    # previsualizar el build
```

El dev server debe levantarse en **background**:

```sh
astro dev --background
astro dev stop | status | logs
```

---

## 🏗️ Arquitectura del juego

### Autoloads (el orden importa)

| Autoload | Script | Responsabilidad |
| :--- | :--- | :--- |
| `EducationManager` | `scripts/education/EducationManager.gd` | Popups educativos, descubrimientos, mensajes de oleada/muerte. |
| `SaveManager` | `scripts/save_manager.gd` | **Fuente única de stats** y persistencia por slots. |
| `BiomasaManager` | `ecenes/players/quark/BiomasaManager.gd` | Contador de biomasa (sin tope) y costo de súper. |
| `MejorasManager` | `scripts/mejoras_manager.gd` | Aplica las cartas/mejoras a los stats de `SaveManager`. |
| `AudioManager` | `scripts/audio_manager.gd` | Buses y SFX generados por código; volúmenes desde ajustes. |

> ⚠️ `SaveManager` **debe** ir antes que `BiomasaManager` (este último lee
> `SaveManager` al arrancar).

### Contratos clave (no romper)

- **`WaveManager` (`scripts/wave_manager.gd`) es la ÚNICA fuente de verdad** de
  oleadas, spawns y escalado. El reloj manda: matar enemigos **no** adelanta la oleada.
- **`SaveManager.stats` es la única fuente de stats guardados** (`jugador`, `arbol`, …)
  = base + mejoras. El Jugador y el Árbol **leen de ahí**; nunca se asignan valores a mano.
- **Daño:** los enemigos llaman a `recibir_danio(cantidad)`. Los nodos se resuelven
  **por grupos** (`jugador`, `enemi`, `arbol`, `player`, `fire_player`), no por rutas rígidas.
- **Biomasa:** `BiomasaManager.contador` es un **costo, no un tope** (`COSTO_SUPER = 10`);
  lo sobrante se conserva.
- **No renombrar** `mult_vida`, `mult_velocidad` ni `mult_danio` en `EtapaConfig`:
  el WaveManager los lee por nombre exacto.

### Persistencia

- Partida por slots (máx. 5): `user://partida_1..5.save`.
- Metadatos de slots: `user://slots.json` (oleada, etapa, biomasa, fecha, tiempo).
- Ajustes globales: `user://ajustes.save` (no se borran con "Nueva partida").

---

## 🎮 Modelo de contenido

### Etapas y oleadas

- **10 etapas × 10 oleadas.** Cada etapa tiene **3 enemigos normales + 1 jefe**
  = **30 normales + 10 jefes**.
- La **última oleada de cada etapa es de jefe**: no tiene reloj, solo cierra al
  morir el jefe. Los escoltas salen del pool normal, con tope `jefe_escoltas`.
- `heredar_enemigos_anteriores = true`: las etapas acumulan enemigos previos.
- `EnemigoOleadaConfig` define la ventana de aparición por enemigo
  (`oleada_minima`, `oleada_maxima` con `0 = sin límite`, `peso`, `max_simultaneos`).

### Fórmulas de escalado (WaveManager)

```
Vida      = base × etapa.mult_vida × cfg.mult_vida × (1 + (oleada−1) × escalado_vida)
Daño      = base × etapa.mult_danio × (1 + (oleada−1) × escalado_danio)
Velocidad = base × etapa.mult_velocidad          (no escala por oleada)
Duración  = base × (1 + aumento_micro × (N−1)) × (1 + aumento_macro × etapa)
```

- `tiempo_entre_spawns` es **el knob de presión** (menor valor = más enemigos).
- Valores por defecto: `escalado_vida_por_oleada = 0.07`, `escalado_danio_por_oleada = 0.04`,
  `aumento_duracion_por_oleada = 0.10`, `tiempo_maximo_oleada = 40 s`,
  `tiempo_descanso = 5 s`, `oleadas_por_etapa = 10`.

### Arquetipos de enemigo (`TIPO_DEF` en `tools/generar_enemigos.gd`)

| Tipo | Vida | Velocidad | Daño | Contacto |
| :--- | --: | --: | --: | :--- |
| enjambre | 22 | 150 | 10 | sí |
| melee | 65 | 80 | 18 | no |
| rango | 26 | 95 | 9 | no |
| torreta | 90 | 60 | 12 | no |
| embestida | 80 | 75 | 22 | sí |

### Las 10 etapas

| # | Tema | Enemigos normales | Jefe |
| --: | :--- | :--- | :--- |
| 1 | Contaminación del suelo y el aire | Microplástico · Nube de Gas · Petróleo | Excavadora Tóxica |
| 2 | Basura y vertederos | Lata Oxidada · Neumático Quemado · Bolsa Plástica | Vertedero Viviente |
| 3 | Océanos y plástico | Botella de Plástico · Botella Lanzadora · Red Fantasma | Isla de Plástico |
| 4 | Contaminación industrial | Humo de Fábrica · Chimenea · Hollín | Chimenea Gigante |
| 5 | Lluvia ácida | Gota Ácida · Charco Ácido · Nube Ácida | Géiser Ácido |
| 6 | Residuos electrónicos | Basura Electrónica · Cable Eléctrico · Batería Tóxica | Montaña de Chatarra |
| 7 | Energía nuclear y radiación | Residuo Radiactivo · Barril Explosivo · Mutante | Reactor Roto |
| 8 | Pesticidas y agricultura | Dron Pesticida · Nube de Fumigación · Plaga | Helicóptero Fumigador |
| 9 | Deforestación | Talador · Motosierra · Incendio | Aserradero Andante |
| 10 | Cambio climático | Ola de Calor · Tormenta · Deshielo | Calentamiento Global |

### Jugador

- **`quark`** es el jugador principal; sus componentes se crean por código en `_ready`:
  `DashComponent`, `AnimacionQuark`, `EfectoRegeneracion`, `FlechaArbol`,
  `SuperMeteoritos` (lluvia de meteoritos), `ContadorRespawn`, `SelectorObjetivo`,
  `EnemigosUtil`. Clases adicionales: `aura`, `cronos`, `flora`, `geo`.
- Balance de referencia (oleada 1): DPS base ≈ 17 (12 daño / 0.5 s) + 5 % crítico;
  100 HP + regeneración tras unos segundos + i-frames de dash
  (`velocidad_dash`, `cooldown_dash`, `invulnerable_en_dash = true`).

### Escenarios por etapa

- "Mismo valle, distinta piel": **no se genera terreno nuevo**. La etapa 1 deja el
  `valle` original intacto; las demás **recolorean** la geometría existente con la
  paleta del `TemaEtapa` (mismos límites/colisiones) y añaden props temáticos.
- `GestorEtapa` aporta tinte de ambiente, partículas, banner "ETAPA N · TEMA" y
  peligro característico (zonas de daño temáticas).

---

## 🎓 Sistema educativo (pilar, no extra)

- Basado en **Teoría del Aprendizaje Significativo + Gamificación**.
- `EducationManager` crea el popup en `_ready()`, detecta settings por grupo/tipo y
  usa `EducationDataStages` si no hay etapas embebidas. Es tolerante a fallos:
  **nunca crashea por propiedades ausentes** (usa `.get()`), y resuelve ids
  normalizando tildes/espacios/guiones + alias por nombre visible.
- Datos en `scripts/education/education_data_stages.gd` (temas, datos, muertes y
  enemigos con `represents` y `facts`); datos generales en `education_data_general.gd`.
- API para WaveManager/jugador: `set_data`, `start_run`, `stop_run`,
  `on_stage_started`, `on_wave_started/ended`, `on_enemy_encountered`,
  `on_boss_defeated`, `show_wave_break/death/survival_fact`, `get_discovered`.
- `EducationPopup` v6.1: variantes `WAVE_BREAK`, `DEATH`, `ENEMY_CARD`, `SURVIVAL`;
  estilos `CARD`/`SUBTITLES`. Duración por defecto 3.5 s.
- La primera oleada espera a que terminen los mensajes iniciales (señal
  `liberar_arranque()` o timeout).

---

## 🃏 Mejoras / cartas

- `MejorasManager` mapea `id_carta → Array de [ruta_stat, op, valor]`:
  - `pct` → `stat *= (1 + valor)` (p. ej. 0.20 = +20 %)
  - `add` → `stat += valor`
  - `mult` → `stat *= valor`
- **Acumulable:** cada compra reaplica su delta (no hay mejoras "únicas").
- Definición de cartas en `ecenes/cards/` (`CartasConfig.gd`, `MejorasConfig.gd`).

---

## 🌐 Web (landing)

- Astro 7 + React 19 + Tailwind 4 + `lucide-react` y `marked`.
- Secciones en `web/src/components/sections/`: `Hero`, `QueEs`, `Problema`,
  `Objetivos`, `Mecanicas`, `Etapas`, `MarcoTeorico`, `Galeria`, `Metodologia`,
  `Equipo`, `Descargar`, `Footer`.
- **Datos de etapas duplicados** en `web/src/lib/etapas.ts` (espejo manual de
  `education_data_stages.gd`). Al cambiar temas/enemigos en el juego, **sincroniza ambos**.
- `web/src/lib/github.ts` consulta estadísticas de GitHub; `apa.ts` para citas.

---

## 🛠️ Tecnologías

| Componente | Tecnología |
| :--- | :--- |
| Motor de juego | Godot Engine 4.7 (Forward Plus, Jolt Physics) |
| Lenguaje principal | GDScript (+ C# habilitado) |
| Web | Astro 7 · React 19 · Tailwind 4 |
| Control de versiones | Git / GitHub |
| Licencia | MIT |

---

## 🗺️ Mapa "dónde mirar" por tarea

| Quiero tocar… | Archivos/rutas clave |
| :--- | :--- |
| Oleadas, spawns, escalado | `scripts/wave_manager.gd` |
| Etapas (temas, multiplicadores, jefe) | `scripts/etapa_config.gd`, `ecenes/enemies/etapas/etapa_*.tres` |
| Ventana de oleadas por enemigo | `scripts/enemigo_oleada_config.gd` |
| Generar enemigos/jefes en masa | `tools/generar_enemigos.gd` |
| Enemigo base y comportamientos | `ecenes/enemies/class/`, `.../comportamientos/` |
| Jefe (ataques) | `ecenes/enemies/class/BossAttackComponent.gd`, `proyectil_jefe.gd` |
| Contenido educativo | `scripts/education/` |
| Tarjetas y mejoras | `ecenes/cards/`, `scripts/mejoras_manager.gd` |
| Jugador / combate | `ecenes/players/quark/` (+ `aura`, `cronos`, `flora`, `geo`) |
| Escenario por etapa | `ecenes/etapas/gestor_etapa.gd`, `escenario_etapa.gd`, `tema_etapa.gd` |
| UI | `ui/` (`main/`, `intro/`, `dead/`, `ajustes/`, `slots/`, `controles/`) |
| Web (secciones) | `web/src/components/sections/`, `web/src/lib/etapas.ts` |

---

## 🐞 Debug

- **F9** muestra una carta de prueba del popup educativo.
- **F10** invierte la posición; **F11** cicla el estilo del popup (solo builds debug).
- `WaveManager`: exporta `debug_activo`, `debug_oleada_inicial`, `debug_no_guardar`,
  `debug_spawnear_enemigos` para arrancar en una oleada concreta sin ensuciar el guardado.
- `BiomasaManager`: `DEBUG` y `AUTOTEST_AL_INICIAR` imprimen quién cambia el contador.
- Input actions del proyecto: `super`, `mega`, `debug_kill` (tecla K), `debug`.

---

## 🤝 Flujo de trabajo con Git

- Ramas por feature: `feature/<tema>` (p. ej. `feature/10-update-wavemanager-enemis`).
- **Commits atómicos:** un commit = un cambio lógico y aislado.
- Formato: `<prefijo>: <descripción corta>` con prefijos `feature:`, `fix:`, `add:`
  y `choire:` (mantenimiento/limpieza). Descripción corta **en inglés**.
- **Nunca** comitees `apk/`, `assets/`, `addons/`, `.godot/` ni los `.aider*`.

---

## 👥 Equipo de desarrollo

- **Juan Felipe Casas Aguilar** — Programación principal en GDScript, diseño de mecánicas e integración en Godot Engine.
- **Emmanuel Efrén Rosero Sánchez** — Diseño principal de assets y programación en GDScript.
- **Miguel Ángel Murcia Galindo** — Investigación, revisión teórica/histórica y programación en GDScript.

---

## 🏫 Institución y marco académico

- **Institución Educativa:** I.E. Técnico Industrial "Julio Flórez"
- **Especialidad:** Sistemas Informáticos
- **Programa:** Articulación SENA – Técnico en Desarrollo de Software

---

## 🔗 Enlaces

- **Repositorio:** [github.com/l1teSG/dirty-road-godot](https://github.com/l1teSG/dirty-road-godot)
- **Landing / micrositio:** código en [`web/`](web/)
- **Documentación de diseño:** [`docs/DirtyRoad_GDD.md`](docs/DirtyRoad_GDD.md) *(en progreso)*

---

## 📄 Licencia

Distribuido bajo la **Licencia MIT**. Consulta [`LICENSE`](LICENSE) para más detalles.
