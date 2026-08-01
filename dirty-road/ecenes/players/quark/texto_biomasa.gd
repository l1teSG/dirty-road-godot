extends Label

const MAX_BIOMASA := 10
var biomasa_actual: int = 0

func _ready() -> void:
	text = "%d / %d" % [biomasa_actual, MAX_BIOMASA]
	BiomasaManager.biomasa_incrementada.connect(_actualizar_texto)

func _actualizar_texto() -> void:
	text = "%d / %d" % [BiomasaManager.contador, MAX_BIOMASA]
