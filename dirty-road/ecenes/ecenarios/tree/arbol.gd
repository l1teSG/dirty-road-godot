extends Area2D

# Variable global al inicio del script para controlar el tiempo del latido
var tiempo_latido: float = 0.0
@export var vida_maxima: int = 100
var vida_actual: float
var esta_destruido: bool = false

# ── Regeneración ───────────────────────────────────────
@export_category("Regeneración")
@export var regeneracion_por_segundo: float = 1.0
@export var tiempo_sin_recibir_danio: float = 10.0
@export var permitir_regeneracion: bool = true

var _tiempo_ultimo_danio: float = 0.0

# -------------------------------------------------------------------
# FUNCIÓN VISUAL: LATIDO Y CHISPEO DE LUZ MÍSTICA DEL ÁRBOL
# -------------------------------------------------------------------
func animar_luz_mistica(delta: float) -> void:
	# Reference directa y segura al nodo de luz del árbol
	var luz = $LuzArbol as PointLight2D
	if luz == null:
		return
		
	tiempo_latido += delta
	
	# 1. RESPIRACIÓN (Expansión y contracción suave de la sombra)
	var onda_respiracion: float = sin(tiempo_latido * 2.5) # Velocidad de respiración
	var escala_dinamica: float = 3.5 + (onda_respiracion * 0.5) # Modifica el tamaño entre 3.0 y 4.0
	luz.texture_scale = escala_dinamica
	
	# 2. CHISPEO / PARPADEO ORGÁNICO (Micro-destellos de energía viva)
	var chispeo_aleatorio: float = randf_range(-0.18, 0.18)
	var energia_base: float = 1.6 + (onda_respiracion * 0.4) + chispeo_aleatorio
	luz.energy = max(0.8, energia_base)
	
	# 3. TRANSICIÓN CROMÁTICA (Oscila entre Verde Esmeralda y Cian Místico)
	var factor_color: float = (onda_respiracion + 1.0) / 2.0 # Transforma rango [-1,1] a [0,1]
	var color_verde := Color("#00FF88")
	var color_cian := Color("#00F0FF")
	luz.color = color_verde.lerp(color_cian, factor_color)
	
func _process(delta: float) -> void:
	if esta_destruido:
		return
	animar_luz_mistica(delta)

	if permitir_regeneracion:
		var result = RegenerationHelper.update_regeneration(delta, vida_actual, float(vida_maxima), regeneracion_por_segundo, _tiempo_ultimo_danio, tiempo_sin_recibir_danio, permitir_regeneracion)
		vida_actual = result.life
		_tiempo_ultimo_danio = result.time_since_damage
		actualizar_barra_vida()

func recibir_danio(cantidad: int) -> void:
	vida_actual = max(0.0, vida_actual - cantidad)
	_tiempo_ultimo_danio = 0.0
	actualizar_barra_vida()
	reaccionar_visualmente_al_danio()

	if vida_actual <= 0:
		destruir_arbol()

func actualizar_barra_vida() -> void:
	var barra = $BarraVida as ProgressBar
	if barra != null:
		barra.max_value = vida_maxima
		barra.value = vida_actual

# Efecto de destello rojo en la luz al recibir un golpe
func reaccionar_visualmente_al_danio() -> void:
	var luz = $LuzArbol as PointLight2D
	if luz == null:
		return

	# Guardar valores originales antes de la alerta
	var color_original = luz.color
	var energia_original = luz.energy
	var escala_original = luz.texture_scale

	# Estallido inmediato de alerta intensa
	luz.color = Color("#FF0055")
	luz.energy = 12.0
	luz.texture_scale = 14.0

	# Sacudida rápida del tronco (shake) para dar sensación de impacto físico
	var pos_original = position
	var shake_offset = Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	var shake_tween = create_tween()
	shake_tween.tween_property(self, "position", pos_original + shake_offset, 0.05)
	shake_tween.tween_property(self, "position", pos_original, 0.1).set_ease(Tween.EASE_OUT)

	# Animación de la luz: overshoot (valores aún más altos) y luego vuelta suave con rebote
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(luz, "color", Color("#FF0088"), 0.08)
	tween.tween_property(luz, "energy", 16.0, 0.08)
	tween.tween_property(luz, "texture_scale", 18.0, 0.08)

	# Retorno a los valores originales con un efecto de rebote (BACK) para que
	# la transición se sienta viva y orgánica
	tween.chain().set_parallel(true)
	tween.tween_property(luz, "color", color_original, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(luz, "energy", energia_original, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(luz, "texture_scale", escala_original, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func destruir_arbol() -> void:
	esta_destruido = true

	# Desactivar colisiones del árbol
	monitoring = false
	monitorable = false
	if has_node("StaticBody2D"):
		var static_body = $StaticBody2D as StaticBody2D
		static_body.collision_layer = 0
		static_body.collision_mask = 0

	# Desactivar al jugador instantáneamente
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.hide()
		player.process_mode = Node.PROCESS_MODE_DISABLED

	# ── Fase 1: Muerte agónica del árbol (2.0 segundos) ──────────────
	var luz = $LuzArbol as PointLight2D
	if luz != null:
		# Animación de color y escala
		var tween_agonia = create_tween()
		tween_agonia.set_parallel(true)
		tween_agonia.tween_property(luz, "color", Color("#FF0022"), 2.0).set_ease(Tween.EASE_IN)
		tween_agonia.tween_property(luz, "texture_scale", 1.0, 2.0).set_ease(Tween.EASE_IN)

		# Oscilación salvaje de energía
		var tween_energia = create_tween()
		tween_energia.set_parallel(false)
		tween_energia.tween_property(luz, "energy", 8.0, 0.5)
		tween_energia.tween_property(luz, "energy", 0.5, 0.5)
		tween_energia.tween_property(luz, "energy", 8.0, 0.5)
		tween_energia.tween_property(luz, "energy", 0.5, 0.5)

	# Sacudida violenta del tronco (shake continuo)
	var pos_original = position
	var shake_tween = create_tween()
	shake_tween.set_parallel(false)
	for i in range(10):
		var offset = Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		shake_tween.tween_property(self, "position", pos_original + offset, 0.1)
		shake_tween.tween_property(self, "position", pos_original, 0.1)
	shake_tween.tween_callback(func(): position = pos_original)

	# Esperar a que termine la fase agónica (2.0 segundos)
	await shake_tween.finished

	# ── Fase 2: Cobertura de pantalla completa (2.5 segundos) ────────
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128
	get_tree().current_scene.add_child(canvas_layer)

	var color_rect = ColorRect.new()
	color_rect.color = Color.RED
	color_rect.modulate = Color(1, 1, 1, 0)
	color_rect.anchors_preset = Control.PRESET_FULL_RECT
	canvas_layer.add_child(color_rect)

	var tween_pantalla = create_tween()
	tween_pantalla.set_parallel(true)
	tween_pantalla.tween_property(color_rect, "modulate:a", 1.0, 2.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween_pantalla.tween_property(color_rect, "color", Color.BLACK, 2.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween_pantalla.finished

	# Limpiar overlay
	canvas_layer.queue_free()

	# Cambiar a la escena de muerte
	get_tree().change_scene_to_file("res://ui/dead/dead.tscn")
	
func _ready() -> void:
	vida_actual = float(vida_maxima)
	actualizar_barra_vida()
