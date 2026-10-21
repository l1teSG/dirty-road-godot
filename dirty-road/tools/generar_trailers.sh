#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════
#  Genera TODOS los trailers del modo trailer.
#
#  Uso:  tools/generar_trailers.sh [filtro]
#    sin filtro  → genera los 21 (general + 10 etapas + 10 jefes)
#    filtro      → solo los guiones cuyo nombre contiene el texto
#                  ej.: tools/generar_trailers.sh jefe
#
#  Salida: dirty-road/capturas/trailers/*.mp4
# ══════════════════════════════════════════════════════════
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
FILTRO="${1:-}"

# Primero (re)genera los guiones a partir de las escenas reales.
python3 "$AQUI/generar_guiones_trailers.py" >/dev/null

shopt -s nullglob
for guion in "$AQUI"/trailers/*.json; do
	nombre="$(basename "$guion" .json)"
	[[ -z "$FILTRO" || "$nombre" == *"$FILTRO"* ]] || continue
	"$AQUI/grabar_trailer.sh" "$guion" || echo "[trailers] fallo en $nombre"
done

echo "[trailers] terminado. Revisa dirty-road/capturas/trailers/"
