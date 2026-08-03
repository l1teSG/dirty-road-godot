extends enemigoNuevo

func seleccionar_objetivo() -> void:
	objetivo = null

func evaluar_y_ejecutar_ataque() -> void:
	# No ejecuta ningún ataque. NubeGas es completamente inofensivo.
	pass

func _physics_process(delta: float) -> void:
	# Llamamos a la animación del padre (opcional) pero no a la selección
	# de objetivo ni al ataque.
	animar_cuerpo_enemigo(delta)
	# No llamamos a super._physics_process(delta) porque eso ejecutaría
	# seleccionar_objetivo() y evaluar_y_ejecutar_ataque().
	# En su lugar, nos quedamos quietos.
	velocity = Vector2.ZERO
	move_and_slide()
