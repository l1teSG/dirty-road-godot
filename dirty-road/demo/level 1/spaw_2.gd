extends Marker2D
var enemi = preload('res://ecenes/enemies/firstStage/ignis/ignis.tscn')

func _on_timer_timeout() -> void:
	var enemigo = enemi.instantiate()
	enemigo.global_position = self.global_position
	enemigo.add_to_group('enemi')
	
	get_tree().current_scene.add_child(enemigo)
