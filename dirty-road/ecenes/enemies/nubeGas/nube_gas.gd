class_name NubeGas
extends enemigoNuevo

## ------------------------------------------------------------
## Enemigo a Rango "Nube de Gas"
## Dispara proyectiles desde lejos, huye cuando el jugador
## se acerca demasiado y nunca persigue al jugador.
## ------------------------------------------------------------

# Variables exportables (ajustables en Inspector)
@export var velocidad_movimiento: float = 85.0
@export var rango_ataque: float = 850.0
@export var distancia_minima_jugador: float = 150.0   # el jugador disparará la huida
@export var distancia_maxima_jugador: float = 400.0   # fuera de este rango la nube ignora al jugador
@export var velocidad_retroceso: float = 100.0
@export var danio_proyectil: int = 12
@export var intervalo_disparo: float = 1.8
@export var velocidad_proyectil: float = 400.0
@export var escena_proyectil: PackedScene = preload("res://ecenes/enemies/nubeGas/bullet/bulletGas.tscn")

# Referencias a nodos visuales (asignar en la escena)
@onready var cuerpo_ext: Polygon2D = $CuerpoExterior
@onready var luz: PointLight2D = $PointLight2D

# Estado interno
var puede_disparar: bool = true
var target_tree: Node2D = null
var target_player: Node2D = null

func _ready() -> void:
	# Registrar en el grupo de enemigos
	add_to_group("enemi")

	# Ajustar perfil de Nube de Gas sobreescribiendo parámetros heredados
	life = 60
	# Ajustamos también las variables heredadas para coherencia
	danio_ataque = danio_proyectil
	tiempo_recarga = intervalo_disparo
	distancia_ataque = rango_ataque
	distancia_urgencia_arbol = rango_ataque - 50.0
	distancia_max_aggro = rango_ataque + 100.0
	tiempo_aggro = 3.0

# ─── Funciones de búsqueda ──────────────────────────────

func buscar_arbol() -> Node2D:
	var arbol: Node2D = get_tree().get_first_node_in_group("arbol")
	if arbol == null:
		arbol = get_tree().get_first_node_in_group("tree")
	return arbol

func buscar_jugador() -> Node2D:
	var player: Node2D = get_tree().get_first_node_in_group("jugador")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	return player

func actualizar_objetivos() -> void:
	target_tree = buscar_arbol()
	target_player = buscar_jugador()

# ─── Movimiento modular ──────────────────────────────────

func mover() -> void:
	actualizar_objetivos()

	var player_valid: bool = is_instance_valid(target_player)
	var tree_valid: bool = is_instance_valid(target_tree)

	# Priorizar la huida si el jugador está demasiado cerca
	if player_valid:
		var dist_player: float = global_position.distance_to(target_player.global_position)
		if dist_player <= distancia_minima_jugador:
			# Retroceder (alejarse del jugador)
			var dir_retirada: Vector2 = (global_position - target_player.global_position).normalized()
			velocity = dir_retirada * velocidad_retroceso
			# Anular objetivo de ataque mientras se aleja
			objetivo = null
			return

		# Si el jugador está dentro de la distancia máxima pero fuera de la mínima,
		# mantener distancia: quedarse quieto (no perseguir)
		if dist_player <= distancia_maxima_jugador and dist_player > distancia_minima_jugador:
			velocity = Vector2.ZERO
			objetivo = null
			return

	# Sin interferencia del jugador, volver a la lógica del árbol
	if tree_valid:
		var dist_tree: float = global_position.distance_to(target_tree.global_position)
		if dist_tree > rango_ataque:
			# Avanzar hacia el árbol
			var dir_arbol: Vector2 = (target_tree.global_position - global_position).normalized()
			velocity = dir_arbol * velocidad_movimiento
		else:
			# Dentro del rango de ataque, detenerse para disparar
			velocity = Vector2.ZERO
			objetivo = target_tree  # aseguramos que el árbol es el objetivo
	else:
		velocity = Vector2.ZERO

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

	# Configurar el proyectil
	bullet.danio = danio_proyectil
	bullet.velocidad = velocidad_proyectil
	bullet.inicializar(dir_disparo, global_position + (dir_disparo * 45.0))

	get_tree().current_scene.add_child(bullet)

	# Animación de retroceso
	_animar_retroceso()

	# Cooldown
	puede_disparar = false
	await get_tree().create_timer(intervalo_disparo).timeout
	puede_disparar = true

# ─── Física ──────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	# Ejecuta comportamiento base (animación, selección de objetivo, etc.)
	super(delta)

	# Llamar a la lógica modular de movimiento
	mover()

	# Llamar a disparar si estamos en condiciones
	disparar()

	# Aplicar movimiento
	move_and_slide()

# ─── Selección de objetivo mejorada ─────────────────────

func seleccionar_objetivo() -> void:
	# La selección de objetivo la hacemos manualmente en mover/disparar,
	# porque no queremos que la clase padre sobreescriba nuestro objetivo.
	# Simplemente no hacemos nada aquí; el objetivo se asigna en mover().
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
