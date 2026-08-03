extends Player

# ── Referencias a nodos ──────────────────────────────
@onready var rangeArea = $Area2D/range
@onready var aim: Node2D = $aim
@onready var nucleo: Polygon2D = $Nucleo
@onready var luz_punta: PointLight2D = $LuzPunta
@onready var sombra: Polygon2D = $sombra
@onready var barra_vida: ProgressBar = $ui/margenUi/ContenedorVertical/FilaVida/BarraVida

# ── Combate / disparo ─────────────────────────────────
var proyectil: PackedScene = preload("res://ecenes/players/projectile/quark/playerProyectil.tscn")
var power: String = 'basic'  # basic | super | mega
var onFire: bool = false
var enemi: Node2D = null
var enemigos_en_rango: Array[Node2D] = []

# ── Animación ──────────────────────────────────────────
var tiempo_caminata: float = 0.0
var tiempo_pulso: float = 0.0

# ── Vida / respawn ─────────────────────────────────────
## Vida máxima del jugador, usada para restaurarla al hacer respawn.
@export var vida_maxima: int = 100

## Emitida cuando la vida llega a 0. RespawnManager escucha esta señal
## para iniciar la secuencia de respawn.
signal died

## Evita que el jugador siga recibiendo daño (y re-emitiendo "died")
## mientras ya está esperando a que RespawnManager lo reposicione.
var _muerto: bool = false


func _ready() -> void:
	
	_actualizar_barra_vida()


func _physics_process(delta: float) -> void:
	# Salvaguarda: si el jugador está muerto (esperando respawn), no debe
	# procesar movimiento ni animaciones. En la práctica esto ya queda
	# cubierto por process_mode = PROCESS_MODE_DISABLED en take_damage(),
	# pero se deja esta guarda explícita como protección adicional.
	if _muerto:
		return

	aplicar_pulso_energia(delta)
	animar_sombra(delta)
	move()


func move() -> void:
	var vectorDireccion = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	velocity = vectorDireccion * speed
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
	# Si ya está esperando el respawn, ignoramos daño adicional para no
	# seguir bajando "life" indefinidamente ni re-emitir "died".
	if _muerto:
		return

	life -= damage
	_actualizar_barra_vida()

	if life <= 0:
		_muerto = true
		hide()
		process_mode = Node.PROCESS_MODE_DISABLED
		died.emit()


## Restaura la vida al máximo y reposiciona al jugador.
## Llamado por RespawnManager una vez transcurrido el tiempo de espera.
func respawn_at(posicion: Vector2) -> void:
	life = vida_maxima
	global_position = posicion
	_actualizar_barra_vida()
	show()
	process_mode = Node.PROCESS_MODE_INHERIT
	_muerto = false


## Sincroniza la barra de vida de la UI con el valor actual de "life".
func _actualizar_barra_vida() -> void:
	if barra_vida == null:
		return
	barra_vida.max_value = vida_maxima
	barra_vida.value = clamp(life, 0, vida_maxima)


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
