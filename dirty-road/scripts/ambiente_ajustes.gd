extends WorldEnvironment

## ══════════════════════════════════════════════════════════
##  AMBIENTE · AJUSTES — Brillo, contraste y saturación.
##
##  Se cuelga de un nodo `WorldEnvironment` y aplica los ajustes
##  globales al `Environment` (afecta al render 2D, igual que el glow).
##  Se refresca al cambiar cualquier ajuste.
## ══════════════════════════════════════════════════════════

func _ready() -> void:
	_aplicar()
	if SaveManager != null and SaveManager.has_signal("ajustes_cambiados"):
		SaveManager.ajustes_cambiados.connect(_aplicar)


func _aplicar() -> void:
	if environment == null or SaveManager == null:
		return
	environment.adjustment_enabled = true
	environment.adjustment_brightness = clampf(
		float(SaveManager.get_ajuste("brillo", 1.0)), 0.5, 1.5)
	environment.adjustment_contrast = clampf(
		float(SaveManager.get_ajuste("contraste", 1.0)), 0.5, 1.5)
	environment.adjustment_saturation = clampf(
		float(SaveManager.get_ajuste("saturacion", 1.0)), 0.0, 2.0)
