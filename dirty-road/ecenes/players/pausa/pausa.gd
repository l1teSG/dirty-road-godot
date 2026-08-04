extends CanvasLayer

func _on_button_button_down() -> void:
	# Continuar: Desvanecimiento suave deslizándose hacia abajo (1.0 segundo)
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_property($Contenedor, "modulate:a", 0.0, 1.0)
	tween.tween_property($Contenedor, "position:y", $Contenedor.position.y + 60, 1.0)
	
	await tween.finished
	
	self.visible = false
	# Restaurar valores originales para la próxima vez que se abra la pausa
	$Contenedor.modulate.a = 1.0
	$Contenedor.position.y -= 60


func _on_nueva_partida_button_down() -> void:
	# 1. Despausar el juego
	get_tree().paused = false
	# 2. Resetear SaveManager (memoria + disco)
	SaveManager.nueva_partida()
	# (Opcional) Deslizamiento suave hacia la derecha con desvanecimiento (1.0 segundo)
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	tween.tween_property($Contenedor, "modulate:a", 0.0, 1.0)
	tween.tween_property($Contenedor, "position:x", $Contenedor.position.x + 150, 1.0)
	
	await tween.finished
	
	# 3. Recargar la escena actual de forma limpia
	get_tree().reload_current_scene()


func _on_salir_button_down() -> void:
	# Salir: Deslizamiento suave hacia la izquierda con desvanecimiento (1.0 segundo)
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	tween.tween_property($Contenedor, "modulate:a", 0.0, 1.0)
	tween.tween_property($Contenedor, "position:x", $Contenedor.position.x - 150, 1.0)
	
	await tween.finished
	
	get_tree().change_scene_to_file('res://ui/main/main.tscn')
