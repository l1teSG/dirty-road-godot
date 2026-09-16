extends Player

# ── Referencias a nodos ──────────────────────────────
@onready var rangeArea = $Area2D/range
@onready var aim: Node2D = $aim
@onready var nucleo: Polygon2D = $Nucleo
@onready var cuerpo: Polygon2D = $body
@onready var body_interior: Polygon2D = $body/bodyInterior
@onready var luz_base: PointLight2D = $LuzBase
@onready var luz_punta: PointLight2D = $LuzPunta
@onready var sombra: Polygon2D = $sombra
@onready var colision: CollisionShape2D = $Collision
@onready var barra_vida: ProgressBar = $ui/margenUi/ContenedorVertical/FilaVida/BarraVida
@onready var contador_respawn: Label = $ui/ContadorRespawn
@onready var ui_contenedor: Node = $ui/margenUi
@onready var contendor_controles: CanvasLayer = $controls

# NOTA: ajusta este path al nombre real de tu nodo Timer de disparo
@onready var timer_disparo: Timer = $Timer

# ── Combate / disparo ─────────────────────────────────
var proyectil: PackedScene = preload("res://ecenes/players/projectile/quark/playerProyectil.tscn")
var power: String = 'basic'
var onFire: bool = false
var enemi: Node2D = null
var enemigos_en_rango: Array[Node2D] = []

@export_category("Cadencia de Disparo")
@export var cadencia_basic: float = 0.6

# ── Movimiento ─────────────────────────────────────────
@export_category("Movimiento")
@export var aceleracion: float = 1200.0
@export var friccion: float = 1400.0

@export_category("Dash")
@export var velocidad_dash: float = 600.0
@export var duracion_dash: float = 0.15
@export var cooldown_dash: float = 0.8

var _en_dash: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direccion: Vector2 = Vector2.RIGHT

# ── Super: Lluvia de Meteoritos ────────────────────────
@export_category("Super - Lluvia de Meteoritos")
@export var danio_meteorito: int = 40
@export var radio_impacto_meteorito: float = 90.0
@export var tiempo_advertencia_meteorito: float = 0.6
## Pequeño retraso entre la caída de cada meteorito, para que no impacten
## todos exactamente en el mismo frame.
@export var retraso_entre_meteoritos: float = 0.08

# ── Animación ──────────────────────────────────────────
var tiempo_caminata: float = 0.0
var tiempo_pulso: float = 0.0

# ── Vida / respawn ─────────────────────────────────────
@export var vida_maxima: int = 100
@export var respawn_manager: Node

@export_category("Combate")
@export var disparoON: bool = true

signal died
var _muerto: bool = false

# ── Feedback visual de golpe ───────────────────────────
@export_category("Feedback de Daño")
@export var color_flash_golpe: Color = Color(4.0, 1.0, 1.0, 1.0)
@export var duracion_flash_golpe: float = 0.12

var _color_original_cuerpo: Color = Color.WHITE
var _color_original_nucleo: Color = Color.WHITE
var _flash_tween: Tween = null

# ── Regeneración ───────────────────────────────────────
@export_category("Regeneración")
@export var regeneracion_por_segundo: float = 2.0
@export var retraso_regeneracion: float = 5.0
@export var regeneracion_activa: bool = true

var tiempo_sin_recibir_danio: float = 0.0

# ── Efecto visual regeneración ────────────────────────
var _regeneracion_visual_activa: bool = false
var _tween_barra_regeneracion: Tween = null
var _tween_barra_color_regeneracion: Tween = null
var _tween_luz_base_regeneracion: Tween = null
var _tween_luz_punta_regeneracion: Tween = null
var _particulas_regeneracion: GPUParticles2D = null

var _barra_modulate_original: Color
var _luz_base_original_color: Color
var _luz_base_original_energy: float
var _luz_punta_original_color: Color
var _luz_punta_original_energy: float

# ── Variables para animación de movimiento ─────────────
var _movement_vertical_offset: float = 0.0
var _movement_nucleo_rotation: float = 0.0

var _body_original_scale: Vector2
var _body_interior_original_scale: Vector2
var _nucleo_original_scale: Vector2

# ── Flecha indicadora del árbol ────────────────────────
@export_category("Flecha indicadora del árbol")
## Radio de órbita: distancia desde el origen del jugador a la que orbita la flecha.
@export var distancia_flecha_arbol: float = 45.0
## Desplazamiento vertical (altura) del centro del personaje desde donde orbita la flecha.
## Usar valores negativos para subirla (ej. -15.0).
@export var offset_altura_flecha: float = -15.0
## Distancia MÍNIMA en px entre el jugador y el árbol para que aparezca la flecha.
## (Poner en 0.0 si solo quieres que dependa de la cámara).
@export var distancia_minima_mostrar: float = 80.0
## Margen adicional de la pantalla en px para evitar apariciones en el mismo borde.
@export var margen_camara: float = 20.0
## Color de la flecha.
@export var color_flecha_arbol: Color = Color(1.0, 0.85, 0.2, 0.95)
## Tamaño (ancho x alto) del triángulo de la flecha.
@export var tamano_flecha_arbol: Vector2 = Vector2(18.0, 14.0)
## Tiempo en segundos que tarda la animación de aparición y desaparición.
@export var duracion_animacion_flecha: float = 0.25

var nodo_arbol: Node2D = null
var flecha_arbol: Polygon2D = null

# Control de animación de la flecha
var _flecha_visible_objetivo: bool = false
var _tween_flecha: Tween = null


func _ready() -> void:
	_actualizar_barra_vida()
	_conectar_respawn_manager()

	if timer_disparo != null:
		timer_disparo.wait_time = cadencia_basic

	if cuerpo != null:
		_color_original_cuerpo = cuerpo.modulate
	if nucleo != null:
		_color_original_nucleo = nucleo.modulate

	# Guardar valores originales para el efecto visual de regeneración
	if barra_vida != null:
		_barra_modulate_original = barra_vida.modulate
	if luz_base != null:
		_luz_base_original_color = luz_base.color
		_luz_base_original_energy = luz_base.energy
	if luz_punta != null:
		_luz_punta_original_color = luz_punta.color
		_luz_punta_original_energy = luz_punta.energy

	# Guardar escalas originales para animación de movimiento
	if cuerpo != null:
		_body_original_scale = cuerpo.scale
	if body_interior != null:
		_body_interior_original_scale = body_interior.scale
	if nucleo != null:
		_nucleo_original_scale = nucleo.scale

	_crear_particulas_regeneracion()

	_crear_flecha_arbol()
	_buscar_arbol()


func _crear_particulas_regeneracion() -> void:
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

	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(4.0, 4.0, 0.0)

	particle.process_material = material
	add_child(particle)
	_particulas_regeneracion = particle


func _conectar_respawn_manager() -> void:
	if respawn_manager == null:
		push_warning("Quark: falta asignar la referencia a RespawnManager (contador de respawn deshabilitado)")
		return

	if respawn_manager.has_signal("respawn_iniciado"):
		respawn_manager.connect("respawn_iniciado", _on_respawn_iniciado)

	if respawn_manager.has_signal("respawn_finalizado"):
		respawn_manager.connect("respawn_finalizado", _on_respawn_finalizado)


func _physics_process(delta: float) -> void:
	if _muerto:
		if _regeneracion_visual_activa:
			_detener_efecto_regeneracion()
			_regeneracion_visual_activa = false
		_set_flecha_visible(false)
		return

	aplicar_pulso_energia(delta)
	animar_movimiento(delta)
	animar_sombra(delta)
	actualizar_dash(delta)
	move()
	actualizar_aim()
	_actualizar_flecha_arbol(delta)

	if regeneracion_activa:
		var result = RegenerationHelper.update_regeneration(delta, life, vida_maxima, regeneracion_por_segundo, tiempo_sin_recibir_danio, retraso_regeneracion, regeneracion_activa)
		life = result.life
		tiempo_sin_recibir_danio = result.time_since_damage
		_actualizar_barra_vida()

	_actualizar_efecto_regeneracion(delta)


# ── Movimiento ─────────────────────────────────────────

func move() -> void:
	var delta: float = get_physics_process_delta_time()
	var vector_direccion = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')

	if _en_dash:
		velocity = _dash_direccion * velocidad_dash
		move_and_slide()
		return

	var velocidad_objetivo: Vector2 = vector_direccion * speed

	if vector_direccion != Vector2.ZERO:
		velocity = velocity.move_toward(velocidad_objetivo, aceleracion * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friccion * delta)

	move_and_slide()


func _intentar_dash_desde_boton() -> void:
	if _muerto or _en_dash or _dash_cooldown_timer > 0.0:
		return

	var vector_direccion = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	_iniciar_dash(vector_direccion)


func _iniciar_dash(vector_direccion: Vector2) -> void:
	if vector_direccion != Vector2.ZERO:
		_dash_direccion = vector_direccion.normalized()
	elif is_instance_valid(aim):
		_dash_direccion = Vector2.RIGHT.rotated(aim.rotation)

	_en_dash = true
	_dash_timer = duracion_dash
	_dash_cooldown_timer = cooldown_dash


func actualizar_dash(delta: float) -> void:
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta

	if _en_dash:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_en_dash = false


# ── Disparo ────────────────────────────────────────────

func shot(target: Node2D, _power_actual: String) -> void:
	if _muerto or not disparoON:
		return

	if not onFire or not is_instance_valid(target):
		return

	var direction = (target.global_position - aim.global_position).normalized()

	var bullet = proyectil.instantiate()
	bullet.scale = Vector2(0.5, 0.5)
	bullet.rotation = direction.angle()
	bullet.add_to_group('bullet')
	bullet.global_position = aim.global_position
	bullet.positionEnemi = direction

	get_tree().current_scene.add_child(bullet)


func _on_timer_timeout() -> void:
	if onFire and disparoON and is_instance_valid(enemi):
		shot(enemi, power)
	else:
		_actualizar_objetivo()


func actualizar_aim() -> void:
	if not is_instance_valid(aim):
		return

	if is_instance_valid(enemi):
		var direccion: Vector2 = (enemi.global_position - aim.global_position).normalized()
		aim.rotation = direccion.angle()
	elif velocity != Vector2.ZERO:
		aim.rotation = velocity.angle()


# ── Detección de enemigos en rango ────────────────────

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemi') and not enemigos_en_rango.has(body):
		enemigos_en_rango.append(body)
		_actualizar_objetivo()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group('enemi'):
		enemigos_en_rango.erase(body)
		_actualizar_objetivo()


func _actualizar_objetivo() -> void:
	enemigos_en_rango = enemigos_en_rango.filter(func(e): return is_instance_valid(e))

	if enemigos_en_rango.is_empty():
		onFire = false
		enemi = null
		return

	enemi = enemigos_en_rango[0]
	var dist_min = aim.global_position.distance_to(enemi.global_position)

	for e in enemigos_en_rango:
		var d = aim.global_position.distance_to(e.global_position)
		if d < dist_min:
			dist_min = d
			enemi = e

	onFire = true


# ── Botones de poder (UI) ──────────────────────────────

func _on_super_pressed() -> void:
	if _muerto:
		return

	if not BiomasaManager.consumir_biomasa():
		return

	_lanzar_lluvia_meteoritos()


func _on_mega_pressed() -> void:
	_intentar_dash_desde_boton()


# ── Super: Lluvia de Meteoritos ────────────────────────

func _lanzar_lluvia_meteoritos() -> void:
	var enemigos: Array = get_tree().get_nodes_in_group("enemi")

	var indice: int = 0
	for enemigo in enemigos:
		if not is_instance_valid(enemigo):
			continue

		var pos_impacto: Vector2 = enemigo.global_position + Vector2(
			randf_range(-25.0, 25.0), randf_range(-25.0, 25.0)
		)

		get_tree().create_timer(retraso_entre_meteoritos * indice).timeout.connect(
			func(): _spawn_meteorito(pos_impacto)
		)
		indice += 1


func _spawn_meteorito(pos_impacto: Vector2) -> void:
	var advertencia := Node2D.new()
	advertencia.global_position = pos_impacto
	advertencia.z_index = 500

	var radio: float = radio_impacto_meteorito
	advertencia.draw.connect(func():
		advertencia.draw_arc(Vector2.ZERO, radio, 0.0, TAU, 32, Color(1.0, 0.3, 0.1, 0.9), 4.0)
	)
	get_tree().current_scene.add_child(advertencia)
	advertencia.queue_redraw()

	var tween: Tween = advertencia.create_tween()
	tween.tween_property(advertencia, "scale", Vector2(0.3, 0.3), tiempo_advertencia_meteorito)
	tween.tween_callback(func():
		_impacto_meteorito(pos_impacto, radio)
		advertencia.queue_free()
	)


func _impacto_meteorito(pos_impacto: Vector2, radio: float) -> void:
	var explosion := Node2D.new()
	explosion.global_position = pos_impacto
	explosion.z_index = 500
	explosion.draw.connect(func():
		explosion.draw_circle(Vector2.ZERO, radio, Color(1.0, 0.55, 0.1, 0.55))
	)
	get_tree().current_scene.add_child(explosion)
	explosion.queue_redraw()

	var tween: Tween = explosion.create_tween()
	tween.tween_property(explosion, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)

	for enemigo in get_tree().get_nodes_in_group("enemi"):
		if not is_instance_valid(enemigo):
			continue
		if enemigo.global_position.distance_to(pos_impacto) <= radio:
			if enemigo.has_method("recibir_danio"):
				enemigo.recibir_danio(danio_meteorito, self)
			elif enemigo.has_method("take_damage"):
				enemigo.take_damage(danio_meteorito)


# ── Vida / daño ────────────────────────────────────────

func take_damage(damage: int) -> void:
	if _muerto:
		return

	_mostrar_flash_golpe()

	life -= damage
	tiempo_sin_recibir_danio = 0.0
	_actualizar_barra_vida()

	if life <= 0:
		_muerto = true
		_ocultar_al_morir()
		BiomasaManager.reiniciar_biomasa()
		died.emit()


func respawn_at(posicion: Vector2) -> void:
	life = vida_maxima
	global_position = posicion
	_actualizar_barra_vida()
	_restaurar_al_reaparecer()
	_muerto = false


func _ocultar_al_morir() -> void:
	if sombra != null:
		sombra.visible = false
	if nucleo != null:
		nucleo.visible = false
	if cuerpo != null:
		cuerpo.visible = false
	if luz_base != null:
		luz_base.enabled = false
	if luz_punta != null:
		luz_punta.enabled = false
	if colision != null:
		colision.set_deferred("disabled", true)
	if ui_contenedor != null:
		ui_contenedor.visible = false
	if contendor_controles != null:
		contendor_controles.visible = false
	_set_flecha_visible(false)


func _restaurar_al_reaparecer() -> void:
	if sombra != null:
		sombra.visible = true
	if nucleo != null:
		nucleo.visible = true
	if cuerpo != null:
		cuerpo.visible = true
	if luz_base != null:
		luz_base.enabled = true
	if luz_punta != null:
		luz_punta.enabled = true
	if colision != null:
		colision.set_deferred("disabled", false)
	if ui_contenedor != null:
		ui_contenedor.visible = true
	if contendor_controles != null:
		contendor_controles.visible = true


func _actualizar_barra_vida() -> void:
	if barra_vida == null:
		return
	barra_vida.max_value = vida_maxima
	barra_vida.value = clamp(life, 0, vida_maxima)


# ── Feedback visual de golpe ───────────────────────────

func _mostrar_flash_golpe() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()

	if cuerpo != null:
		cuerpo.modulate = color_flash_golpe
	if nucleo != null:
		nucleo.modulate = color_flash_golpe

	_flash_tween = create_tween()
	_flash_tween.set_parallel(true)
	if cuerpo != null:
		_flash_tween.tween_property(cuerpo, "modulate", _color_original_cuerpo, duracion_flash_golpe)
	if nucleo != null:
		_flash_tween.tween_property(nucleo, "modulate", _color_original_nucleo, duracion_flash_golpe)


# ── Contador de respawn (UI) ────────────────────────────

func _on_respawn_iniciado(tiempo_espera: float) -> void:
	_iniciar_contador_respawn(tiempo_espera)


func _on_respawn_finalizado() -> void:
	if contador_respawn != null:
		contador_respawn.visible = false


func _iniciar_contador_respawn(tiempo_espera: float) -> void:
	if contador_respawn == null:
		return

	var segundos_restantes: int = int(ceil(tiempo_espera))
	contador_respawn.visible = true
	await _actualizar_texto_contador(segundos_restantes)

	while segundos_restantes > 0:
		await get_tree().create_timer(1.0).timeout
		segundos_restantes -= 1
		await _actualizar_texto_contador(segundos_restantes)

	contador_respawn.visible = false


func _actualizar_texto_contador(segundos: int) -> void:
	contador_respawn.text = str(segundos)

	await get_tree().process_frame
	if contador_respawn == null:
		return
	contador_respawn.pivot_offset = contador_respawn.size / 2.0

	contador_respawn.scale = Vector2(1.4, 1.4)

	var tween = create_tween()
	tween.tween_property(contador_respawn, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ── Animaciones visuales ───────────────────────────────

func aplicar_pulso_energia(delta: float) -> void:
	if nucleo == null or luz_punta == null:
		return

	tiempo_pulso += delta * 5.0

	var factor_pulso: float = 1.0 + sin(tiempo_pulso) * 0.12
	nucleo.scale = Vector2(factor_pulso, factor_pulso)
	luz_punta.energy = 1.8 + sin(tiempo_pulso * 2.0) * 0.5


func animar_sombra(delta: float) -> void:
	if sombra == null:
		return

	if velocity != Vector2.ZERO:
		tiempo_caminata += delta * 18.0
		sombra.scale.x = 1.0 - sin(tiempo_caminata) * 0.1
	else:
		sombra.scale = sombra.scale.lerp(Vector2.ONE, delta * 10.0)


func _on_ajustes_button_down() -> void:
	$Pausa.visible = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_kill"):
		take_damage(9999)

func debug():
	print(contador_respawn.visible)

func activar_disparo() -> void:
	disparoON = true

func desactivar_disparo() -> void:
	disparoON = false


# ── Flecha indicadora del árbol ────────────────────────

## Crea el Polygon2D triangular que sirve de flecha.
func _crear_flecha_arbol() -> void:
	var flecha := Polygon2D.new()
	flecha.name = "FlechaArbol"
	flecha.z_index = 100
	flecha.top_level = true
	
	flecha.visible = false
	flecha.scale = Vector2.ZERO
	flecha.modulate.a = 0.0

	add_child(flecha)
	flecha_arbol = flecha
	_actualizar_geometria_flecha()


## Reconstruye el polígono de la flecha con el tamaño y color configurados.
func _actualizar_geometria_flecha() -> void:
	if flecha_arbol == null:
		return

	var mitad_ancho: float = tamano_flecha_arbol.x / 2.0
	var mitad_alto: float = tamano_flecha_arbol.y / 2.0

	flecha_arbol.polygon = PackedVector2Array([
		Vector2(mitad_ancho, 0.0),
		Vector2(-mitad_ancho, -mitad_alto),
		Vector2(-mitad_ancho, mitad_alto)
	])
	flecha_arbol.color = color_flecha_arbol


## Busca el árbol en la escena por su grupo "arbol".
func _buscar_arbol() -> void:
	await get_tree().process_frame
	nodo_arbol = get_tree().get_first_node_in_group("arbol")
	if nodo_arbol == null:
		push_warning("Quark: no se encontró ningún nodo en el grupo 'arbol'")


## Actualiza cada frame la posición, rotación y animación de la flecha.
func _actualizar_flecha_arbol(_delta: float) -> void:
	if flecha_arbol == null:
		return

	if _muerto:
		_set_flecha_visible(false)
		return

	if not is_instance_valid(nodo_arbol):
		_set_flecha_visible(false)
		_buscar_arbol()
		return

	# Punto de origen considerando el offset vertical
	var centro_origen: Vector2 = global_position + Vector2(0.0, offset_altura_flecha)
	var vector_hacia_arbol: Vector2 = (nodo_arbol.global_position - centro_origen)
	var distancia_al_arbol: float = vector_hacia_arbol.length()

	# 1. Comprobar si supera la distancia mínima de activación
	if distancia_al_arbol < distancia_minima_mostrar:
		_set_flecha_visible(false)
		return

	# 2. Comprobar si el árbol está fuera del campo de visión de la cámara
	var esta_fuera_camara: bool = not _arbol_esta_en_camara()

	if esta_fuera_camara:
		_set_flecha_visible(true)
		flecha_arbol.rotation = vector_hacia_arbol.angle()
		# Posición orbital exacta
		flecha_arbol.global_position = centro_origen + vector_hacia_arbol.normalized() * distancia_flecha_arbol
	else:
		_set_flecha_visible(false)


## Maneja las transiciones con Tween de aparición y desaparición.
func _set_flecha_visible(debe_mostrar: bool) -> void:
	if _flecha_visible_objetivo == debe_mostrar:
		return

	_flecha_visible_objetivo = debe_mostrar

	if _tween_flecha != null and _tween_flecha.is_valid():
		_tween_flecha.kill()

	_tween_flecha = create_tween().set_parallel(true)

	if debe_mostrar:
		flecha_arbol.visible = true
		_tween_flecha.tween_property(flecha_arbol, "scale", Vector2.ONE, duracion_animacion_flecha)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween_flecha.tween_property(flecha_arbol, "modulate:a", 1.0, duracion_animacion_flecha)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_tween_flecha.tween_property(flecha_arbol, "scale", Vector2.ZERO, duracion_animacion_flecha)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_tween_flecha.tween_property(flecha_arbol, "modulate:a", 0.0, duracion_animacion_flecha)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		_tween_flecha.chain().tween_callback(func(): 
			if not _flecha_visible_objetivo and flecha_arbol != null:
				flecha_arbol.visible = false
		)


## Comprueba si la posición global del árbol cae dentro del rectángulo del viewport (con margen).
func _arbol_esta_en_camara() -> bool:
	var viewport := get_viewport()
	if viewport == null or nodo_arbol == null:
		return true

	var transform_canvas: Transform2D = viewport.get_canvas_transform()
	var pos_en_pantalla: Vector2 = transform_canvas * nodo_arbol.global_position
	var tamano_pantalla: Vector2 = viewport.get_visible_rect().size

	# Rectángulo ampliado según el margen
	var rect_pantalla := Rect2(
		Vector2(-margen_camara, -margen_camara),
		tamano_pantalla + Vector2(margen_camara * 2.0, margen_camara * 2.0)
	)

	return rect_pantalla.has_point(pos_en_pantalla)


# ── Efecto visual de regeneración ──────────────────────

func _actualizar_efecto_regeneracion(_delta: float) -> void:
	var regenerando: bool = regeneracion_activa and tiempo_sin_recibir_danio >= retraso_regeneracion and life < vida_maxima

	if regenerando == _regeneracion_visual_activa:
		return

	if regenerando:
		_iniciar_efecto_regeneracion()
	else:
		_detener_efecto_regeneracion()

	_regeneracion_visual_activa = regenerando


func _iniciar_efecto_regeneracion() -> void:
	if barra_vida != null:
		if _tween_barra_regeneracion != null and _tween_barra_regeneracion.is_valid():
			_tween_barra_regeneracion.kill()
		_tween_barra_regeneracion = create_tween().set_loops()
		_tween_barra_regeneracion.tween_property(barra_vida, "scale", Vector2(1.08, 1.08), 0.6)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tween_barra_regeneracion.tween_property(barra_vida, "scale", Vector2(1.0, 1.0), 0.6)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

		if _tween_barra_color_regeneracion != null and _tween_barra_color_regeneracion.is_valid():
			_tween_barra_color_regeneracion.kill()
		_tween_barra_color_regeneracion = create_tween()
		_tween_barra_color_regeneracion.tween_property(barra_vida, "modulate", Color(0.2, 1.0, 0.3, 1.0), 0.3)\
			.set_ease(Tween.EASE_IN_OUT)

	if _particulas_regeneracion != null:
		_particulas_regeneracion.emitting = true

	if luz_base != null:
		if _tween_luz_base_regeneracion != null and _tween_luz_base_regeneracion.is_valid():
			_tween_luz_base_regeneracion.kill()
		_tween_luz_base_regeneracion = create_tween().set_loops()
		_tween_luz_base_regeneracion.tween_property(luz_base, "energy", _luz_base_original_energy * 1.6, 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tween_luz_base_regeneracion.parallel().tween_property(luz_base, "color", Color(0.2, 1.0, 0.3, 1.0), 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tween_luz_base_regeneracion.tween_property(luz_base, "energy", _luz_base_original_energy, 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tween_luz_base_regeneracion.parallel().tween_property(luz_base, "color", _luz_base_original_color, 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	if luz_punta != null:
		if _tween_luz_punta_regeneracion != null and _tween_luz_punta_regeneracion.is_valid():
			_tween_luz_punta_regeneracion.kill()
		_tween_luz_punta_regeneracion = create_tween().set_loops()
		_tween_luz_punta_regeneracion.tween_property(luz_punta, "energy", _luz_punta_original_energy * 1.6, 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tween_luz_punta_regeneracion.parallel().tween_property(luz_punta, "color", Color(0.2, 1.0, 0.3, 1.0), 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tween_luz_punta_regeneracion.tween_property(luz_punta, "energy", _luz_punta_original_energy, 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tween_luz_punta_regeneracion.parallel().tween_property(luz_punta, "color", _luz_punta_original_color, 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _detener_efecto_regeneracion() -> void:
	if _tween_barra_regeneracion != null and _tween_barra_regeneracion.is_valid():
		_tween_barra_regeneracion.kill()
	if _tween_barra_color_regeneracion != null and _tween_barra_color_regeneracion.is_valid():
		_tween_barra_color_regeneracion.kill()

	if barra_vida != null:
		barra_vida.scale = Vector2.ONE
		barra_vida.modulate = _barra_modulate_original

	if _particulas_regeneracion != null:
		_particulas_regeneracion.emitting = false

	if luz_base != null:
		if _tween_luz_base_regeneracion != null and _tween_luz_base_regeneracion.is_valid():
			_tween_luz_base_regeneracion.kill()
		luz_base.color = _luz_base_original_color
		luz_base.energy = _luz_base_original_energy

	if luz_punta != null:
		if _tween_luz_punta_regeneracion != null and _tween_luz_punta_regeneracion.is_valid():
			_tween_luz_punta_regeneracion.kill()
		luz_punta.color = _luz_punta_original_color
		luz_punta.energy = _luz_punta_original_energy


# ── Animación de movimiento ───────────────────────────

func animar_movimiento(delta: float) -> void:
	var moving: bool = velocity.length() > 10.0

	if moving:
		tiempo_caminata += delta * 14.0
		var dir: Vector2 = velocity.normalized()

		var target_scale: Vector2 = Vector2(
			_body_original_scale.x + abs(dir.x) * 0.15,
			_body_original_scale.y - abs(dir.x) * 0.08
		)

		var vertical_bob: float = sin(tiempo_caminata * 6.0) * 2.0

		if cuerpo != null:
			cuerpo.scale = cuerpo.scale.lerp(target_scale, delta * 12.0)

		if body_interior != null:
			var target_interior: Vector2 = _body_interior_original_scale * (target_scale / _body_original_scale)
			body_interior.scale = body_interior.scale.lerp(target_interior, delta * 12.0)

		_movement_vertical_offset = _movement_vertical_offset + (vertical_bob - _movement_vertical_offset) * delta * 10.0
		if cuerpo != null:
			cuerpo.position.y = _movement_vertical_offset

		_nucleo_original_scale = nucleo.scale if nucleo != null else Vector2.ONE
		var nucleo_target_scale: float = _nucleo_original_scale.x + 0.1 + sin(tiempo_caminata * 8.0) * 0.08
		if nucleo != null:
			nucleo.scale = nucleo.scale.lerp(Vector2(nucleo_target_scale, nucleo_target_scale), delta * 10.0)
			_movement_nucleo_rotation = sin(tiempo_caminata * 4.0) * 0.1
			nucleo.rotation = nucleo.rotation + (_movement_nucleo_rotation - nucleo.rotation) * delta * 6.0

	else:
		if cuerpo != null:
			cuerpo.scale = cuerpo.scale.lerp(_body_original_scale, delta * 10.0)
		if body_interior != null:
			body_interior.scale = body_interior.scale.lerp(_body_interior_original_scale, delta * 10.0)

		_movement_vertical_offset = _movement_vertical_offset * (1.0 - delta * 8.0)
		if cuerpo != null:
			cuerpo.position.y = _movement_vertical_offset

		if nucleo != null:
			nucleo.scale = nucleo.scale.lerp(_nucleo_original_scale, delta * 10.0)
			nucleo.rotation = nucleo.rotation * (1.0 - delta * 6.0)
