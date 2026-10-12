#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════
#  Regenera los enemigos (etapas 2..10) y las EtapaConfig de forma SEGURA:
#   1) genera escenas/tres con generar_enemigos.gd
#   2) restaura los `uid` desde git HEAD (el generador los pierde)
#   3) verifica que todas las escenas instancian
#  Uso: tools/regenerar.sh
# ══════════════════════════════════════════════════════════
set -euo pipefail

GODOT="${GODOT:-/usr/bin/godot}"
PROJ="$(cd "$(dirname "$0")/.." && pwd)"

echo "[regenerar] 1/3 generando enemigos…"
"$GODOT" --path "$PROJ" --headless --script res://tools/generar_enemigos.gd \
	| grep -E "\[GEN\] listo" || true

echo "[regenerar] 2/3 restaurando UIDs desde HEAD…"
python3 "$PROJ/tools/restaurar_uids.py"

echo "[regenerar] 3/3 verificando…"
"$GODOT" --path "$PROJ" --headless --script res://tools/verificar_enemigos.gd \
	| grep -E "\[VERIF\]" || true

echo "[regenerar] Listo. Revisa 'git diff' antes de commitear."