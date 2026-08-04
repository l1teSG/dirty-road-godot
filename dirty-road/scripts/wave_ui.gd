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
		
		if label_oleada != null:
			label_oleada.text = "HORDA " + str(wave_manager.oleada_actual)
		_actualizar_numero_tiempo(wave_manager.tiempo_restante)

func _on_oleada_iniciada(num_oleada: int) -> void:
	if label_oleada != null:
		label_oleada.text = "HORDA " + str(num_oleada)

func _on_descanso_iniciado(_tiempo_total: float) -> void:
	if label_oleada != null:
		label_oleada.text = "¡COMPLETADA!"

func _on_tiempo_actualizado(segundos_restantes: int, _es_descanso: bool) -> void:
	_actualizar_numero_tiempo(segundos_restantes)

func _actualizar_numero_tiempo(segundos: int) -> void:
	if label_tiempo != null:
		# Muestra solo números limpios de dos dígitos (ej. 30, 08, 05)
		label_tiempo.text = "%02d" % max(0, segundos)
