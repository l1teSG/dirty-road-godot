#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════
#  Capturas del juego → secuencia de PNG con el Movie Maker de Godot.
#  Uso:  tools/capturas.sh [segundos] [escena]
#  Ej.:  tools/capturas.sh 8
#        tools/capturas.sh 15 "res://demo/level 1/niviel1.tscn"
#
#  Salida: dirty-road/capturas/frame0001.png, frame0002.png, ...
#  Requiere display/GPU (no headless). GODOT_FPS para ajustar el muestreo.
# ══════════════════════════════════════════════════════════
set -euo pipefail

GODOT="${GODOT:-/usr/bin/godot}"
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$PROJ/capturas"
DUR="${1:-8}"
ESCENA="${2:-res://demo/level 1/niviel1.tscn}"
FPS="${GODOT_FPS:-10}"
FRAMES=$(( DUR * FPS ))

mkdir -p "$OUT"
echo "[capturas] $DUR s ($FRAMES frames @ ${FPS}fps) de $ESCENA"

"$GODOT" --path "$PROJ" \
	--write-movie "$OUT/frame.png" \
	--fixed-fps "$FPS" \
	--quit-after "$FRAMES" \
	"$ESCENA"

echo "[capturas] Listo → $OUT"