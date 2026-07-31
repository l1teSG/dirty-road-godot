extends Marker2D

var enemimo  = preload("res://ecenes/enemies/firstStage/carbonilla/carbonilla.tscn")


func _on_timer_timeout() -> void:
	var enemigoInstancia = enemimo.instantiate()
	enemigoInstancia.add_to_group('enemi')
	enemigoInstancia.global_position = self.global_position
	get_tree().current_scene.add_child(enemigoInstancia)
