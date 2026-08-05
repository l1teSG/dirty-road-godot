extends Player

# ── Referencias a nodos ──────────────────────────────
@onready var rangeArea = $Area2D/range
@onready var aim: Node2D = $aim
@onready var nucleo: Polygon2D = $Nucleo
@onready var cuerpo: Polygon2D = $body
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
		# Si el jugador muere, detener el efecto visual de regeneración
		if _regeneracion_visual_activa:
			_detener_efecto_regeneracion_visual()
			_regeneracion_visual_activa = false
		return

	aplicar_pulso_energia(delta)
	animar_sombra(delta)
	actualizar_dash(delta)
	move()
	actualizar_aim()

	if regeneracion_activa:
		var result = RegenerationHelper.update_regeneration(delta, life, vida_maxima, regeneracion_por_segundo, tiempo_sin_recibir_danio, retraso_regeneracion, regeneracion_activa)
		life = result.life
		tiempo_sin_recibir_danio = result.time_since_damage
		_actualizar_barra_vida()

	# Actualizar efecto visual
	_actualizar_efecto_regeneracion_visual()


# ── Movimiento (con aceleración/fricción y dash) ──────
# Mantiene la misma firma que el padre (Player.move(), sin parámetros).

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


## Intenta iniciar un dash. Llamado desde el botón en pantalla "mega".
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


## Rota el nodo "aim" hacia el enemigo objetivo actual (si existe), o hacia
## la dirección de movimiento cuando no hay ningún enemigo en rango.
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


# ── Botones de poder (UI en pantalla) ──────────────────

## Botón "super": activa la lluvia de meteoritos SOLO si la biomasa
## está al máximo. La consume por completo al activarse.
func _on_super_pressed() -> void:
	if _muerto:
		return

	if not BiomasaManager.consumir_biomasa():
		# No hay suficiente biomasa todavía; no se activa el super.
		return

	_lanzar_lluvia_meteoritos()


## Botón "mega": ahora activa el dash directamente (ya no cambia "power").
func _on_mega_pressed() -> void:
	_intentar_dash_desde_boton()


# ── Super: Lluvia de Meteoritos ────────────────────────

## Lanza un meteorito sobre cada enemigo vivo actualmente en el mapa.
func _lanzar_lluvia_meteoritos() -> void:
	var enemigos: Array = get_tree().get_nodes_in_group("enemi")

	var indice: int = 0
	for enemigo in enemigos:
		if not is_instance_valid(enemigo):
			continue

		var pos_impacto: Vector2 = enemigo.global_position + Vector2(
			randf_range(-25.0, 25.0), randf_range(-25.0, 25.0)
		)

		# Pequeño retraso escalonado para que no caigan todos en el mismo frame
		get_tree().create_timer(retraso_entre_meteoritos * indice).timeout.connect(
			func(): _spawn_meteorito(pos_impacto)
		)
		indice += 1


## Crea el círculo de advertencia en el punto de impacto, que se contrae
## durante "tiempo_advertencia_meteorito" y luego detona.
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


## Ejecuta la explosión visual y aplica daño en área a todos los enemigos
## dentro del radio de impacto.
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


# ── Feedback visual de golpe recibido ─────────────────

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


# ── Efecto visual de regeneración ──────────────────────

func _actualizar_efecto_regeneracion_visual() -> void:
	# Determina si el jugador debería estar regenerando visualmente
	var regenerando: bool = regeneracion_activa and tiempo_sin_recibir_danio >= retraso_regeneracion and life < vida_maxima

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
	# Inicio efecto regeneración: barra de vida, partículas y luces

	# --- Barra de vida: pulso de escala y cambio de color ---
	if barra_vida != null:
		# Pulso de escala (loop infinito)
		if _tween_barra_regeneracion != null and _tween_barra_regeneracion.is_valid():
			_tween_barra_regeneracion.kill()
		_tween_barra_regeneracion = create_tween().set_loops()
		_tween_barra_regeneracion.tween_property(barra_vida, "scale", Vector2(1.08, 1.08), 0.6)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tween_barra_regeneracion.tween_property(barra_vida, "scale", Vector2(1.0, 1.0), 0.6)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

		# Transición de color a verde brillante (una sola vez)
		if _tween_barra_color_regeneracion != null and _tween_barra_color_regeneracion.is_valid():
			_tween_barra_color_regeneracion.kill()
		_tween_barra_color_regeneracion = create_tween()
		_tween_barra_color_regeneracion.tween_property(barra_vida, "modulate", Color(0.2, 1.0, 0.3, 1.0), 0.3)\
			.set_ease(Tween.EASE_IN_OUT)

	# --- Partículas de regeneración ---
	if _particulas_regeneracion != null:
		_particulas_regeneracion.emitting = true

	# --- Luces : cambiar suavemente a verde y aumentar energía ---
	if luz_base != null:
		if _tween_luz_base_regeneracion != null and _tween_luz_base_regeneracion.is_valid():
			_tween_luz_base_regeneracion.kill()
		_tween_luz_base_regeneracion = create_tween()
		_tween_luz_base_regeneracion.tween_property(luz_base, "color", Color(0.2, 1.0, 0.3, 1.0), 0.5)\
			.set_ease(Tween.EASE_IN_OUT)
		_tween_luz_base_regeneracion.parallel().tween_property(luz_base, "energy", _luz_base_original_energy * 1.4, 0.5)\
			.set_ease(Tween.EASE_IN_OUT)

	if luz_punta != null:
		if _tween_luz_punta_regeneracion != null and _tween_luz_punta_regeneracion.is_valid():
			_tween_luz_punta_regeneracion.kill()
		_tween_luz_punta_regeneracion = create_tween()
		_tween_luz_punta_regeneracion.tween_property(luz_punta, "color", Color(0.2, 1.0, 0.3, 1.0), 0.5)\
			.set_ease(Tween.EASE_IN_OUT)
		_tween_luz_punta_regeneracion.parallel().tween_property(luz_punta, "energy", _luz_punta_original_energy * 1.4, 0.5)\
			.set_ease(Tween.EASE_IN_OUT)


func _detener_efecto_regeneracion_visual() -> void:
	# Fin efecto regeneración: restaurar todo a su estado original

	# --- Barra de vida: restaurar escala y color ---
	if _tween_barra_regeneracion != null and _tween_barra_regeneracion.is_valid():
		_tween_barra_regeneracion.kill()
	if _tween_barra_color_regeneracion != null and _tween_barra_color_regeneracion.is_valid():
		_tween_barra_color_regeneracion.kill()

	if barra_vida != null:
		barra_vida.scale = Vector2.ONE
		barra_vida.modulate = _barra_modulate_original

	# --- Partículas: detener emisión ---
	if _particulas_regeneracion != null:
		_particulas_regeneracion.emitting = false

	# --- Luces: restaurar color y energía originales ---
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
