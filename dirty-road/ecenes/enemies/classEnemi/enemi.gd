class_name enemigoNuevo
extends CharacterBody2D

var tiempo_anim: float = randf() * 10.0
var life: int = 30  # ajusta a la vida que quieras

# ── Parámetros de Ataque y Aggro (editable desde Inspector) ──
@export_category("Parámetros de Ataque y Aggro")
@export var distancia_ataque: float = 100.0
@export var danio_ataque: int = 10
@export var tiempo_recarga: float = 1.5
@export var tiempo_aggro: float = 4.0

# ── Control interno ───────────────────────────────────
var puede_atacar: bool = true
var en_aggro: bool = false
var objetivo: Node2D = null


func animar_cuerpo_enemigo(delta: float) -> void:
	var cuerpo_int = $CuerpoInterior as Polygon2D
	var nucleo = $NucleoToxico as Polygon2D

	if cuerpo_int == null:
		return

	tiempo_anim += delta * 8.0

	var deformacion = sin(tiempo_anim) * 0.06
	cuerpo_int.scale.x = 0.8 + deformacion
	cuerpo_int.scale.y = 0.8 - deformacion

	if nucleo != null:
		nucleo.rotation += delta * 2.0


func _physics_process(delta: float) -> void:
	animar_cuerpo_enemigo(delta)
	seleccionar_objetivo()
	evaluar_y_ejecutar_ataque()


func take_hit(damage: int = 10) -> void:
	recibir_danio(damage)


# ── Recepción de daño (con aggro) ────────────────────────

func recibir_danio(cantidad: int, atacante: Node2D = null) -> void:
	# Aggro: si el atacante es el jugador o un proyectil, entra en modo aggro
	if atacante != null and (atacante.is_in_group("player") or atacante.is_in_group("bullet")):
		en_aggro = true
		# Iniciar temporizador asíncrono para desactivar aggro
		await get_tree().create_timer(tiempo_aggro).timeout
		en_aggro = false

	life -= cantidad
	if life <= 0:
		var label = get_tree().current_scene.find_child("TextoBiomasa", true, false)
		if label:
			# Llamada original de take_hit (ajusta según tu implementación de BiomasaManager)
			BiomasaManager.emitir_biomasa(
				global_position,
				label.global_position,
				label.get_node("/root").find_child("ui", true, false)
			)
		self.queue_free()


# ── Búsqueda dinámica de objetivos ─────────────────────

func seleccionar_objetivo() -> void:
	# Aggro: si está en modo aggro y el jugador está dentro del rango de detección,
	# lo fija como objetivo inmediato (ignora la prioridad habitual).
	if en_aggro:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0 and is_instance_valid(players[0]):
			var player = players[0] as Node2D
			if global_position.distance_to(player.global_position) <= distancia_ataque:
				objetivo = player
				return

	var jugador: Node2D = null
	var arbol: Node2D = null

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		jugador = players[0] as Node2D

	var arboles = get_tree().get_nodes_in_group("arbol")
	if arboles.size() > 0 and is_instance_valid(arboles[0]):
		arbol = arboles[0] as Node2D

	# Seleccionar el objetivo más cercano (dentro de distancia_ataque)
	var closest: Node2D = null
	var min_dist: float = INF
	if jugador != null:
		var d = global_position.distance_to(jugador.global_position)
		if d <= distancia_ataque and d < min_dist:
			closest = jugador
			min_dist = d
	if arbol != null:
		var d = global_position.distance_to(arbol.global_position)
		if d <= distancia_ataque and d < min_dist:
			closest = arbol
			min_dist = d
	objetivo = closest


# ── Método principal de ataque ────────────────────────

func evaluar_y_ejecutar_ataque() -> void:
	if not is_instance_valid(objetivo):
		return

	if not puede_atacar:
		return

	var distancia = global_position.distance_to(objetivo.global_position)
	if distancia > distancia_ataque:
		return

	# Ejecutar ataque según el tipo de objetivo
	if objetivo.has_method("take_damage"):
		objetivo.take_damage(danio_ataque)
	elif objetivo.has_method("recibir_danio"):
		objetivo.recibir_danio(danio_ataque)

	# Iniciar recarga
	puede_atacar = false
	await get_tree().create_timer(tiempo_recarga).timeout
	puede_atacar = true
