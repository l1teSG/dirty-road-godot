func evaluar_y_ejecutar_ataque() -> void:
	if not puede_atacar or not is_instance_valid(objetivo):
		return
	if global_position.distance_to(objetivo.global_position) > rango_disparo:
		return

	var bullet = escena_proyectil.instantiate()
	var dir_disparo: Vector2 = (objetivo.global_position - global_position).normalized()

	# 1. Agregar a la escena primero
	get_tree().current_scene.add_child(bullet)

	# 2. Asignar posición global e inyectar dirección después de estar en el árbol
	bullet.global_position = global_position + (dir_disparo * 45.0)
	
	if bullet.has_method("set_direction"):
		bullet.set_direction(dir_disparo)

	_animar_retroceso()

	puede_atacar = false
	await get_tree().create_timer(tiempo_recarga).timeout
	puede_atacar = true
