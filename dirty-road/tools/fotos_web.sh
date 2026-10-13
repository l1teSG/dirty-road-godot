#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════
#  Fotos de las 10 etapas (+ jefes) para la web.
#  Fuerza cada etapa con los overrides de debug del WaveManager y
#  captura un PNG sin HUD (modo foto) → web/src/media/juego/.
#
#  Uso:  tools/fotos_web.sh [carpeta_salida]
#  Requiere display/GPU (no headless).
# ══════════════════════════════════════════════════════════
set -euo pipefail

GODOT="${GODOT:-/usr/bin/godot}"
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$PROJ/../web/src/media/juego}"
ESCENA="res://demo/level 1/niviel1.tscn"
ESPERA="${ESPERA:-6}"
RES="${RES:-1920x1080}"

mkdir -p "$OUT/etapas" "$OUT/enemigos"

foto() { # oleada  archivo
	local oleada="$1" archivo="$2"
	"$GODOT" --path "$PROJ" --resolution "$RES" "$ESCENA" -- \
		"--captura-oleada=$oleada" \
		"--captura-espera=$ESPERA" \
		"--captura-salida=$archivo" \
		"--captura-salir" >/dev/null 2>&1 || true
	if [ -f "$archivo" ]; then echo "  ok  $archivo"; else echo "  FALLO $archivo"; fi
}

echo "[fotos] 10 etapas → $OUT/etapas"
for e in $(seq 1 10); do
	oleada=$(( (e - 1) * 10 + 1 ))
	foto "$oleada" "$(printf '%s/etapas/etapa_%02d.png' "$OUT" "$e")"
done

echo "[fotos] jefes → $OUT/enemigos"
foto "10"  "$OUT/enemigos/boss_01_excavadora.png"
foto "50"  "$OUT/enemigos/boss_05_geiser.png"
foto "100" "$OUT/enemigos/boss_10_calentamiento.png"

echo "[fotos] Listo → $OUT"