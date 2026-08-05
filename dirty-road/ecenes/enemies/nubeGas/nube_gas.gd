class_name NubeGas
extends enemigoNuevo

## ------------------------------------------------------------
## Enemigo a Rango "Nube de Gas"
## Prioridad absoluta al jugador mientras esté vivo: le dispara
## y se mueve constantemente (strafe) mientras lo hace. Si el
## jugador se acerca demasiado, huye en línea recta.
## Solo ataca al árbol si el jugador está muerto o no existe.
## ------------------------------------------------------------

# Variables exportables (ajustables en Inspector)
@export var velocidad_movimiento: float = 85.0
@export var rango_ataque: float = 850.0
@export var distancia_minima_jugador: float = 150.0   # dispara la huida
@export var velocidad_retroceso: float = 100.0
@export var danio_proyectil: int = 12
@export var intervalo_disparo: float = 1.8
@export var velocidad_proyectil: float = 400.0
@export var escena_proyectil: PackedScene = preload("res://ecenes/enemies/nubeGas/bullet/bulletGas.tscn")

@export_category("Movimiento de Strafe")
@export var velocidad_strafe: float = 60.0
@export var tiempo_cambio_strafe_min: float = 1.0
@export var tiempo_cambio_strafe_max: float = 2.5

# Referencias a nodos visuales (asignar en la escena)
@onready var cuerpo_ext: Polygon2D = $CuerpoExterior
@onready var luz: PointLight2D = $PointLight2D

# Estado interno
var puede_disparar: bool = true
var target_tree: Node2D = null
var target_player: Node2D = null

var strafe_dir: float = 1.0          # 1 = un lado, -1 = el otro
var strafe_timer: float = 0.0

func _ready() -> void:
	configurar_etiqueta_nombre("Nube de Gas")

	add_to_group("enemi")

	life = 60
	danio_ataque = danio_proyectil
	tiempo_recarga = intervalo_disparo
	distancia_ataque = rango_ataque
	distancia_urgencia_arbol = rango_ataque - 50.0
	distancia_max_aggro = rango_ataque + 100.0
	tiempo_aggro = 3.0

	_reiniciar_timer_strafe()
	strafe_dir = 1.0 if randf() < 0.5 else -1.0

# ─── Actualización de objetivos ─────────────────────────

func actualizar_objetivos() -> void:
	target_tree = buscar_arbol()
	target_player = buscar_jugador()

func _jugador_esta_vivo(jugador: Node2D) -> bool:
	if not is_instance_valid(jugador):
		return false
	if jugador.has_method("is_dead"):
		return not jugador.is_dead()
	if "life" in jugador:
		return jugador.life > 0
	return true

func _reiniciar_timer_strafe() -> void:
	strafe_timer = randf_range(tiempo_cambio_strafe_min, tiempo_cambio_strafe_max)

# ─── IA unificada: decide objetivo Y movimiento juntos ──

func actualizar_ia(delta: float) -> void:
	actualizar_objetivos()

	var player_valid: bool = is_instance_valid(target_player)
	var player_vivo: bool = player_valid and _jugador_esta_vivo(target_player)

	# ── Prioridad absoluta: si el jugador está vivo, siempre es el objetivo ──
	if player_vivo:
		var dist_player: float = global_position.distance_to(target_player.global_position)
		var dir_al_jugador: Vector2 = (target_player.global_position - global_position).normalized()

		objetivo = target_player

		# Demasiado cerca: huir en línea recta, ignorar el strafe
		if dist_player <= distancia_minima_jugador:
			velocity = -dir_al_jugador * velocidad_retroceso
			return

		# Fuera de rango de disparo: acercarse directo para tener línea de tiro
		if dist_player > rango_ataque:
			velocity = dir_al_jugador * velocidad_movimiento
			return

		# En rango de disparo y a distancia segura: mantenerse en movimiento (strafe)
		strafe_timer -= delta
		if strafe_timer <= 0.0:
			strafe_dir *= -1.0
			_reiniciar_timer_strafe()

		var dir_perpendicular: Vector2 = dir_al_jugador.orthogonal() * strafe_dir
		velocity = dir_perpendicular * velocidad_strafe
		return

	# ── Jugador muerto o inexistente: enfocarse en el árbol ──
	var tree_valid: bool = is_instance_valid(target_tree)
	if tree_valid:
		var dist_tree: float = global_position.distance_to(target_tree.global_position)
		if dist_tree > rango_ataque:
			var dir_arbol: Vector2 = (target_tree.global_position - global_position).normalized()
			velocity = dir_arbol * velocidad_movimiento
		else:
			velocity = Vector2.ZERO
		objetivo = target_tree
		return

	# ── Nada válido ──
	velocity = Vector2.ZERO
	objetivo = null

# ─── Disparo modular ─────────────────────────────────────

func disparar() -> void:
	if not puede_disparar:
		return
	if not is_instance_valid(objetivo):
		return
	if global_position.distance_to(objetivo.global_position) > rango_ataque:
		return

	var bullet = escena_proyectil.instantiate()
	var dir_disparo: Vector2 = (objetivo.global_position - global_position).normalized()

	bullet.danio = danio_proyectil
	bullet.velocidad = velocidad_proyectil
	bullet.inicializar(dir_disparo, global_position + (dir_disparo * 45.0))

	get_tree().current_scene.add_child(bullet)

	_animar_retroceso()

	puede_disparar = false
	await get_tree().create_timer(intervalo_disparo).timeout
	puede_disparar = true

# ─── Física ──────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	super(delta)

	actualizar_ia(delta)
	disparar()

	move_and_slide()

# NubeGas maneja su propio objetivo manualmente en actualizar_ia(),
# así que no dejamos que la clase padre lo sobreescriba.
func seleccionar_objetivo() -> void:
	pass

# ─── Animación de retroceso ─────────────────────────────

func _animar_retroceso() -> void:
	if not is_instance_valid(cuerpo_ext):
		return

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(cuerpo_ext, "scale", Vector2(0.85, 0.85), 0.05)
	if is_instance_valid(luz):
		tween.tween_property(luz, "energy", 2.5, 0.05)

	tween.tween_property(cuerpo_ext, "scale", Vector2.ONE, 0.1).set_delay(0.05)
	if is_instance_valid(luz):
		tween.tween_property(luz, "energy", 1.0, 0.1).set_delay(0.05)
