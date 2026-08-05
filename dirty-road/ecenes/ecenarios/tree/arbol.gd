extends Area2D

# Variable global al inicio del script para controlar el tiempo del latido
var tiempo_latido: float = 0.0
@export var vida_maxima: int = 100
var vida_actual: float
var esta_destruido: bool = false

# ── Regeneración ───────────────────────────────────────
@export_category("Regeneración")
@export var regeneracion_por_segundo: float = 1.0
@export var retraso_regeneracion: float = 10.0
@export var regeneracion_activa: bool = true

var tiempo_sin_recibir_danio: float = 0.0

# ── Efecto visual regeneración ────────────────────────
var _regeneracion_visual_activa: bool = false
var _tween_barra_regeneracion: Tween = null
var _tween_barra_color_regeneracion: Tween = null
var _tween_luz_regeneracion: Tween = null
var _particulas_regeneracion: GPUParticles2D = null

var _barra_modulate_original: Color
var _luz_original_color: Color
var _luz_original_energy: float


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
		# Si el árbol está destruido, detener el efecto visual de regeneración
		if _regeneracion_visual_activa:
			_detener_efecto_regeneracion_visual()
			_regeneracion_visual_activa = false
		return
	animar_luz_mistica(delta)

	if regeneracion_activa:
		var result = RegenerationHelper.update_regeneration(delta, vida_actual, float(vida_maxima), regeneracion_por_segundo, tiempo_sin_recibir_danio, retraso_regeneracion, regeneracion_activa)
		vida_actual = result.life
		tiempo_sin_recibir_danio = result.time_since_damage
		actualizar_barra_vida()

	# Actualizar efecto visual
	_actualizar_efecto_regeneracion_visual()


func recibir_danio(cantidad: int) -> void:
	vida_actual = max(0.0, vida_actual - cantidad)
	tiempo_sin_recibir_danio = 0.0
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

	# Guardar valores originales para el efecto visual de regeneración
	var barra = $BarraVida as ProgressBar
	if barra != null:
		_barra_modulate_original = barra.modulate

	var luz = $LuzArbol as PointLight2D
	if luz != null:
		_luz_original_color = luz.color
		_luz_original_energy = luz.energy

	_crear_particulas_regeneracion()


func _crear_particulas_regeneracion() -> void:
	# Crea un GPUParticles2D para las partículas verdes de regeneración
	var particle := GPUParticles2D.new()
	particle.name = "ParticulasRegeneracion"
	particle.amount = 10
	particle.lifetime = 1.0
	particle.one_shot = false
	particle.emitting = false
	particle.local_coords = true

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.gravity = Vector3(0, 0, 0)
	material.initial_velocity_min = 15.0
	material.initial_velocity_max = 30.0
	material.lifetime_randomness = 0.2
	material.scale_min = 0.3
	material.scale_max = 0.6
	material.color = Color(0.2, 1.0, 0.3, 0.8)

	# Curva de alpha para que desaparezcan gradualmente
	var alpha_curve := Gradient.new()
	alpha_curve.add_point(0.0, 1.0)
	alpha_curve.add_point(1.0, 0.0)
	material.alpha_curve = alpha_curve

	# Caja de emisión pequeña centrada en el origen
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(4.0, 4.0, 0.0)

	particle.process_material = material
	add_child(particle)
	_particulas_regeneracion = particle


# ── Efecto visual de regeneración ──────────────────────

func _actualizar_efecto_regeneracion_visual() -> void:
	# Determina si el árbol debería estar regenerando visualmente
	var regenerando: bool = regeneracion_activa and tiempo_sin_recibir_danio >= retraso_regeneracion and vida_actual < vida_maxima

	if regenerando == _regeneracion_visual_activa:
		return  # No hay cambio de estado

	if regenerando:
		# Inicio efecto regeneración
		_iniciar_efecto_regeneracion_visual()
	else:
		# Fin efecto regeneración
		_detener_efecto_regeneracion_visual()

	_regeneracion_visual_activa = regenerando


func _iniciar_efecto_regeneracion_visual() -> void:
	# Inicio efecto regeneración: barra de vida, partículas y luz

	var barra = $BarraVida as ProgressBar

	# --- Barra de vida: pulso de escala y cambio de color ---
	if barra != null:
		# Pulso de escala (loop infinito)
		if _tween_barra_regeneracion != null and _tween_barra_regeneracion.is_valid():
			_tween_barra_regeneracion.kill()
		_tween_barra_regeneracion = create_tween().set_loops()
		_tween_barra_regeneracion.tween_property(barra, "scale", Vector2(1.08, 1.08), 0.6)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tween_barra_regeneracion.tween_property(barra, "scale", Vector2(1.0, 1.0), 0.6)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

		# Transición de color a verde brillante (una sola vez)
		if _tween_barra_color_regeneracion != null and _tween_barra_color_regeneracion.is_valid():
			_tween_barra_color_regeneracion.kill()
		_tween_barra_color_regeneracion = create_tween()
		_tween_barra_color_regeneracion.tween_property(barra, "modulate", Color(0.2, 1.0, 0.3, 1.0), 0.3)\
			.set_ease(Tween.EASE_IN_OUT)

	# --- Partículas de regeneración ---
	if _particulas_regeneracion != null:
		_particulas_regeneracion.emitting = true

	# --- Luz : cambiar suavemente a verde y aumentar energía ---
	var luz = $LuzArbol as PointLight2D
	if luz != null:
		if _tween_luz_regeneracion != null and _tween_luz_regeneracion.is_valid():
			_tween_luz_regeneracion.kill()
		_tween_luz_regeneracion = create_tween()
		_tween_luz_regeneracion.tween_property(luz, "color", Color(0.2, 1.0, 0.3, 1.0), 0.5)\
			.set_ease(Tween.EASE_IN_OUT)
		_tween_luz_regeneracion.parallel().tween_property(luz, "energy", _luz_original_energy * 1.4, 0.5)\
			.set_ease(Tween.EASE_IN_OUT)


func _detener_efecto_regeneracion_visual() -> void:
	# Fin efecto regeneración: restaurar todo a su estado original

	var barra = $BarraVida as ProgressBar

	# --- Barra de vida: restaurar escala y color ---
	if _tween_barra_regeneracion != null and _tween_barra_regeneracion.is_valid():
		_tween_barra_regeneracion.kill()
	if _tween_barra_color_regeneracion != null and _tween_barra_color_regeneracion.is_valid():
		_tween_barra_color_regeneracion.kill()

	if barra != null:
		barra.scale = Vector2.ONE
		barra.modulate = _barra_modulate_original

	# --- Partículas: detener emisión ---
	if _particulas_regeneracion != null:
		_particulas_regeneracion.emitting = false

	# --- Luz: restaurar color y energía originales ---
	var luz = $LuzArbol as PointLight2D
	if luz != null:
		if _tween_luz_regeneracion != null and _tween_luz_regeneracion.is_valid():
			_tween_luz_regeneracion.kill()
		luz.color = _luz_original_color
		luz.energy = _luz_original_energy
