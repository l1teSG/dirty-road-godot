#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════
#  Genera las capturas de pantalla para el MANUAL y la
#  PRESENTACIÓN usando el Movie Maker de Godot (resolución del
#  proyecto, 1536×864) y el MODO CAPTURA.
#
#  Salida: dirty-road/capturas/docs/*.png
#
#  Uso:  tools/generar_capturas_docs.sh [escena_key]
#    sin argumento  → genera TODAS
#    escena_key     → solo una: intro | menu | slots | ajustes |
#                     dead | hud | jefe | cartas
#
#  Requiere display/GPU (no headless) y ffmpeg.
# ══════════════════════════════════════════════════════════
set -euo pipefail

GODOT="${GODOT:-/usr/bin/godot}"
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$PROJ/capturas/docs"
TMP="$OUT/.tmp"
FPS="${FPS:-30}"
NIVEL="res://demo/level 1/niviel1.tscn"
ONLY="${1:-}"

command -v ffmpeg >/dev/null || { echo "Falta ffmpeg"; exit 1; }
mkdir -p "$OUT" "$TMP"

# graba <clave> <frames> <escena> [args...]
# Graba con Movie Maker y extrae el último fotograma como PNG.
grabar() {
	local clave="$1"; shift
	local frames="$1"; shift
	local escena="$1"; shift
	[[ -z "$ONLY" || "$ONLY" == "$clave" ]] || return 0
	local avi="$TMP/$clave.avi"
	echo "[capturas] $clave → $OUT/$clave.png ($frames frames)"
	cd "$PROJ"
	"$GODOT" --path "$PROJ" \
		--write-movie "$avi" \
		--fixed-fps "$FPS" \
		--disable-vsync \
		--quit-after "$frames" \
		"$escena" "$@" >/dev/null 2>&1 || true
	ffmpeg -y -sseof -0.2 -i "$avi" -frames:v 1 "$OUT/$clave.png" >/dev/null 2>&1
	rm -f "$avi"
}

seg() { echo $(( $1 * FPS )); }

grabar intro   "$(seg 3)"  "res://ui/intro/intro.tscn"
grabar menu    "$(seg 4)"  "res://ui/main/main.tscn"
grabar slots   "$(seg 3)"  "res://ui/slots/slots.tscn"
grabar ajustes "$(seg 3)"  "res://ui/ajustes/ajustes.tscn"
grabar dead    "$(seg 3)"  "res://ui/dead/dead.tscn"
grabar hud     "$(seg 14)" "$NIVEL" -- --mc-oleada=3
grabar jefe    "$(seg 20)" "$NIVEL" -- --mc-oleada=10
grabar cartas  "$(seg 14)" "$NIVEL" -- --mc-cartas

echo "[capturas] Listo. PNGs en $OUT"
