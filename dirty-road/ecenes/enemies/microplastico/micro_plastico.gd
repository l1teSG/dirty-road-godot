extends enemigoNuevo

@export var speed: float = 130.0

func _ready() -> void:
	tiempo_recarga = 0.5
	distancia_ataque = 45.0

func seleccionar_objetivo() -> void:
	var jugadores = get_tree().get_nodes_in_group("player")
	if jugadores.is_empty():
		jugadores = get_tree().get_nodes_in_group("jugador")

	if not jugadores.is_empty() and is_instance_valid(jugadores[0]):
		objetivo = jugadores[0] as Node2D
	else:
		objetivo = null

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
