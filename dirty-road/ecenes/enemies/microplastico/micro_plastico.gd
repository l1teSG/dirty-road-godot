extends enemigoNuevo

@export var speed: float = 120.0

func _ready() -> void:
	tiempo_recarga = 0.6
	distancia_ataque = 45.0
	distancia_max_aggro = 300.0
	tiempo_aggro = 4.0


func seleccionar_objetivo() -> void:
	var jugador: Node2D = null
	var arbol: Node2D = null

	var jugadores = get_tree().get_nodes_in_group("player")
	if jugadores.is_empty():
		jugadores = get_tree().get_nodes_in_group("jugador")
	if not jugadores.is_empty() and is_instance_valid(jugadores[0]):
		jugador = jugadores[0] as Node2D

	var arboles = get_tree().get_nodes_in_group("arbol")
	if not arboles.is_empty() and is_instance_valid(arboles[0]):
		arbol = arboles[0] as Node2D

	var dist_j: float = global_position.distance_to(jugador.global_position) if jugador else INF
	var dist_a: float = global_position.distance_to(arbol.global_position) if arbol else INF

	# 1. Si está en AGGRO (recibió un disparo de Quark) y Quark está en rango max:
	if en_aggro and jugador != null and dist_j <= distancia_max_aggro:
		objetivo = jugador
		return

	# 2. Si Quark está más cerca que el árbol (o a menos de 150px de distancia):
	if jugador != null and (dist_j < dist_a or dist_j <= 150.0):
		objetivo = jugador
		return

	# 3. De lo contrario, su objetivo predeterminado es el Árbol:
	if arbol != null:
		objetivo = arbol
		return

	objetivo = jugador


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if not is_instance_valid(objetivo):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distancia = global_position.distance_to(objetivo.global_position)
	if distancia <= distancia_ataque:
		velocity = Vector2.ZERO
	else:
		var direccion = (objetivo.global_position - global_position).normalized()
		velocity = direccion * speed

	move_and_slide()
