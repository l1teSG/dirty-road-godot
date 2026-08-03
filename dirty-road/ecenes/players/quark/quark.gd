extends Player

# ── Referencias a nodos ──────────────────────────────
@onready var rangeArea = $Area2D/range
@onready var aim: Node2D = $aim
@onready var nucleo: Polygon2D = $Nucleo
@onready var luz_punta: PointLight2D = $LuzPunta
@onready var sombra: Polygon2D = $sombra
@onready var joystick: VirtualJoystick = $controls/Joystick  # Joystick virtual

# ── Combate / disparo ─────────────────────────────────
var proyectil: PackedScene = preload("res://ecenes/players/projectile/quark/playerProyectil.tscn")
var power: String = 'basic'  # basic | super | mega
var onFire: bool = false
var enemi: Node2D = null
var enemigos_en_rango: Array[Node2D] = []

# ── Animación ──────────────────────────────────────────
var tiempo_caminata: float = 0.0
var tiempo_pulso: float = 0.0


func _physics_process(delta: float) -> void:
	aplicar_pulso_energia(delta)
	animar_sombra(delta)
	move()

	if life <= 0:
		queue_free()


func move() -> void:
	# Obtener dirección desde el joystick virtual
	var vector_direccion: Vector2 = Vector2.ZERO
	if joystick != null:
		vector_direccion = joystick.get_value()

	# Si el joystick apenas se usa, complementar con teclado
	if vector_direccion.length() < 0.1:
		vector_direccion = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')

	# Suavizar el movimiento (sin aceleración brusca)
	velocity = vector_direccion * speed
	move_and_slide()


# ── Disparo ────────────────────────────────────────────

func shot(target: Node2D, power_actual: String) -> void:
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
	if onFire and is_instance_valid(enemi):
		shot(enemi, power)
	else:
		_actualizar_objetivo()


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
	# limpia referencias a enemigos que ya no existen
	enemigos_en_rango = enemigos_en_rango.filter(func(e): return is_instance_valid(e))

	if enemigos_en_rango.is_empty():
		onFire = false
		enemi = null
		return

	# elige siempre el enemigo más cercano al punto de mira
	enemi = enemigos_en_rango[0]
	var dist_min = aim.global_position.distance_to(enemi.global_position)

	for e in enemigos_en_rango:
		var d = aim.global_position.distance_to(e.global_position)
		if d < dist_min:
			dist_min = d
			enemi = e

	onFire = true


# ── Poder de disparo ───────────────────────────────────

func _on_super_pressed() -> void:
	
	power = 'super'


func _on_mega_pressed() -> void:
	
	power = 'mega'


# ── Vida / daño ────────────────────────────────────────

func take_damage(damage: int) -> void:
	life -= damage
	if life <= 0:
		get_tree().change_scene_to_file('res://demo/muerte.tscn')


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
