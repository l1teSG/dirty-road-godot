extends Node2D

@onready var fondo_negro: ColorRect = $CanvasLayer/ColorRect
@onready var texto_horda: Label = $CanvasLayer/TextoHorda

var horda_actual: int = 1

const DURACION_FADE_ENTRADA := 1.0
const ESPERA_ANTES_DE_TEXTO := 0.5
const DURACION_ENTRADA_TEXTO := 0.8
const TIEMPO_VISIBLE_TEXTO := 1.6
const DURACION_SALIDA_TEXTO := 1.0
const DESPLAZAMIENTO_TEXTO := 20.0

var tween_actual: Tween


func _ready() -> void:
	horda_actual = SaveManager.get_horda() if SaveManager else 1
	_iniciar_transicion_entrada()

	# Conectar señales con WaveManager
	await get_tree().process_frame
	var wave_manager = get_tree().get_first_node_in_group("wave_manager") as WaveManager
	if wave_manager != null:
		wave_manager.oleada_iniciada.connect(_on_oleada_iniciada)
		wave_manager.descanso_iniciado.connect(_on_descanso_iniciado)


# ── Transición de entrada al nivel (fade desde negro) ──────────────

func _iniciar_transicion_entrada() -> void:
	if fondo_negro == null:
		push_warning("Nivel: no se encontró el ColorRect de transición")
		mostrar_mensaje("HORDA %d" % horda_actual)
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
	tween.tween_callback(func():
		mostrar_mensaje("HORDA %d" % horda_actual)
	)


# ── Handlers de Señales de WaveManager ────────────────────────────────

func _on_oleada_iniciada(num_oleada: int) -> void:
	horda_actual = num_oleada
	mostrar_mensaje("HORDA %d" % horda_actual)


func _on_descanso_iniciado(_tiempo_total: float) -> void:
	mostrar_mensaje("¡OLEADA COMPLETADA!")


# ── Lógica de Animación Unificada ────────────────────────────────────

func mostrar_mensaje(texto: String) -> void:
	if texto_horda == null:
		return

	# Cancelar animación previa si existía
	if tween_actual != null and tween_actual.is_running():
		tween_actual.kill()

	texto_horda.text = texto
	
	# Configurar anclajes al centro de la pantalla
	texto_horda.anchors_preset = Control.PRESET_CENTER
	texto_horda.grow_horizontal = Control.GROW_DIRECTION_BOTH
	texto_horda.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	await get_tree().process_frame

	# Fijar pivote en el centro exacto del Label
	texto_horda.pivot_offset = texto_horda.size / 2.0
	
	# Estado inicial de la animación
	texto_horda.modulate.a = 0.0
	texto_horda.scale = Vector2(0.9, 0.9)
	
	# Posición centrada base
	var pos_centro: Vector2 = (get_viewport_rect().size / 2.0) - (texto_horda.size / 2.0)
	texto_horda.position = pos_centro - Vector2(0, DESPLAZAMIENTO_TEXTO)

	# Secuencia de animación en pantalla
	tween_actual = create_tween()

	# Entrada: Fade in + Zoom + Desplazamiento al centro exacto
	tween_actual.set_parallel(true)
	tween_actual.tween_property(texto_horda, "modulate:a", 1.0, DURACION_ENTRADA_TEXTO)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_actual.tween_property(texto_horda, "scale", Vector2.ONE, DURACION_ENTRADA_TEXTO)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_actual.tween_property(texto_horda, "position", pos_centro, DURACION_ENTRADA_TEXTO)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Mantener visible
	tween_actual.chain().tween_interval(TIEMPO_VISIBLE_TEXTO)

	# Salida: Fade out + Flotación leve hacia arriba
	tween_actual.chain().set_parallel(true)
	tween_actual.tween_property(texto_horda, "modulate:a", 0.0, DURACION_SALIDA_TEXTO)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween_actual.tween_property(texto_horda, "position", pos_centro + Vector2(0, -15.0), DURACION_SALIDA_TEXTO)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
