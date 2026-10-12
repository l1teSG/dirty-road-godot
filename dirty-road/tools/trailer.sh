#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════
#  Trailer del juego → AVI (Movie Maker de Godot) → MP4 H.264 1080p.
#  Uso:  tools/trailer.sh [segundos] [escena]
#  Ej.:  tools/trailer.sh 20
#        tools/trailer.sh 30 "res://demo/level 1/niviel1.tscn"
#
#  Variables: GODOT (ruta), FPS (por defecto 60).
#  Salida: dirty-road/capturas/trailer.mp4  (+ .avi intermedio).
#  Requiere display/GPU (no headless) y ffmpeg.
# ══════════════════════════════════════════════════════════
set -euo pipefail

GODOT="${GODOT:-/usr/bin/godot}"
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$PROJ/capturas"
DUR="${1:-20}"
ESCENA="${2:-res://demo/level 1/niviel1.tscn}"
FPS="${FPS:-60}"
AVI="$OUT/trailer.avi"
MP4="$OUT/trailer.mp4"
FRAMES=$(( DUR * FPS ))

command -v ffmpeg >/dev/null || { echo "Falta ffmpeg"; exit 1; }
mkdir -p "$OUT"
echo "[trailer] Grabando $DUR s ($FRAMES frames @ ${FPS}fps) de $ESCENA"

"$GODOT" --path "$PROJ" \
	--write-movie "$AVI" \
	--fixed-fps "$FPS" \
	--disable-vsync \
	--quit-after "$FRAMES" \
	"$ESCENA"

echo "[trailer] Convirtiendo a MP4 H.264 1080p…"
ffmpeg -y -i "$AVI" \
	-c:v libx264 -pix_fmt yuv420p -crf 20 -preset medium \
	-movflags +faststart "$MP4"

echo "[trailer] Listo → $MP4"