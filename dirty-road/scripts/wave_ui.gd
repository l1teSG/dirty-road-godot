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
		
		# Inicializar la UI con los valores actuales
		_actualizar_numero_tiempo(wave_manager.tiempo_restante)
		_on_enemigos_restantes_actualizado(wave_manager.obtener_enemigos_restantes())


func _on_oleada_iniciada(num_oleada: int) -> void:
	# No actualizamos el texto aquí porque la señal enemigos_restantes_actualizado
	# se encargará de mostrar el número de enemigos restantes (incluyendo la oleada actual)
	pass


func _on_descanso_iniciado(_tiempo_total: float) -> void:
	if label_oleada != null:
		label_oleada.text = "0"


func _on_tiempo_actualizado(segundos_restantes: int, _es_descanso: bool) -> void:
	_actualizar_numero_tiempo(segundos_restantes)


func _on_enemigos_restantes_actualizado(cantidad: int) -> void:
	if label_oleada != null:
		label_oleada.text = "%d" % max(0, cantidad)


func _actualizar_numero_tiempo(segundos: int) -> void:
	if label_tiempo != null:
		# Muestra solo números limpios de dos dígitos (ej. 30, 08, 05)
		label_tiempo.text = "%02d" % max(0, segundos)
