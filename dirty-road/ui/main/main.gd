extends Control


func _on_exit_button_down() -> void:
	get_tree().quit()


func _on_play_button_down() -> void:
	get_tree().change_scene_to_file('res://ui/matchSelector/matchSelector.tscn')
