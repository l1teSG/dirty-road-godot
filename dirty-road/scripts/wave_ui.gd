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

		_actualizar_texto_oleada(wave_manager.oleada_actual)
		_actualizar_texto_tiempo(wave_manager.tiempo_restante, wave_manager.en_descanso)


func _on_oleada_iniciada(num_oleada: int) -> void:
	_actualizar_texto_oleada(num_oleada)


func _on_descanso_iniciado(_tiempo_total: float) -> void:
	if label_oleada != null:
		label_oleada.text = "¡HORDA COMPLETADA!"


func _on_tiempo_actualizado(segundos_restantes: int, es_descanso: bool) -> void:
	_actualizar_texto_tiempo(segundos_restantes, es_descanso)


func _actualizar_texto_oleada(num_oleada: int) -> void:
	if label_oleada != null:
		label_oleada.text = "HORDA " + str(num_oleada)


func _actualizar_texto_tiempo(segundos: int, es_descanso: bool) -> void:
	if label_tiempo != null:
		if es_descanso:
			label_tiempo.text = "Siguiente horda en: " + str(segundos) + "s"
		else:
			label_tiempo.text = "Tiempo restante: " + str(segundos) + "s"
