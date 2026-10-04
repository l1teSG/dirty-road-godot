extends CanvasLayer


func _on_button_button_down() -> void:
	# Continuar: desvanecimiento deslizándose hacia abajo (1.0 s)
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($Contenedor, "modulate:a", 0.0, 1.0)
	tween.tween_property($Contenedor, "position:y", $Contenedor.position.y + 60, 1.0)

	await tween.finished

	self.visible = false
	# Restaurar valores originales para la próxima vez que se abra la pausa
	$Contenedor.modulate.a = 1.0
	$Contenedor.position.y -= 60

	# Reanudar la partida al final, cuando el menú ya se fue.
	# (Si tu script del jugador ya despausa con Esc, esta línea no estorba.)
	get_tree().paused = false


func _on_nueva_partida_button_down() -> void:
	# 1. Resetear SaveManager (memoria + disco) con el juego AÚN CONGELADO.
	#    Así el WaveManager de la partida vieja no puede volver a guardar
	#    la horda durante la animación (ese era el hueco del bug).
	SaveManager.nueva_partida()

	# 2. Animación de salida. TWEEN_PAUSE_PROCESS hace que corra aunque
	#    el árbol siga pausado, así no hace falta despausar antes de tiempo.
	var tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property($Contenedor, "modulate:a", 0.0, 1.0)
	tween.tween_property($Contenedor, "position:x", $Contenedor.position.x + 150, 1.0)

	await tween.finished

	# 3. Despausar y recargar en el mismo frame: sin ventana para saves fantasma
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_salir_button_down() -> void:
	# Salir: deslizamiento hacia la izquierda con desvanecimiento (1.0 s)
	var tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property($Contenedor, "modulate:a", 0.0, 1.0)
	tween.tween_property($Contenedor, "position:x", $Contenedor.position.x - 150, 1.0)

	await tween.finished

	# Salir NO borra la partida (querés poder "Continuar" desde el menú);
	# solo despausa antes de cambiar de escena para que el menú no cargue congelado.
	get_tree().paused = false
	get_tree().change_scene_to_file('res://ui/main/main.tscn')
