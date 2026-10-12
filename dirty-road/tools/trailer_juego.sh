#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════
#  Graba clips de gameplay (una etapa por clip) con el jugador pilotado.
#  Salida: dirty-road/capturas/trailer_clips/<slug>.avi (1920x1080).
#  Uso: tools/trailer_juego.sh [clips_dir]
#  Requiere display/GPU.
# ══════════════════════════════════════════════════════════
set -euo pipefail

GODOT="${GODOT:-/usr/bin/godot}"
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$PROJ/capturas/trailer_clips}"
ESCENA="res://demo/level 1/niviel1.tscn"
FPS="${FPS:-30}"
DUR="${DUR:-3}"
FRAMES=$(( DUR * FPS ))

mkdir -p "$OUT"

# oleada:slug  (las oleadas 10/50/100 son de jefe)
ITEMS=(
	"1:01_contaminacion"
	"11:02_basura"
	"21:03_oceanos"
	"31:04_industrial"
	"41:05_lluvia_acida"
	"51:06_electronica"
	"61:07_nuclear"
	"71:08_pesticidas"
	"81:09_deforestacion"
	"91:10_clima"
	"10:11_jefe_excavadora"
	"50:12_jefe_geiser"
)

for it in "${ITEMS[@]}"; do
	oleada="${it%%:*}"
	slug="${it##*:}"
	avi="$OUT/${slug}.avi"
	echo "[trailer_juego] grabando $slug (oleada $oleada)"
	"$GODOT" --path "$PROJ" \
		--write-movie "$avi" \
		--fixed-fps "$FPS" \
		--disable-vsync \
		--quit-after "$FRAMES" \
		"$ESCENA" -- \
		"--captura-oleada=$oleada" \
		"--captura-grabar" >/dev/null 2>&1 || true
	if [ -f "$avi" ]; then echo "  ok  $avi"; else echo "  FALLO $avi"; fi
done

echo "[trailer_juego] Listo → $OUT"