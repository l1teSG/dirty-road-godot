extends Marker2D

var enemi = preload('res://assets/stage/elDespertarDeLasMaquinas/enemies/Carbonilla/shapeCarbonilla.tscn')

func _on_timer_timeout() -> void:
	var enemiInstancia = enemi.instantiate()
	enemiInstancia.global_position = self.global_position
	enemiInstancia.add_to_group('enemi')
	get_tree().current_scene.add_child(enemiInstancia)
