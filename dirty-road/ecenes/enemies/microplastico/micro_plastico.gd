extends enemigoNuevo

@export var speed: float = 120.0

var en_combate: bool = false
var _animando_ataque: bool = false
var _tween_ataque: Tween = null
var _ataque_animado_en_recarga: bool = false


func _ready() -> void:
	tiempo_recarga = 0.6
	distancia_ataque = 45.0
	distancia_max_aggro = 300.0


func animar_cuerpo_enemigo(delta: float) -> void:
	if _animando_ataque:
		return
	super.animar_cuerpo_enemigo(delta)


func _arbol_valido(arbol_node: Node2D) -> bool:
	if not is_instance_valid(arbol_node):
		return false
	if arbol_node.has_method("is_dead"):
		return not arbol_node.is_dead()
	var vida_actual = arbol_node.get("vida_actual")
	if vida_actual != null:
		return vida_actual > 0
	var life = arbol_node.get("life")
	if life != null:
		return life > 0
	return true


func seleccionar_objetivo() -> void:
	var jugador: Node2D = null
	var arbol: Node2D = null

	var jugadores = get_tree().get_nodes_in_group("player")
	if jugadores.is_empty():
		jugadores = get_tree().get_nodes_in_group("jugador")
	if not jugadores.is_empty() and is_instance_valid(jugadores[0]):
		jugador = jugadores[0] as Node2D

	var arboles = get_tree().get_nodes_in_group("arbol")
	var tree_exists = false
	var tree_dead = false
	if not arboles.is_empty() and is_instance_valid(arboles[0]):
		tree_exists = true
		arbol = arboles[0] as Node2D
		if not _arbol_valido(arbol):
			arbol = null
			tree_dead = true

	# Si el árbol está muerto, detener cualquier movimiento
	# (más tarde podrá reanudar si Quark está cerca o en aggro)
	if tree_dead:
		objetivo = null
		en_combate = false

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
	# (excepto si el árbol ha muerto, en ese caso se debe detener)
	if not tree_dead and is_instance_valid(objetivo) and not quark_muerto:
		var dist = global_position.distance_to(objetivo.global_position)
		if dist <= distancia_ataque:
			en_combate = true
			return
		else:
			en_combate = false

	# Si Quark está muerto: Prioridad absoluta volver al Árbol
	if quark_muerto:
		# Si el árbol está muerto, no hay a dónde ir; quedarse quieto
		if tree_dead:
			en_aggro = false
			en_combate = false
			return

		en_aggro = false
		en_combate = false

		# 1. Si el Árbol sigue en pie, atacarlo inmediatamente
		if arbol != null and _arbol_valido(arbol):
			objetivo = arbol
			return

		# 2. Si el Árbol ya fue destruido, ir al punto de respawn
		var spawn_nodes = get_tree().get_nodes_in_group("player_spawn")
		if spawn_nodes.size() > 0 and is_instance_valid(spawn_nodes[0]):
			objetivo = spawn_nodes[0] as Node2D
			return

		var respawn_manager = get_tree().get_first_node_in_group("respawn_manager")
		if respawn_manager != null and respawn_manager.has_method("get_punto_respawn"):
			var punto = respawn_manager.get_punto_respawn()
			if punto != null:
				objetivo = punto
				return

		objetivo = null
		return

	# 1. Aggro activo: perseguir a Quark si le disparó
	if en_aggro and jugador != null:
		var dist_j = global_position.distance_to(jugador.global_position)
		if dist_j <= distancia_max_aggro:
			objetivo = jugador
			en_combate = false
			return
		else:
			en_aggro = false

	# 2. Proximidad activa
	if jugador != null:
		var dist_j = global_position.distance_to(jugador.global_position)
		var dist_a = global_position.distance_to(arbol.global_position) if arbol != null else INF
		var can_target_player = false

		if tree_dead:
			# Solo atacar a Quark si está dentro del rango de proximidad o aggro
			if dist_j <= 180.0 or (en_aggro and dist_j <= distancia_max_aggro):
				can_target_player = true
		else:
			# Comportamiento normal: si está más cerca que el árbol o dentro de 180px
			if dist_j <= 180.0 or dist_j < dist_a:
				can_target_player = true

		if can_target_player:
			objetivo = jugador
			en_combate = false
			return

	# 3. Prioridad por defecto: Si Quark está lejos, marcha directo hacia el Árbol
	if arbol != null and _arbol_valido(arbol):
		objetivo = arbol
		en_combate = false
		return

	objetivo = null
	en_combate = false


func evaluar_y_ejecutar_ataque() -> void:
	# Si el cooldown ya terminó, limpiar el flag de animación usada
	if puede_atacar:
		_ataque_animado_en_recarga = false

	super.evaluar_y_ejecutar_ataque()

	# Lanzamos la animación solo una vez por cada ciclo de ataque
	if not puede_atacar and not _ataque_animado_en_recarga and is_instance_valid(objetivo):
		_ataque_animado_en_recarga = true
		animar_ataque_impactante(objetivo.global_position)


func animar_ataque_impactante(target_pos: Vector2) -> void:
	var cuerpo = $CuerpoInterior as Polygon2D
	var nucleo = $NucleoToxico as Polygon2D

	if cuerpo == null:
		return

	# Matar cualquier tween anterior que esté en medio para evitar superposiciones
	if _tween_ataque and _tween_ataque.is_valid() and _tween_ataque.is_running():
		_tween_ataque.kill()

	_animando_ataque = true

	var tween = create_tween().set_parallel(false)
	_tween_ataque = tween

	# Dirección hacia el objetivo para el impulso
	var dir = (target_pos - global_position).normalized()
	var offset_impulso = dir * 8.0 # Ligero desplazamiento hacia adelante

	# 1. Carga Casi Instantánea (30ms - Micro-compresión)
	tween.tween_property(cuerpo, "scale", Vector2(1.15, 0.85), 0.03)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Embate Explosivo + Snag (50ms - Estiramiento hacia el golpe)
	tween.chain().tween_property(cuerpo, "scale", Vector2(0.7, 1.3), 0.05)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(cuerpo, "position", offset_impulso, 0.05)

	# Flash blanco sutil en el núcleo si existe
	if nucleo != null:
		tween.parallel().tween_property(nucleo, "modulate", Color(2.5, 2.5, 2.5, 1.0), 0.02)
		tween.chain().tween_property(nucleo, "modulate", Color.WHITE, 0.04)

	# 3. Recuperación Elástica Instantánea (100ms - Rebote fluido a 1.0)
	tween.chain().tween_property(cuerpo, "scale", Vector2(1.0, 1.0), 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(cuerpo, "position", Vector2.ZERO, 0.1)

	tween.finished.connect(func():
		_animando_ataque = false
	)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Si el objetivo actual es el Árbol y ya no es válido / está sin vida,
	# lo descartamos inmediatamente.
	if is_instance_valid(objetivo) and objetivo.is_in_group("arbol"):
		if not _arbol_valido(objetivo):
			objetivo = null

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
