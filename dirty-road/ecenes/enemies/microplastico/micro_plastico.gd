extends enemigoNuevo

@export var speed: float = 120.0

var en_combate: bool = false

func _ready() -> void:
	tiempo_recarga = 0.6
	distancia_ataque = 45.0
	distancia_max_aggro = 300.0


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

	# Detectar si Quark está muerto
	var quark_muerto: bool = false
	if jugador != null:
		if jugador.has_method("is_dead"):
			quark_muerto = jugador.is_dead()
		elif "life" in jugador:
			quark_muerto = jugador.life <= 0
		else:
			quark_muerto = false

	# Fijación de combate: si ya estamos golpeando a Quark vivo, no cambiar objetivo
	if is_instance_valid(objetivo) and not quark_muerto:
		var dist = global_position.distance_to(objetivo.global_position)
		if dist <= distancia_ataque:
			en_combate = true
			return
		else:
			en_combate = false

	# Si Quark está muerto, ir a su punto de reaparición
	if quark_muerto:
		var spawn_nodes = get_tree().get_nodes_in_group("player_spawn")
		if spawn_nodes.size() > 0 and is_instance_valid(spawn_nodes[0]):
			objetivo = spawn_nodes[0] as Node2D
			en_combate = false
			return
		# Fallback: buscar RespawnManager
		var respawn_manager = get_tree().get_first_node_in_group("respawn_manager")
		if respawn_manager != null and respawn_manager.has_method("get_punto_respawn"):
			var punto = respawn_manager.get_punto_respawn()
			if punto != null:
				objetivo = punto
				en_combate = false
				return
		objetivo = null
		en_combate = false
		return

	# Aggro activo: perseguir a Quark si está dentro del rango máximo
	if en_aggro and jugador != null:
		var dist_j = global_position.distance_to(jugador.global_position)
		if dist_j <= distancia_max_aggro:
			objetivo = jugador
			en_combate = false
			return
		else:
			en_aggro = false

	# Prioridad base: Árbol si existe
	if arbol != null:
		objetivo = arbol
		en_combate = false
		return

	# Secundario: Quark (vivo)
	if jugador != null:
		objetivo = jugador
		en_combate = false
		return

	objetivo = null
	en_combate = false


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
