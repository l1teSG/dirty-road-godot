#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════
#  Monta un vídeo a partir de la secuencia PNG que graba el
#  MODO CAPTURA (tecla R / botón "Grabar").
#
#  Uso:  tools/montaje_video.sh [carpeta] [fps] [salida]
#    carpeta : carpeta con frame_00000.png, frame_00001.png, …
#              (por defecto, la última dentro de user://videos)
#    fps     : fotogramas por segundo (por defecto 30)
#    salida  : ruta del .mp4 (por defecto <carpeta>.mp4)
#
#  Ej.:  tools/montaje_video.sh ~/.local/share/godot/app_userdata/dirty\ road/videos/grabacion_2026-10-20 30 /tmp/clip.mp4
#
#  Requiere ffmpeg.
# ══════════════════════════════════════════════════════════
set -euo pipefail

PROJ="$(cd "$(dirname "$0")/.." && pwd)"
FPS="${2:-30}"

# Ruta de user:// (app_userdata/<nombre proyecto>) como fallback.
USER_DIR="${HOME}/.local/share/godot/app_userdata/dirty road"

CARPETA="${1:-}"
if [[ -z "$CARPETA" ]]; then
	# Toma la grabación más reciente.
	CARPETA="$(ls -1dt "$USER_DIR"/videos/grabacion_* 2>/dev/null | head -n1 || true)"
fi
[[ -n "$CARPETA" && -d "$CARPETA" ]] || { echo "No encuentro carpeta de frames: '$CARPETA'"; exit 1; }

SALIDA="${3:-${CARPETA%/}.mp4}"
command -v ffmpeg >/dev/null || { echo "Falta ffmpeg"; exit 1; }

echo "[montaje] frames: $CARPETA  @ ${FPS}fps → $SALIDA"
ffmpeg -y -framerate "$FPS" -i "$CARPETA/frame_%05d.png" \
	-c:v libx264 -pix_fmt yuv420p -crf 18 -preset medium \
	-movflags +faststart "$SALIDA"
echo "[montaje] Listo → $SALIDA"
