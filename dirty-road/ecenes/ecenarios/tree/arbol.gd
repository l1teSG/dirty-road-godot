extends Area2D

# ══════════════════════════════════════════════════════════
#  ÁRBOL — objetivo de defensa (grupo 'arbol') y derrota.
#  CONTRATO CON EL SISTEMA NUEVO:
#  • WaveManager y Enemigo.gd lo identifican por el grupo
#    'arbol'; los anti-estructura lo eligen como objetivo.
#  • Recibe daño por el contrato único: recibir_danio(cantidad).
#    Aliases take_hit / recibir_dano para scripts viejos.
#  BALANCE (Etapa 1 — el WaveManager escala a los enemigos,
#  al árbol NO; cifras de enemigo sin escalar):
#  • Vida 150: un microplástico filtrado hace 1/s (armadura) y
#    muere solo por las espinas; un petróleo hace 7/s y aguanta
#    las espinas ~30 s → hay que matarlo a tiros.
#  • Armadura 1: resta plana por golpe (ningún golpe baja de 1).
#    Anti-enjambre: el microplástico pasa de 2 a 1 por roce.
#  • Espinas 2 en radio 36: todo enemigo pegado al tronco
#    recibe contragolpe cuando el árbol es golpeado; un micro
#    (8 HP) cae en ~4 roces. La Nube dispara desde lejos: nunca
#    la punzan (es el castigo por ignorarla: 3 por proyectil).
#  • Jefe (12-19 por embestida): la armadura es marginal a propósito.
#  • Regeneración 1.5 HP/s tras 8 s: recupera ~10-20 HP entre
#    oleadas, nada mientras hay contacto constante.
# ══════════════════════════════════════════════════════════

# Variable global al inicio del script para controlar el tiempo del latido
var tiempo_latido: float = 0.0

## Vida del árbol (condición de derrota). Más alta que la del jugador
## porque varios enemigos pueden golpearlo a la vez.
@export var vida_maxima: int = 150
var vida_actual: float
var esta_destruido: bool = false

# ── Señales para otros sistemas (HUD, enciclopedia, logros, etc.) ──
signal vida_actualizada(vida: float, vida_max: int)
signal arbol_destruido

# ── Defensa ────────────────────────────────────────────
@export_category("Defensa")
## Resta plana a cada golpe recibido (el golpe nunca baja de 1).
## 1 = un microplástico pasa de 2 a 1 por roce contra el tronco.
@export var armadura: float = 1.0
## Savia punzante: al recibir un golpe, todo enemigo pegado al
## tronco recibe este daño de vuelta (Enemigo.gd muestra el
## número flotante). 0 = desactivado.
@export_range(0.0, 50.0) var danio_espinas: float = 2.0
## Radio alrededor del tronco en el que pican las espinas.
@export_range(8.0, 200.0) var radio_espinas: float = 36.0

# ── Regeneración ───────────────────────────────────────
@export_category("Regeneración")
## 1.5 HP/s tras 8 s sin daño: recupera ~10-20 HP entre oleadas.
@export var regeneracion_por_segundo: float = 1.5
@export var retraso_regeneracion: float = 8.0
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

# ── Prioridad de la luz (flash > regeneración > latido) ──
## Segundos restantes de destello por golpe; mientras dura, el
## latido místico no toca la luz.
var _flash_luz_tiempo: float = 0.0
var _tween_flash_luz: Tween = null
## true mientras el pulso de regeneración controla la luz.
var _regen_luz_activa: bool = false


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
			_detener_efecto_regeneracion()
			_regeneracion_visual_activa = false
		return

	# PRIORIDAD DE LA LUZ: flash de golpe > pulso de regeneración > latido.
	# animar_luz_mistica() escribe color/energía/escala cada frame, así que
	# si hay un efecto superior activo hay que pausar el latido o lo tapa
	# en el siguiente frame (el destello rojo y el pulso verde no se veían).
	if _flash_luz_tiempo > 0.0:
		_flash_luz_tiempo -= delta
	if _flash_luz_tiempo <= 0.0 and not _regen_luz_activa:
		animar_luz_mistica(delta)

	if regeneracion_activa:
		var result = RegenerationHelper.update_regeneration(delta, vida_actual, float(vida_maxima), regeneracion_por_segundo, tiempo_sin_recibir_danio, retraso_regeneracion, regeneracion_activa)
		vida_actual = result.life
		tiempo_sin_recibir_danio = result.time_since_damage
		actualizar_barra_vida()

	# Actualizar efecto visual
	_actualizar_efecto_regeneracion(delta)


# ───────────── CONTRATO DE DAÑO CON LA CLASE ENEMIGO ─────────────
## Enemigo.atacar_objetivo() llama recibir_danio(cantidad) sobre lo que
## esté en el grupo 'arbol'. El parámetro es float porque el escalado
## de oleadas del WaveManager puede dejar el daño con decimales.

func recibir_danio(cantidad: float) -> void:
	if esta_destruido:
		return
	# Armadura: resta plana, pero ningún golpe baja de 1 de daño.
	var cantidad_efectiva := maxf(1.0, cantidad - armadura)
	vida_actual = maxf(0.0, vida_actual - cantidad_efectiva)
	tiempo_sin_recibir_danio = 0.0
	actualizar_barra_vida()
	_devolver_espinas()
	reaccionar_visualmente_al_danio()

	if vida_actual <= 0.0:
		destruir_arbol()


## Savia punzante: cuando el árbol recibe un golpe, todo enemigo dentro
## de radio_espinas del tronco recibe danio_espinas. Funciona por radio,
## así que NO hay que cambiar Enemigo.gd ni el contrato de 1 argumento.
## Los proyectiles de la Nube golpean desde lejos: nunca sufren espinas.
func _devolver_espinas() -> void:
	if danio_espinas <= 0.0 or esta_destruido:
		return
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		var e := enemigo as Node2D
		if e == null or not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) <= radio_espinas:
			if e.has_method("recibir_danio"):
				e.recibir_danio(danio_espinas)
			elif e.has_method("take_damage"):
				e.take_damage(roundi(danio_espinas))


## Alias de compatibilidad: el proyectil viejo del jugador y algunos
## comportamientos usan la convención take_hit / recibir_dano.
func take_hit(cantidad: float) -> void:
	recibir_danio(cantidad)


func recibir_dano(cantidad: float) -> void:
	recibir_danio(cantidad)


func actualizar_barra_vida() -> void:
	var barra = $BarraVida as ProgressBar
	if barra != null:
		barra.max_value = vida_maxima
		barra.value = vida_actual
	vida_actualizada.emit(vida_actual, vida_maxima)


# Efecto de destello rojo en la luz al recibir un golpe
func reaccionar_visualmente_al_danio() -> void:
	var luz = $LuzArbol as PointLight2D
	if luz == null:
		return

	# Si un destello anterior sigue animando la luz, matarlo: dos tweens
	# peleándose por color/energía hacían parpadear el destello.
	if _tween_flash_luz != null and _tween_flash_luz.is_valid():
		_tween_flash_luz.kill()
	# Duración total del destello (0.08 de estallido + 0.25 de retorno);
	# mientras corre, el latido místico pausa (ver _process).
	_flash_luz_tiempo = 0.35

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
	_tween_flash_luz = tween
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
	# Guardia anti-doble-muerte: varios enemigos pueden golpear en el
	# mismo frame; solo la primera llamada ejecuta la secuencia.
	if esta_destruido:
		return
	esta_destruido = true

	# Deja de ser objetivo: los enemigos que consultan el grupo 'arbol'
	# dejan de encontrarlo en la próxima búsqueda.
	remove_from_group("arbol")
	arbol_destruido.emit()

	# Desactivar colisiones del árbol
	monitoring = false
	monitorable = false
	if has_node("StaticBody2D"):
		var static_body = $StaticBody2D as StaticBody2D
		static_body.collision_layer = 0
		static_body.collision_mask = 0

	# Desactivar al jugador instantáneamente. Grupo 'jugador' (el que usa
	# WaveManager y la clase Enemigo), con fallback al viejo 'player'.
	var player = get_tree().get_first_node_in_group("jugador")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
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

	# Cierra la corrida educativa y encola el mensaje de muerte: el popup
	# vive en el Autoload, así que sobrevive al cambio de escena y puede
	# aparecer sobre la pantalla de game over.
	var edu = get_node_or_null("/root/EducationManager")
	if edu != null:
		edu.stop_run()
		edu.on_player_died()

	# Cambiar a la escena de muerte
	get_tree().change_scene_to_file("res://ui/dead/dead.tscn")
	

func _ready() -> void:
	vida_actual = float(vida_maxima)
	actualizar_barra_vida()

	# Añadir al grupo "arbol" para que WaveManager y los anti-estructura
	# lo identifiquen como objetivo (única fuente de verdad: los grupos).
	add_to_group("arbol")

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

	# Caja de emisión pequeña centrada en el origen
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(4.0, 4.0, 0.0)

	particle.process_material = material
	add_child(particle)
	_particulas_regeneracion = particle


# ── Efecto visual de regeneración ──────────────────────

func _actualizar_efecto_regeneracion(_delta: float) -> void:
	# Determina si el árbol debería estar regenerando visualmente
	var regenerando: bool = regeneracion_activa and tiempo_sin_recibir_danio >= retraso_regeneracion and vida_actual < vida_maxima

	if regenerando == _regeneracion_visual_activa:
		return  # No hay cambio de estado

	if regenerando:
		# Inicio efecto regeneración
		_iniciar_efecto_regeneracion()
	else:
		# Fin efecto regeneración
		_detener_efecto_regeneracion()

	_regeneracion_visual_activa = regenerando


func _iniciar_efecto_regeneracion() -> void:
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

	# --- Luz : pulso suave de energía y color ---
	var luz = $LuzArbol as PointLight2D
	if luz != null:
		# El pulso de regeneración toma el control de la luz: el latido
		# místico pausa hasta que termine (ver _process).
		_regen_luz_activa = true
		if _tween_luz_regeneracion != null and _tween_luz_regeneracion.is_valid():
			_tween_luz_regeneracion.kill()
		_tween_luz_regeneracion = create_tween().set_loops()
		# Subir energía y virar a verde
		_tween_luz_regeneracion.tween_property(luz, "energy", _luz_original_energy * 1.6, 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tween_luz_regeneracion.parallel().tween_property(luz, "color", Color(0.2, 1.0, 0.3, 1.0), 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		# Bajar energía y volver a color original
		_tween_luz_regeneracion.tween_property(luz, "energy", _luz_original_energy, 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tween_luz_regeneracion.parallel().tween_property(luz, "color", _luz_original_color, 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _detener_efecto_regeneracion() -> void:
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
		_regen_luz_activa = false
		if _tween_luz_regeneracion != null and _tween_luz_regeneracion.is_valid():
			_tween_luz_regeneracion.kill()
		luz.color = _luz_original_color
		luz.energy = _luz_original_energy
