# DIRTY ROAD — GAME DESIGN DOCUMENT
### Infinite Ecological Survival Action Game
**Prepared as:** AAA Game Design + UX + Educational Gamification + Godot 4.7 Technical Design Document

**Version:** 10.0.0 beta · **Engine:** Godot 4.7 (Forward Plus, Jolt Physics) · **Language:** GDScript (+ C#)
**License:** Proprietary (All Rights Reserved) · **Status:** In development (living document)

---

## 1. CORE VISION

Dirty Road is an infinite top-down/2D action-survival game where the player defends a living Tree — the last symbol of a healthy ecosystem — against endless waves of enemies that represent real environmental threats. There is no ending, no victory screen, no "final boss of pollution." Pollution is systemic and cyclical, exactly like in reality: you can never fully defeat it, only manage it, slow it down, and keep the ecosystem alive as long as possible.

**Design Pillars:**
1. **Learn by Playing, Not by Reading.** Every fact is delivered through combat feedback, visuals, audio, and short contextual pop-ups (never blocking, never longer than 3-4 seconds).
2. **Infinite, Not Repetitive.** The world itself evolves (Pollution Index, seasons, mutators, dynamic events) so hour 3 feels different from hour 1.
3. **Skill Over Grind.** Progression is about mastery (dash timing, positioning, combo routing) and cosmetic/informational unlocks — not raw power creep that would break infinite balance.
4. **Every Enemy Teaches Something.** No generic "monster" — every enemy, mini-boss, and event maps 1:1 to a real ecological problem.
5. **The World Reacts to You.** Visual/audio state of the game is a living dashboard of ecosystem health.

**Audience:** Players 10+, classrooms, and general audiences. The educational layer is a first-class pillar, not a bolt-on.

---

## 2. CORE LOOP

The session loop is a **defend-the-Tree survival loop** structured in escalating blocks:

```
Spawn into a stage  →  Fight a timed wave  →  Clear / survive the wave
        ▲                                              │
        │                                              ▼
  Next wave / stage  ◄──  Cross the door  ◄──  Wave break: pick upgrades
        │                                              │
        └──────────────  Boss wave every 10th  ◄───────┘
```

1. **Survive a timed wave.** Enemies spawn continuously every `tiempo_entre_spawns` seconds until the wave clock runs out. Killing enemies does **not** advance the wave — the clock does. The player must defend the Tree while surviving.
2. **Wave break.** After the wave ends there is a short rest (`tiempo_descanso`). During breaks (every `mostrar_cada_n_oleadas`) the player is offered upgrade cards to buy with Biomasa.
3. **Escalate within the stage.** Each successive wave in a stage is longer (`aumento_duracion_por_oleada`) and spawns more enemies (`enemigos_base_por_oleada + incremento_enemigos_por_oleada`).
4. **Boss wave.** The 10th (last) wave of every stage is a **boss wave**: no clock, it closes only when the boss dies. Normal escorts spawn from the stage pool up to `jefe_escoltas`.
5. **Cross the door.** When the stage ends, the game does **not** auto-advance; it waits for the player to cross the door, then loads the next stage with the same valley, re-skinned.
6. **Repeat infinitely.** Stages cycle with inherited enemies (`heredar_enemigos_anteriores`), rising multipliers and faster pressure.

**Win/lose:** There is no win. The run ends only when the **Tree** (or the player) dies. The score is *how long the ecosystem survived* — tracked per save slot (wave, stage, biomass, time).

---

## 3. WAVE & STAGE SYSTEM

### 3.1 Structure

- **10 stages × 10 waves = 100 waves** per full cycle.
- Each stage defines **3 new normal enemies + 1 boss** (30 normals + 10 bosses total).
- Enemies from previous stages keep appearing (`heredar_enemigos_anteriores = true`), so the pool grows every stage.
- Stage index for a global wave: `clamp((oleada_global − 1) / 10, 0, stages − 1)`.

### 3.2 The clock is the pressure knob

The single most important tuning value is `tiempo_entre_spawns` (default `1.2 s`). Lower = more enemies per wave. Everything else scales the enemies themselves, not the cadence.

### 3.3 Scaling formulas

```
Vida       = base × etapa.mult_vida × cfg.mult_vida × (1 + (oleada − 1) × escalado_vida)
Daño       = base × etapa.mult_danio × (1 + (oleada − 1) × escalado_danio)
Velocidad  = base × etapa.mult_velocidad              (does NOT scale per wave)
Duración   = base × (1 + aumento_micro × (N − 1)) × (1 + aumento_macro × etapa)
```

| Parameter | Default | Meaning |
| :--- | --: | :--- |
| `tiempo_maximo_oleada` | 40 s | Base wave duration. |
| `tiempo_descanso` | 5 s | Rest between waves. |
| `aumento_duracion_por_oleada` | 0.10 | +10 % duration per wave inside a stage (micro). |
| `aumento_duracion_por_etapa` | 0.0 | +% duration per stage (macro). |
| `escalado_vida_por_oleada` | 0.07 | +7 % enemy HP per global wave. |
| `escalado_danio_por_oleada` | 0.04 | +4 % enemy damage per global wave. |
| `oleadas_por_etapa` | 10 | Waves per stage. |
| `jefe_escoltas` | 4 | Normal escorts during a boss wave. |
| `jefe_tiempo_descanso` | 15 s | Rest after a boss dies. |

> **Contract:** `WaveManager` (`scripts/wave_manager.gd`) is the **single source of truth** for waves, spawns and scaling. Life/speed/damage are applied **before** `add_child`, and player/Tree references are injected by group (with cache). Never duplicate this logic elsewhere.

### 3.4 Per-enemy spawn window

`EnemigoOleadaConfig` (`scripts/enemigo_oleada_config.gd`) defines when each enemy can appear:

| Field | Meaning |
| :--- | :--- |
| `oleada_minima` / `oleada_maxima` | Wave window (`0` = no limit). |
| `peso` | Relative spawn weight within the pool. |
| `max_simultaneos` | Cap of simultaneous instances of this enemy. |
| `mult_vida` | Per-enemy HP multiplier on top of the stage scaling. |

---

## 4. ENEMY DESIGN

### 4.1 Archetypes (`TIPO_DEF` in `tools/generar_enemigos.gd`)

| Archetype | HP | Speed | Damage | Contact damage | Role |
| :--- | --: | --: | --: | :--- | :--- |
| **enjambre** (swarm) | 22 | 150 | 10 | yes | Fast, fragile, swarms the player. |
| **melee** | 65 | 80 | 18 | no | Durable brawler, heavy melee hits. |
| **rango** (ranged) | 26 | 95 | 9 | no | Keeps distance, harasses. |
| **torreta** (turret) | 90 | 60 | 12 | no | Slow, tanky, area denial. |
| **embestida** (charger) | 80 | 75 | 22 | yes | Commits to charge attacks. |

Every enemy is a modular scene under `ecenes/enemies/main/<range>/` built on `ecenes/enemies/class/` with interchangeable **behaviors** (`comportamientos/`). New enemies must implement the damage contract `recibir_danio(cantidad)` and resolve nodes **by group**, never by hard paths.

### 4.2 Bosses

- One boss per stage, spawned on the last wave (`jefe_escena` in `EtapaConfig`).
- Boss attacks live in `BossAttackComponent.gd`; projectiles in `proyectil_jefe.gd`.
- Boss waves have **no clock**; they close only on the boss's death, then a longer rest plays.
- Bosses are the loudest teaching moment: on defeat, `EducationManager` shows a `boss_defeated` message tied to the stage theme.

### 4.3 Boss roster

| Stage | Theme | Boss |
| --: | :--- | :--- |
| 1 | Soil and air pollution | Excavadora Tóxica |
| 2 | Trash and landfills | Vertedero Viviente |
| 3 | Oceans and plastic | Isla de Plástico |
| 4 | Industrial pollution | Chimenea Gigante |
| 5 | Acid rain | Géiser Ácido |
| 6 | Electronic waste | Montaña de Chatarra |
| 7 | Nuclear energy and radiation | Reactor Roto |
| 8 | Pesticides and agriculture | Helicóptero Fumigador |
| 9 | Deforestation | Aserradero Andante |
| 10 | Climate change | Calentamiento Global |

---

## 5. PLAYER DESIGN

### 5.1 Character

- Protagonist: **Renata**; the playable node is **Quark** (`ecenes/players/quark/quark.tscn`).
- Components are created in code in `_ready`: `DashComponent`, `AnimacionQuark`, `EfectoRegeneracion`, `FlechaArbol`, `SuperMeteoritos`, `ContadorRespawn`, `SelectorObjetivo`, `EnemigosUtil`.
- Additional playable classes live in `aura`, `cronos`, `flora`, `geo`.

### 5.2 Combat

- **Ranged auto-attack** (toggleable with `disparo_automatico`) plus manual aim (right stick / joystick on mobile).
- Reference balance (wave 1): ≈ 17 DPS (12 damage / 0.5 s cadence) + 5 % crit chance (1.75× crit multiplier).
- Stats are **never hard-assigned**: player and Tree read from `SaveManager.stats` (base + upgrades).

### 5.3 Survival tools

| Tool | Reference value | Notes |
| :--- | :--- | :--- |
| HP | 100 | Player pool. |
| Regen | 0.6 HP/s after 6 s | `EfectoRegeneracion`. |
| Dash | `velocidad_dash 620`, `cooldown_dash 1.1` | Grants i-frames (`invulnerable_en_dash = true`). |
| Super | `COSTO_SUPER = 10` Biomasa | Meteor rain (`SuperMeteoritos`). |
| Death | `ContadorRespawn` | Respawn countdown instead of instant game over. |

### 5.4 The Tree (defense objective)

- The Tree (`arbol` group) is the ecosystem the player protects; it has its own HP, regen and defensive stats (`SaveManager.stats.arbol`).
- Tree upgrades (armor, thorns, regen, barrier, freeze) come from cards, reinforcing the "protect the ecosystem" fantasy.

---

## 6. PROGRESSION & ECONOMY

### 6.1 Biomasa

- Currency dropped by enemies as orbs; collected by the player.
- `BiomasaManager.contador` is **a cost, not a cap**: it has no upper limit and leftover biomass is preserved. Spending the Super costs `10`.
- Persisted through `SaveManager` per slot.

### 6.2 Upgrade cards

- Offered during wave breaks (every `mostrar_cada_n_oleadas`, min wave `min_oleada`), `cartas_por_descanso = 3` choices, multi-buy allowed.
- `MejorasManager` maps `id_carta → [stat_path, op, value]`:
  - `pct` → `stat *= (1 + value)` (e.g. `0.20` = +20 %)
  - `add` → `stat += value`
  - `mult` → `stat *= value`
- **Stackable:** every purchase re-applies its delta; there are no "unique" upgrades.

### 6.3 Rarity

| Rarity | Weight | Cost | Min wave | Color |
| :--- | --: | --: | --: | :--- |
| Común | 100 | 20 | 1 | `#7fdcb0` |
| Rara | 40 | 35 | 3 | `#5ee6a0` |
| Épica | 12 | 60 | 6 | `#99ff33` |
| Legendaria | 3 | 100 | 10 | `#ffd54a` |

Card families: **Tree/defense** (reforestación, muro de eco-ladrillos, barrera, espinas), **Offense** (herramienta reciclada, molino de viento, lentes solares, perforación, proyectiles extra), **Movement/utility** (bicicleta ecológica, zapatillas de caucho, orbes, suerte, esquiva) and one **mixed legendary** (fuerza de la naturaleza: +damage, −cadence, −speed).

> **Known debt:** several stats are stored but not yet consumed by a mechanic ("hook pendiente"), e.g. `congelar`, `danio_elite`, `danio_acuaticos`, `danio_continuo`, `danio_toxico`, `detonar_prob`, `inmunidad_nube`, `bonus_quieto`, `paralizar`, `aturdir`, `dron`. They will be wired to projectiles, auras and AI.

---

## 7. EDUCATIONAL SYSTEM

A core pillar based on **Meaningful Learning Theory + Gamification**.

### 7.1 Delivery

- **Short, non-blocking pop-ups** (`EducationPopup` v6.1, default 3.5 s) with variants: `WAVE_BREAK`, `DEATH`, `ENEMY_CARD`, `SURVIVAL`; styles `CARD` / `SUBTITLES`.
- Facts surface through **combat feedback** (enemy cards on first encounter), wave breaks, death messages and survival facts.

### 7.2 Content model

- `EducationManager` (autoload) creates the popup in `_ready()`, reads settings and falls back to `EducationDataStages` when stages carry no embedded data.
- Data: `scripts/education/education_data_stages.gd` (per-stage theme, intro, facts, death lines, boss line, action, and per-enemy `represents` + `facts`) and `education_data_general.gd`.
- **Fail-safe by design:** never crashes on missing properties (uses `.get()`); resolves ids by normalizing accents/spaces/hyphens plus visible-name aliases.

### 7.3 API (used by WaveManager / player)

`set_data`, `start_run`, `stop_run`, `on_stage_started`, `on_wave_started`/`on_wave_ended`, `on_enemy_encountered`, `on_boss_defeated`, `show_wave_break`/`show_death`/`show_survival_fact`, `get_discovered`.

### 7.4 Startup gate

The first wave waits until the initial educational messages finish (`liberar_arranque()` signal or a `tiempo_maximo_espera` timeout), so the player is never attacked mid-intro.

### 7.5 Player control over the layer

Settings expose `edu_escala`, `edu_posicion`, `edu_duracion_mult`, `edu_insignia` and `edu_sonido` — the educational layer is **adjustable, never forced**.

---

## 8. WORLD & STAGE PRESENTATION

- **"Same valley, different skin":** no new terrain is generated. Stage 1 leaves the original `valle` untouched; later stages **recolor** the existing geometry with the `TemaEtapa` palette (same limits/collisions) and add themed props.
- `GestorEtapa` provides ambient tint, particles, an "ETAPA N · TEMA" banner and a signature **hazard** (themed damage zones) per stage.
- `escenario_etapa.gd` / `tema_etapa.gd` drive the re-skin; `puerta.gd` handles the door transition between stages.
- The scene is a **living dashboard**: palette, particles and audio reflect ecosystem health and current stage.

---

## 9. UX / HUD / MENUS

### 9.1 Screens (`ui/`)

| Screen | Purpose |
| :--- | :--- |
| `intro/` | Title / main menu (project main scene). |
| `main/` | In-game HUD (`main.tscn`, `wave_ui.gd`, `barra_jefe.gd`). |
| `slots/` | Save-slot management (5 slots). |
| `ajustes/` | Settings (tabbed: audio, video, education, HUD, controls). |
| `controles/` | Input / control configuration. |
| `dead/` | Death / run-over screen. |
| `cartel_inicio/` | Intro banners. |

### 9.2 HUD

- Wave timer + wave counter, remaining enemies, biomass counter, boss health bar.
- Fully scalable HUD (`hud_escala`) and opacity (`hud_opacidad`).
- `wave_ui.gd` consumes `WaveManager` signals (`tiempo_actualizado`, `enemigos_restantes_actualizado`, `jefe_aparecido`, …).

### 9.3 Controls

- Desktop: keyboard + mouse (auto-aim or manual).
- Mobile/Android: dual virtual joysticks (movement + aim) and touch-friendly buttons; sensor landscape orientation.
- Project input actions: `super`, `mega`, `debug_kill` (key K), `debug`.

### 9.4 Feedback rules

- **Never blocking, never > 3-4 s** for educational pop-ups.
- Clear telegraphs for hazards and boss attacks.
- Death is informative, not punitive: `ContadorRespawn` plus a themed `death` message.

---

## 10. PERSISTENCE

- **Per-slot saves (max 5):** `user://partida_1..5.save`.
- **Slot metadata:** `user://slots.json` (wave, stage, biomass, date, play time, last used slot).
- **Global settings:** `user://ajustes.save` — **not** erased by "New Game".
- `SaveManager` (autoload) is the **single source of truth** for saved stats; `datos` = `DATOS_DEFECTO` base plus applied upgrades.

---

## 11. TECHNICAL DESIGN

### 11.1 Stack

- **Godot 4.7**, Forward Plus renderer, C# enabled; 3D physics engine = **Jolt**.
- Primary language **GDScript** (mixed Spanish/English naming).
- Target resolutions: 1920×1080 viewport, `canvas_items` stretch, `expand` aspect; Android export (`com.l1t3Sg.dirtyroad`).

### 11.2 Autoloads (order matters)

| Autoload | Script | Responsibility |
| :--- | :--- | :--- |
| `EducationManager` | `scripts/education/EducationManager.gd` | Educational pop-ups, discoveries, wave/death messages. |
| `SaveManager` | `scripts/save_manager.gd` | Single source of stats + slot persistence. |
| `BiomasaManager` | `ecenes/players/quark/BiomasaManager.gd` | Biomass counter (no cap) and Super cost. |
| `MejorasManager` | `scripts/mejoras_manager.gd` | Applies cards/upgrades to `SaveManager` stats. |
| `AudioManager` | `scripts/audio_manager.gd` | Buses and code-generated SFX; volumes from settings. |

> ⚠️ `SaveManager` **must** precede `BiomasaManager` (the latter reads `SaveManager` on boot).

### 11.3 Contracts (do not break)

- **Damage:** enemies call `recibir_danio(cantidad)`; nodes are found **by group** (`jugador`, `enemi`, `arbol`, `player`, `fire_player`).
- **Scaling point:** `WaveManager` applies life/speed/damage **before** `add_child` and injects player/Tree refs by group (cached).
- **Do not rename** `mult_vida`, `mult_velocidad`, `mult_danio` in `EtapaConfig` — read by exact name.
- **Biomass:** a cost, not a cap; leftovers are kept.

### 11.4 Content pipeline

- `tools/generar_enemigos.gd` generates enemy scenes and `EtapaConfig` resources in bulk (tables `NORMALES`, `TIPO_DEF`).
- `tools/verificar_enemigos.gd` verifies enemy/stage consistency.
- Stage resources: `ecenes/enemies/etapas/etapa_02..10.tres` (stage 1 authored by hand).

---

## 12. AUDIO

- `AudioManager` (autoload) builds buses and SFX **in code**; volumes (`vol_master`, `vol_musica`, `vol_efectos`) come from settings.
- Audio is part of the "world reacts to you" pillar: the mix reflects combat intensity and ecosystem state.

---

## 13. ART DIRECTION

- **2D, non-pixel-art** — clean shapes, atmospheric lighting and particles over the re-skinned valley.
- Palette per stage from `TemaEtapa`; consistent UI theme (`themes/mainTheme.tres`, Chakra Petch font family).
- Card visuals in `ecenes/cards/` (`carta.gd`, `cartaIcono.gd`, `constructorCarta.gd`).

---

## 14. ACCESSIBILITY & SETTINGS

- Adjustable educational pop-ups (scale, position, duration, sound, badge).
- Adjustable HUD (scale, opacity) and background shader toggle.
- Separate master/music/SFX volumes.
- Auto-fire option; touch and desktop control schemes.

---

## 15. APPENDIX — STAGE TABLE

| # | Theme | Normal enemies | Boss |
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

---

## 16. OPEN QUESTIONS / NEXT STEPS

- **Complete the GDD:** economy depth, season/mutator systems, dynamic events, and the Pollution Index are still to be specified.
- **Wire pending upgrade hooks** (projectiles, auras, AI immunities).
- **Synchronize** `web/src/lib/etapas.ts` with `education_data_stages.gd` whenever stage/enemy data changes (manual mirror).
- **Clean up unused addons** (`godot_rl_agents`, `godotty`) if confirmed unused in gameplay.
- `assets/` and `addons/` are **not** in git — a clean clone cannot reproduce the game until restored.
