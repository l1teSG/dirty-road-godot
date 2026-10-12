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