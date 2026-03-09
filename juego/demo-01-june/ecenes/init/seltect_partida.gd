extends Control
var partida = preload("res://demo/reutilizable/partida.tscn")
var texto_defecto = ["partida nueva", "estadisticas"]

#@nombre@numero"1,2,3.." primero HBoxContainer
#partidas/HBoxContainer/Button

func cambioTexto(texto, nodo): #ruta completa del nodo
	var nuevoTexto = texto
	var get_nodo = get_node(nodo)
	get_nodo.text = nuevoTexto

func _on_newgame_pressed() -> void:
	var nuevaPartida = partida.instantiate()
	$ScrollContainer/partidas.add_child(nuevaPartida)
	get_tree().change_scene_to_file("res://demo/pruebaMovimiento.tscn")
	

func guardar_partidar(partidas):
	var partida = get_children(partidas) 
