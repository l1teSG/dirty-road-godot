class_name WaveUI
extends CanvasLayer

@export var label_oleada: Label
@export var label_tiempo: Label


func _ready() -> void:
	await get_tree().process_frame
	
	var wave_manager = get_tree().get_first_node_in_group("wave_manager") as WaveManager
	if wave_manager == null:
		wave_manager = get_parent().find_child("WaveManager", true, false) as WaveManager

	if wave_manager != null:
		wave_manager.oleada_iniciada.connect(_on_oleada_iniciada)
		wave_manager.descanso_iniciado.connect(_on_descanso_iniciado)
		wave_manager.tiempo_actualizado.connect(_on_tiempo_actualizado)
		wave_manager.enemigos_restantes_actualizado.connect(_on_enemigos_restantes_actualizado)
		
		_on_oleada_iniciada(wave_manager.oleada_actual)


func _on_oleada_iniciada(num_oleada: int) -> void:
	if label_oleada != null:
		label_oleada.text = "OLEADA " + str(num_oleada)


func _on_enemigos_restantes_actualizado(cantidad: int) -> void:
	if label_oleada != null:
		var wave_manager = get_tree().get_first_node_in_group("wave_manager") as WaveManager
		if wave_manager != null and not wave_manager.en_descanso:
			# Muestra "Enemigos: X" o solo el número según prefieras
			label_oleada.text = "Enemigos: %d" % max(0, cantidad)


func _on_descanso_iniciado(_tiempo_total: float) -> void:
	if label_oleada != null:
		label_oleada.text = "¡OLEADA COMPLETADA!"


func _on_tiempo_actualizado(segundos_restantes: int, _es_descanso: bool) -> void:
	if label_tiempo != null:
		label_tiempo.text = "%02d" % max(0, segundos_restantes)
