# Herramientas (`tools/`)

Scripts de apoyo para desarrollo, verificación y material audiovisual.
Ejecutar desde `dirty-road/` o con rutas absolutas.

## Verificar cartas

```sh
godot --headless --script res://tools/verificar_cartas.gd
```

Comprueba las 4 fuentes de datos de las cartas
(`catalogoCards.gd`, `descripciones.gd`, `mejorasConfig.tres`, `EFECTOS`):
- 1:1 por slug (nada falta, nada sobra).
- Sin nombres/slugs duplicados.
- Rutas de stats válidas (según `SaveManager.DATOS_DEFECTO`).
- Rareza válida y `precio == costo_de(rareza)`.
- Descripción no vacía.

Sale con código `1` si hay fallos. Ejemplo:

```
[CARTAS] cartas=84  descripciones=84  efectos(.tres)=84  efectos(EFECTOS)=84
[CARTAS] fallos=0  avisos=0
[CARTAS] ✅ OK
```

## Verificar enemigos

```sh
godot --headless --script res://tools/verificar_enemigos.gd
```

Generar/regenerar escenas de enemigos:

```sh
godot --headless --script res://tools/generar_enemigos.gd
```

## Capturas para los documentos

```sh
tools/generar_capturas_docs.sh            # todas
tools/generar_capturas_docs.sh hud        # solo una
```

Genera en `capturas/docs/` los PNG (1536×864) que usa el manual y la
presentación: `intro`, `menu`, `slots`, `ajustes`, `dead`, `hud`, `jefe`,
`cartas` (Movie Maker + modo captura).

## Modo Captura / Trailer

Herramienta interactiva (solo builds debug) para **montar escenas a mano** y
sacar capturas y vídeo sin combatir. En `demo/level 1/niviel1.tscn` hay un nodo
**ModoCaptura** (`tools/modo_captura.gd`):

- **F2** abre/cierra el panel.
- Elige **etapa → enemigo/jefe** y pulsa *Spawnear* (cualquiera de las 10 etapas).
- **Clic** sobre un enemigo = seleccionar; **arrastrar** para moverlo; **flechas**
  para ajuste fino; **D** duplicar; **Supr** borrar.
- **G** congela/descongela la IA (los enemigos se quedan quietos en su pose).
- **F** modo foto (oculta HUD y popups); *Ocultar jugador* lo esconde aparte.
- *Cámara libre*: **WASD** panea, **+ / −** zoom.
- **ESPACIO** pausa/reanuda la simulación.
- **C** → PNG en `user://capturas/modo/`.
- **R** → graba una secuencia de frames en `user://videos/grabacion_<fecha>/`.

Las oleadas se desactivan solas (WaveManager en modo debug sin spawns) y no se
guarda partida.

### Convertir una grabación a MP4

```sh
tools/montaje_video.sh [carpeta_de_frames] [fps] [salida.mp4]
# ej. (toma la última grabación)
tools/montaje_video.sh
```

## Fotos (capturas)

### En juego (manual)
En `demo/level 1/niviel1.tscn` hay un nodo **Captura** (solo en builds debug):
- **C** → guarda un PNG en `user://capturas/`.
- **V** → alterna **modo foto** (oculta el HUD para tomas limpias).
- Opcional: `auto_cada_seg > 0` captura cada N segundos.

### Por secuencia (automático)
```sh
tools/capturas.sh [segundos] [escena]
# ej.
tools/capturas.sh 8
```
Genera `capturas/frame0001.png`, `frame0002.png`, … con el Movie Maker de Godot.

## Trailer

```sh
tools/trailer.sh [segundos] [escena]
# ej.
tools/trailer.sh 20
```
Graba con el Movie Maker (`--write-movie`) y convierte a
**MP4 H.264 1080p** con `ffmpeg` → `capturas/trailer.mp4`.

- `FPS=60` (por defecto), `GODOT=/usr/bin/godot`.
- Requiere display/GPU (no funciona en `--headless`).
- Truco: arrancar una oleada de jefe con los overrides de debug del
  `WaveManager` (`debug_activo`, `debug_oleada_inicial`).

> `capturas/` está en `.gitignore` (no se versiona el material generado).