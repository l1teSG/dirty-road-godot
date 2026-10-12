class_name MejorasConfig
extends Resource

## ══════════════════════════════════════════════════════════
##  Efectos de las cartas (editable en el editor).
##  Formato: id_carta -> Array de [ruta_stat, operacion, valor]
##    op "pct"  -> stat *= (1 + valor)
##    op "add"  -> stat += valor
##    op "mult" -> stat *= valor
## ══════════════════════════════════════════════════════════

@export var efectos: Dictionary = {}
