class_name WaveUI
extends CanvasLayer

@export var label_enemigo: Label
@export var label_tiempo: Label

## Opcionales: si los dejas vacíos no pasa nada
@export var label_oleada: Label
@export var label_etapa: Label
@export var label_jefe: Label

var _texto_oleada: String = ""
var _enemigos_restantes: int = 0


func _ready() -> void:
	await get_tree().process_frame

	var wave_manager = get_tree().get_first_node_in_group("wave_manager") as WaveManager
	if wave_manager == null:
		return

	wave_manager.tiempo_actualizado.connect(_on_tiempo_actualizado)
	wave_manager.enemigos_restantes_actualizado.connect(_on_enemigos_restantes_actualizado)
	wave_manager.oleada_iniciada.connect(_on_oleada_iniciada)
	wave_manager.etapa_iniciada.connect(_on_etapa_iniciada)
	wave_manager.jefe_aparecido.connect(_on_jefe_aparecido)
	wave_manager.jefe_derrotado.connect(_on_jefe_muerto)

	# La primera oleada/etapa se emitió antes de que la UI conectara: recupera estado.
	_on_oleada_iniciada(wave_manager.obtener_oleada_actual())
	_on_enemigos_restantes_actualizado(wave_manager.obtener_enemigos_restantes())

	var idx: int = wave_manager.obtener_etapa_actual()
	if idx >= 0 and idx < wave_manager.etapas.size() and wave_manager.etapas[idx] != null:
		_on_etapa_iniciada(idx, wave_manager.etapas[idx].nombre)


# ── Handlers de señales ──────────────────────────────────────────────

func _on_oleada_iniciada(numero_oleada: int) -> void:
	_texto_oleada = "Oleada %d" % numero_oleada
	_refrescar_label_oleada()


func _on_enemigos_restantes_actualizado(cantidad: int) -> void:
	_enemigos_restantes = maxi(cantidad, 0)

	if label_enemigo != null:
		label_enemigo.text = "Enemigos: %d" % _enemigos_restantes
	else:
		_refrescar_label_oleada()


func _on_etapa_iniciada(_indice: int, nombre: String) -> void:
	if label_etapa != null:
		label_etapa.text = nombre


func _on_tiempo_actualizado(segundos_restantes: int, es_descanso: bool) -> void:
	if label_tiempo != null:
		if es_descanso:
			label_tiempo.text = "Descanso: %d" % maxi(0, segundos_restantes)
		else:
			label_tiempo.text = "%02d" % maxi(0, segundos_restantes)


func _on_jefe_aparecido(_jefe: Node2D, nombre: String) -> void:
	if label_jefe != null:
		label_jefe.text = "¡%s!" % nombre
		label_jefe.visible = true


func _on_jefe_muerto(_nombre: String) -> void:
	if label_jefe != null:
		label_jefe.visible = false


# ── Helpers ──────────────────────────────────────────────────────────

func _refrescar_label_oleada() -> void:
	if label_oleada != null:
		label_oleada.text = _texto_oleada
	elif label_enemigo != null and _texto_oleada != "":
		# Sin label dedicado para la oleada, se combinan en el mismo label.
		label_enemigo.text = "%s | Enemigos: %d" % [_texto_oleada, _enemigos_restantes]
