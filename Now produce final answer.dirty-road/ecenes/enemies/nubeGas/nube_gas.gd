class_name NubeGas
extends enemigoNuevo

## ------------------------------------------------------------
## Enemigo a Rango "Nube de Gas"
## Dispara proyectiles desde lejos y huye cuando el jugador
## se acerca demasiado.
## ------------------------------------------------------------

# Variables exportables (ajustables en Inspector)
@export var velocidad_movimiento: float = 85.0
@export var rango_disparo: float = 850.0
@export var rango_huida: float = 140.0
@export var escena_proyectil: PackedScene = preload("res://ecenes/enemies/nubeGas/bullet/bulletGas.tscn")

# Nuevas variables exportables para interacción con el jugador
@export var distancia_minima_jugador: float = 150.0      # Si el jugador está más cerca, la nube retrocede
@export var distancia_maxima_jugador: float = 400.0      # Si el jugador está más lejos, vuelve a centrarse en el árbol
@export var velocidad_retroceso: float = 100.0           # Velocidad al alejarse del jugador

# Referencias a nodos visuales (asignar en la escena)
@onready var cuerpo_ext: Polygon2D = $CuerpoExterior
@onready var luz: PointLight2D = $PointLight2D

# Estado interno
var target_tree: Node2D = null
var target_player: Node2D = null

func _ready() -> void:
	# Registrar en el grupo de enemigos
	add_to_group("enemi")

	# Ajustar perfil de Nube de Gas sobreescribiendo parámetros heredados
	life = 60
	danio_ataque = 12
	tiempo_recarga = 1.8
	distancia_ataque = 850.0          # Coincide con el nuevo rango de disparo
	distancia_urgencia_arbol = 400.0
	distancia_max_aggro = 500.0
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
			# Anular objetivo de ataque mientras se aleja (para no disparar en retroceso)
			objetivo = null
			return

		# Si el jugador está dentro de la distancia máxima pero fuera de la mínima,
		# mantener distancia: quedarse quieto (no perseguir)
		if dist_player <= distancia_max_jugador and dist_player > distancia_minima_jugador:
			# No moverse (velocidad nula) – la IA no avanza ni retrocede
			velocity = Vector2.ZERO
			# No atacar al jugador; el disparo sigue dirigido al árbol si lo tenía
			return

	# Si el jugador está fuera del rango máximo (o no existe), volver a la lógica del árbol
	if tree_valid:
		var dist_tree: float = global_position.distance_to(target_tree.global_position)
		if dist_tree > rango_disparo:
			# Avanzar hacia el árbol
			var dir_arbol: Vector2 = (target_tree.global_position - global_position).normalized()
			velocity = dir_arbol * velocidad_movimiento
		else:
			# Dentro del rango de disparo, detenerse para atacar
			velocity = Vector2.ZERO
	else:
		# Sin árbol ni jugador, detenerse
		velocity = Vector2.ZERO


# ─── Disparo modular ─────────────────────────────────────

func disparar() -> void:
	# Esta función se llama a través de evaluar_y_ejecutar_ataque (heredado)
	# No necesitamos implementar nada extra aquí; el método padre se encarga.
	pass


# ─── Física ──────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	# Primero ejecuta comportamiento base (animación, selección de objetivo, etc.)
	super(delta)

	# Llamar a la lógica modular de movimiento
	mover()

	# Aplicar movimiento
	move_and_slide()


# ─── Selección de objetivo mejorada ─────────────────────

func seleccionar_objetivo() -> void:
	# Primero verificar si hay jugador cerca para priorizar la huída
	var player: Node2D = buscar_jugador()
	if is_instance_valid(player):
		var dist: float = global_position.distance_to(player.global_position)
		# Si el jugador está dentro del rango de huida, priorizarlo como objetivo
		# (aunque la nube no ataque al jugador, necesita saber dónde está para huir)
		if dist <= distancia_minima_jugador or en_aggro:
			# No fijar objetivo de ataque, sino usarlo solo para movimiento
			# Dejamos que mover() maneje la huida
			# Pero necesitamos que objetivo esté vacío para que mover() lo gestione,
			# así que no lo asignamos. El ataque lo maneja el timer heredado.
			return

	# Si no hay prioridad de jugador, delegar a la clase padre (Árbol)
	super()


# ─── Ataque (se ejecuta desde el Timer heredado) ─────────

func evaluar_y_ejecutar_ataque() -> void:
	# Solo atacar si el jugador NO está interfiriendo (fuera de rango mínimo)
	if is_instance_valid(target_player):
		var dist_player: float = global_position.distance_to(target_player.global_position)
		if dist_player <= distancia_minima_jugador:
			# No atacar mientras huye
			return

	# Ejecutar lógica heredada (disparo al objetivo)
	super()

func _animar_retroceso() -> void:
	# Pequeña animación visual de retroceso al disparar
	if not is_instance_valid(cuerpo_ext):
		return

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Comprimir escala brevemente
	tween.tween_property(cuerpo_ext, "scale", Vector2(0.85, 0.85), 0.05)
	if is_instance_valid(luz):
		tween.tween_property(luz, "energy", 2.5, 0.05)

	# Recuperar escala normal
	tween.tween_property(cuerpo_ext, "scale", Vector2.ONE, 0.1).set_delay(0.05)
	if is_instance_valid(luz):
		tween.tween_property(luz, "energy", 1.0, 0.1).set_delay(0.05)
