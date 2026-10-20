#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════
#  Graba un trailer a partir de un guion JSON del modo trailer.
#
#  Uso:  tools/grabar_trailer.sh <guion.json> [salida.mp4]
#    ej. tools/grabar_trailer.sh tools/trailers/general.json
#
#  · Grabación NO-realtime con el Movie Maker de Godot (--fixed-fps).
#  · Escala a 1080p con lanczos y quita el audio (mudo).
#  · Salida por defecto: capturas/trailers/<guion>.mp4
#
#  Variables: GODOT, FPS (60), W (1920), H (1080).
#  Requiere display/GPU (no headless) y ffmpeg.
# ══════════════════════════════════════════════════════════
set -euo pipefail

GUION="${1:?uso: tools/grabar_trailer.sh <guion.json> [salida.mp4]}"
GODOT="${GODOT:-/usr/bin/godot}"
FPS="${FPS:-60}"
W="${W:-1920}"
H="${H:-1080}"
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
OUTDIR="$PROJ/capturas/trailers"
mkdir -p "$OUTDIR"

# Ruta absoluta del guion (Godot lo lee desde el sistema de archivos).
GUION="$(cd "$(dirname "$GUION")" && pwd)/$(basename "$GUION")"
NOMBRE="$(basename "$GUION" .json)"
SALIDA="${2:-$OUTDIR/$NOMBRE.mp4}"

command -v ffmpeg >/dev/null || { echo "Falta ffmpeg"; exit 1; }

DUR="$(python3 -c "import json;print(json.load(open('${GUION}'))['duracion'])")"
FRAMES="$(python3 -c "print(int(float('${DUR}')*${FPS})+20)")"

TMP="$(mktemp -d)"
AVI="$TMP/$NOMBRE.avi"
echo "[trailer] $NOMBRE · ${DUR}s · $FRAMES frames @ ${FPS}fps → $SALIDA"

"$GODOT" --path "$PROJ" \
	--write-movie "$AVI" \
	--fixed-fps "$FPS" \
	--disable-vsync \
	--quit-after "$FRAMES" \
	"res://demo/level 1/niviel1.tscn" \
	-- "--trailer=$GUION" >"$TMP/log.txt" 2>&1 || true

if [[ ! -f "$AVI" ]]; then
	echo "ERROR: no se generó el AVI. Log:"; tail -n 20 "$TMP/log.txt"; rm -rf "$TMP"; exit 1
fi

ffmpeg -y -i "$AVI" -an \
	-vf "scale=${W}:${H}:flags=lanczos" \
	-c:v libx264 -pix_fmt yuv420p -crf 18 -preset slow -movflags +faststart \
	"$SALIDA" >/dev/null 2>&1

rm -rf "$TMP"
echo "[trailer] listo → $SALIDA"
