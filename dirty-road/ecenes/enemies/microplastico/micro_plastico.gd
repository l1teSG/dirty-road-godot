extends enemigoNuevo

@export var speed: float = 100.0

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
