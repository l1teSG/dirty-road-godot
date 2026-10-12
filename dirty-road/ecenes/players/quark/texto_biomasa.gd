extends Label
## Muestra la biomasa acumulada (sin límite). Se actualiza con la señal del manager.

## false: solo el número ("27"). true: "27 / 10" (acumulado / costo del super).
@export var mostrar_costo_super: bool = false
## Si es true, el texto se pone verde cuando alcanza para usar el super.
@export var resaltar_super_listo: bool = false

const COLOR_LISTO := Color(0.4, 1.0, 0.6)
const ESCALA_POP := Vector2(1.3, 1.3)

var _ultimo: int = 0
var _tween: Tween = null


func _ready() -> void:
	pivot_offset = size / 2.0
	_ultimo = BiomasaManager.contador
	_refrescar()
	BiomasaManager.biomasa_incrementada.connect(_on_biomasa_cambiada)


func _on_biomasa_cambiada() -> void:
	var actual: int = BiomasaManager.contador
	_refrescar()
	if actual > _ultimo:
		_pop()
	_ultimo = actual


func _refrescar() -> void:
	var actual: int = BiomasaManager.contador
	if mostrar_costo_super:
		text = "%d / %d" % [actual, BiomasaManager.COSTO_SUPER]
	else:
		text = str(actual)

	if resaltar_super_listo and BiomasaManager.puede_usar_super():
		add_theme_color_override("font_color", COLOR_LISTO)
	else:
		remove_theme_color_override("font_color")


func _pop() -> void:
	pivot_offset = size / 2.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	scale = ESCALA_POP
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
