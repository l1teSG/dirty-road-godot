extends Node2D

@onready var fondo_negro: ColorRect = $CanvasLayer/ColorRect
@onready var texto_horda: Label = $CanvasLayer/TextoHorda

var horda_actual: int = 1

const DURACION_FADE_ENTRADA := 1.0
const ESPERA_ANTES_DE_TEXTO := 1.2
const DURACION_ENTRADA_TEXTO := 0.8
const TIEMPO_VISIBLE_TEXTO := 1.6
const DURACION_SALIDA_TEXTO := 1.0
const DESPLAZAMIENTO_TEXTO := 20.0


func _ready() -> void:
	horda_actual = SaveManager.get_horda() if SaveManager else 1

	_iniciar_transicion_entrada()
	await _preparar_texto_horda()


# ── Transición de entrada al nivel (fade desde negro) ──────────────

func _iniciar_transicion_entrada() -> void:
	if fondo_negro == null:
		push_warning("Nivel: no se encontró el ColorRect de transición")
		_secuencia_texto_horda()
		return

	fondo_negro.color.a = 1.0
	fondo_negro.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween = create_tween()
	tween.tween_property(fondo_negro, "color:a", 0.0, DURACION_FADE_ENTRADA)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		fondo_negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
	tween.tween_interval(ESPERA_ANTES_DE_TEXTO)
	tween.tween_callback(_secuencia_texto_horda)


# ── Texto "HORDA X" ──────────────────────────────────────────────────

func _preparar_texto_horda() -> void:
	if texto_horda == null:
		push_warning("Nivel: no se encontró el Label de horda")
		return

	texto_horda.text = "HORDA %d" % horda_actual

	# esperamos un frame para que el Label recalcule su tamaño real
	# con el nuevo texto antes de fijar el pivote de escala
	await get_tree().process_frame

	texto_horda.pivot_offset = texto_horda.size / 2.0
	texto_horda.modulate.a = 0.0
	texto_horda.scale = Vector2(0.92, 0.92)

	# guarda la posición base para poder animar el desplazamiento vertical
	texto_horda.set_meta("pos_base", texto_horda.position)
	texto_horda.position.y -= DESPLAZAMIENTO_TEXTO


func _secuencia_texto_horda() -> void:
	if texto_horda == null:
		return

	var pos_final = texto_horda.get_meta("pos_base", texto_horda.position)

	var tween = create_tween()

	# entrada: fade + escala desde el centro + deslizamiento suave hacia abajo
	tween.set_parallel(true)
	tween.tween_property(texto_horda, "modulate:a", 1.0, DURACION_ENTRADA_TEXTO)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(texto_horda, "scale", Vector2.ONE, DURACION_ENTRADA_TEXTO)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(texto_horda, "position", pos_final, DURACION_ENTRADA_TEXTO)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# se mantiene visible
	tween.chain().tween_interval(TIEMPO_VISIBLE_TEXTO)

	# salida: fade lento + leve deriva hacia arriba
	tween.chain().set_parallel(true)
	tween.tween_property(texto_horda, "modulate:a", 0.0, DURACION_SALIDA_TEXTO)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(texto_horda, "position", pos_final + Vector2(0, -15.0), DURACION_SALIDA_TEXTO)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


# ── Llamar esto cuando el jugador avance de horda ───────────────────

func avanzar_horda() -> void:
	horda_actual += 1

	if SaveManager:
		SaveManager.set_horda(horda_actual)
		SaveManager.guardar_partida()

	await _preparar_texto_horda()
	_secuencia_texto_horda()
