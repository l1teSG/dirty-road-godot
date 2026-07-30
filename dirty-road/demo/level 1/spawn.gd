extends Marker2D

var enemigo = preload('res://assets/stage/elDespertarDeLasMaquinas/enemies/Carbonilla/shapeCarbonilla.tscn')


func _on_timer_timeout() -> void:
	var instanciaEnemigo = enemigo.instantiate()
	instanciaEnemigo.global_position = self.global_position
	instanciaEnemigo.add_to_group('enemi')
	get_tree().current_scene.add_child(instanciaEnemigo)
