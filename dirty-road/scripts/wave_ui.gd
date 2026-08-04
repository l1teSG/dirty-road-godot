class_name WaveUI
extends CanvasLayer

@export var label_oleada: Label
@export var label_tiempo: Label


func _ready() -> void:
	await get_tree().process_frame
	
	var wave_manager = get_tree().get_first_node_in_group("wave_manager") as WaveManager
	if wave_manager != null:
		wave_manager.tiempo_actualizado.connect(_on_tiempo_actualizado)
		wave_manager.enemigos_restantes_actualizado.connect(_on_enemigos_restantes_actualizado)


func _on_enemigos_restantes_actualizado(cantidad: int) -> void:
	if label_oleada != null:
		label_oleada.text = "Enemigos: %d" % max(0, cantidad)


func _on_tiempo_actualizado(segundos_restantes: int, _es_descanso: bool) -> void:
	if label_tiempo != null:
		label_tiempo.text = "%02d" % max(0, segundos_restantes)
