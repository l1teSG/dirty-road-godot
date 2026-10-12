class_name WaveUI
extends CanvasLayer

## ══════════════════════════════════════════════════════════
##  WAVE UI — HUD de oleadas conectado al WaveManager actual.
##  • Lee el estado PÚBLICO del manager (oleada_actual,
##    enemigos_vivos, etapa_actual_idx, jefe_actual): no usa
##    getters, así que wave_manager.gd no necesita cambios.
##  • La oleada de JEFE no tiene reloj: mientras el jefe viva, el label de
##    tiempo se OCULTA (el nombre del jefe vive en la BarraJefe).
## ══════════════════════════════════════════════════════════

@export_category("Referencias")
@export var label_enemigo: Label
@export var label_tiempo: Label
## Opcionales: si los dejas vacíos no pasa nada
@export var label_oleada: Label
@export var label_etapa: Label
@export var label_jefe: Label

@export_category("Tema (opcional)")
## Pinta los labels con la paleta del juego (verde neón / magenta).
@export var usar_colores_personalizados: bool = false
@export var color_texto: Color = Color("00ff7f")
@export var color_jefe: Color = Color("d81b60")

var _texto_oleada: String = ""
var _enemigos_restantes: int = 0
## Mientras el jefe esté vivo no hay reloj de oleada que mostrar.
var _jefe_en_pantalla: bool = false


func _ready() -> void:
	await get_tree().process_frame

	var wave_manager := get_tree().get_first_node_in_group("wave_manager") as WaveManager
	if wave_manager == null:
		return

	wave_manager.tiempo_actualizado.connect(_on_tiempo_actualizado)
	wave_manager.enemigos_restantes_actualizado.connect(_on_enemigos_restantes_actualizado)
	wave_manager.oleada_iniciada.connect(_on_oleada_iniciada)
	wave_manager.etapa_iniciada.connect(_on_etapa_iniciada)
	wave_manager.jefe_aparecido.connect(_on_jefe_aparecido)
	wave_manager.jefe_derrotado.connect(_on_jefe_muerto)

	_aplicar_tema()

	# La primera oleada/etapa se emitió antes de que la UI conectara
	# (el manager arranca con call_deferred): recupera el estado.
	_on_oleada_iniciada(wave_manager.oleada_actual)
	_on_enemigos_restantes_actualizado(
		wave_manager.enemigos_vivos + wave_manager.enemigos_por_spawnear)

	var idx: int = wave_manager.etapa_actual_idx
	if idx >= 0 and idx < wave_manager.etapas.size() and wave_manager.etapas[idx] != null:
		var nombre: Variant = wave_manager.etapas[idx].get("nombre")
		if nombre != null and not String(nombre).is_empty():
			_on_etapa_iniciada(idx, String(nombre))
		else:
			_on_etapa_iniciada(idx, "Etapa %d" % (idx + 1))

	# Si la partida arrancó directo en una oleada de jefe (debug),
	# recupera también ese estado.
	if wave_manager.jefe_actual != null:
		_jefe_en_pantalla = true
		if label_tiempo != null:
			label_tiempo.visible = false


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
	if label_tiempo == null:
		return
	if _jefe_en_pantalla:
		# Oleada de jefe: se OCULTA el contador (sin guion).
		label_tiempo.visible = false
		return
	label_tiempo.visible = true
	if es_descanso:
		label_tiempo.text = "Descanso: %d" % maxi(0, segundos_restantes)
	else:
		label_tiempo.text = "%02d" % maxi(0, segundos_restantes)


## El nombre del jefe ahora vive dentro de la BarraJefe: aquí no se usa.
func _on_jefe_aparecido(_jefe: Node2D, _nombre: String) -> void:
	_jefe_en_pantalla = true
	if label_tiempo != null:
		label_tiempo.visible = false


func _on_jefe_muerto(_nombre: String) -> void:
	_jefe_en_pantalla = false
	if label_tiempo != null:
		label_tiempo.visible = true


# ── Helpers ──────────────────────────────────────────────────────────

func _refrescar_label_oleada() -> void:
	if label_oleada != null:
		label_oleada.text = _texto_oleada
	elif label_enemigo != null and _texto_oleada != "":
		# Sin label dedicado para la oleada, se combinan en el mismo label.
		label_enemigo.text = "%s | Enemigos: %d" % [_texto_oleada, _enemigos_restantes]


func _aplicar_tema() -> void:
	if not usar_colores_personalizados:
		return
	if label_enemigo != null:
		label_enemigo.add_theme_color_override("font_color", color_texto)
	if label_tiempo != null:
		label_tiempo.add_theme_color_override("font_color", color_texto)
	if label_oleada != null:
		label_oleada.add_theme_color_override("font_color", color_texto)
	if label_etapa != null:
		label_etapa.add_theme_color_override("font_color", color_texto)
	if label_jefe != null:
		label_jefe.add_theme_color_override("font_color", color_jefe)
