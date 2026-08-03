extends CanvasLayer


func _on_nueva_partida_button_down() -> void:
	get_tree().change_scene_to_file('res://demo/level 1/niviel1.tscn')


func _on_salir_button_down() -> void:
	get_tree().change_scene_to_file('res://ui/main/main.tscn')
