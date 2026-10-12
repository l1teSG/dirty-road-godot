extends Node2D

@onready var fondo_negro: ColorRect = $CanvasLayer/ColorRect
@onready var texto_horda: Label = $CanvasLayer/TextoHorda

var _vineta: TextureRect = null
var _tween_vineta: Tween = null
var _puerta: Puerta = null
var _transicionando: bool = false

var horda_actual: int = 1

const DURACION_FADE_ENTRADA := 1.0
const ESPERA_ANTES_DE_TEXTO := 0.5
const DURACION_ENTRADA_TEXTO := 0.8
const TIEMPO_VISIBLE_TEXTO := 1.6
const DURACION_SALIDA_TEXTO := 1.0
const DESPLAZAMIENTO_TEXTO := 20.0

# Duración completa de una animación de mensaje (entrada + espera + salida)
const DURACION_MENSAJE_COMPLETO := DURACION_ENTRADA_TEXTO + TIEMPO_VISIBLE_TEXTO + DURACION_SALIDA_TEXTO

## Tope de espera del cartel "HORDA" para no pisar el popup educativo.
const TIEMPO_MAX_ESPERA_HORDA := 20.0

var tween_actual: Tween


func _ready() -> void:
	EducationManager.set_data({
		"general": EducationDataGeneral.get_data(),
		"stages": EducationDataStages.get_data()
	})
	EducationManager.start_run()
	EducationManager.on_stage_started(0)
	horda_actual = SaveManager.get_horda() if SaveManager else 1
	_iniciar_transicion_entrada()

	# Conectar señales con WaveManager
	await get_tree().process_frame
	var wave_manager = get_tree().get_first_node_in_group("wave_manager") as WaveManager
	if wave_manager != null:
		wave_manager.oleada_iniciada.connect(_on_oleada_iniciada)
		wave_manager.descanso_iniciado.connect(_on_descanso_iniciado)
		wave_manager.etapa_completada.connect(_on_etapa_completada)

	# Derrota: si el árbol es destruido, Game Over.
	var arbol := get_tree().get_first_node_in_group("arbol")
	if arbol != null and arbol.has_signal("arbol_destruido"):
		arbol.arbol_destruido.connect(_on_arbol_destruido)
	# Viñeta roja cuando el árbol recibe un golpe.
	_vineta = get_node_or_null("viñeta/TextureRect") as TextureRect
	if arbol != null and arbol.has_signal("golpe_recibido") and _vineta != null:
		arbol.golpe_recibido.connect(_on_golpe_arbol)


func _on_golpe_arbol(cantidad: float) -> void:
	if _vineta == null:
		return
	var fuerza := clampf(cantidad / 40.0, 0.2, 1.0)
	if _tween_vineta != null and _tween_vineta.is_valid():
		_tween_vineta.kill()
	_vineta.modulate = Color(1.0, 0.35, 0.35, fuerza)
	_tween_vineta = create_tween()
	_tween_vineta.tween_property(_vineta, "modulate", Color.WHITE, 0.35)


func _on_arbol_destruido() -> void:
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://ui/dead/dead.tscn")


# ── Puerta de etapa (transición al siguiente escenario) ──────────────

func _on_etapa_completada(_indice: int) -> void:
	_mostrar_puerta()


func _mostrar_puerta() -> void:
	if _puerta != null and is_instance_valid(_puerta):
		_puerta.queue_free()
	_puerta = Puerta.new()
	_puerta.name = "Puerta"
	add_child(_puerta)
	_puerta.global_position = Vector2(560, 0)
	var gestor := get_node_or_null("GestorEtapa")
	if gestor != null:
		var tema = gestor.get("_tema")
		if tema != null:
			_puerta.color = tema.get("banner_color")
	_puerta.cruzada.connect(_on_puerta_cruzada)
	_puerta.abrir()
	mostrar_mensaje("ENTRA POR LA PUERTA")


func _on_puerta_cruzada() -> void:
	if _transicionando:
		return
	_transicionando = true
	await _fade(1.0, 0.5)
	# La base se muda: árbol al centro, jugador al lado opuesto de la puerta.
	var arbol := get_tree().get_first_node_in_group("arbol")
	if arbol != null and arbol.has_method("reubicar"):
		arbol.call("reubicar", Vector2.ZERO)
	var jug := get_tree().get_first_node_in_group("jugador")
	if jug != null and jug is Node2D:
		(jug as Node2D).global_position = Vector2(-560, 0)
	if _puerta != null and is_instance_valid(_puerta):
		_puerta.queue_free()
		_puerta = null
	# Reanuda: arranca la nueva etapa; el GestorEtapa regenera terreno+ambiente.
	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm != null and wm.has_method("continuar_tras_puerta"):
		wm.call("continuar_tras_puerta")
	await _fade(0.0, 0.6)
	_transicionando = false


func _fade(alpha: float, dur: float) -> void:
	if fondo_negro == null:
		return
	fondo_negro.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(fondo_negro, "color:a", alpha, dur)
	await tw.finished
	if alpha <= 0.01:
		fondo_negro.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ── Transición de entrada al nivel (fade desde negro) ──────────────

func _iniciar_transicion_entrada() -> void:
	if fondo_negro == null:
		push_warning("Nivel: no se encontró el ColorRect de transición")
		mostrar_mensaje("CUIDA EL ÁRBOL")
		return

	fondo_negro.color.a = 1.0
	fondo_negro.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween = create_tween()
	tween.tween_property(fondo_negro, "color:a", 0.0, DURACION_FADE_ENTRADA)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		fondo_negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
	tween.tween_interval(ESPERA_ANTES_DE_TEXTO)
	tween.tween_callback(func():
		mostrar_mensaje("CUIDA EL ÁRBOL")
	)
	tween.tween_interval(DURACION_MENSAJE_COMPLETO)
	tween.tween_callback(func():
		_mostrar_horda(horda_actual)
	)


# ── Handlers de Señales de WaveManager ────────────────────────────────

func _on_oleada_iniciada(num_oleada: int) -> void:
	horda_actual = num_oleada
	_mostrar_horda(horda_actual)


## Muestra el cartel "HORDA N" DESPUÉS de que termine el popup educativo
## (p. ej. "ETAPA 1"), para que los mensajes no aparezcan a la vez.
func _mostrar_horda(num: int) -> void:
	if SaveManager != null and not bool(SaveManager.get_ajuste("mostrar_cartel_horda", true)):
		return
	var t0 := Time.get_ticks_msec()
	while is_inside_tree() and EducationManager != null and EducationManager.esta_mostrando():
		if (Time.get_ticks_msec() - t0) / 1000.0 >= TIEMPO_MAX_ESPERA_HORDA:
			break
		await get_tree().process_frame
	if not is_inside_tree():
		return
	mostrar_mensaje("HORDA %d" % num)


func _on_descanso_iniciado(_tiempo_total: float) -> void:
	mostrar_mensaje("¡OLEADA COMPLETADA!")


# ── Lógica de Animación Unificada ────────────────────────────────────

func mostrar_mensaje(texto: String) -> void:
	if texto_horda == null:
		return

	# Cancelar animación previa si existía
	if tween_actual != null and tween_actual.is_running():
		tween_actual.kill()

	texto_horda.text = texto

	# Configurar anclajes al centro de la pantalla
	texto_horda.anchors_preset = Control.PRESET_CENTER
	texto_horda.grow_horizontal = Control.GROW_DIRECTION_BOTH
	texto_horda.grow_vertical = Control.GROW_DIRECTION_BOTH

	await get_tree().process_frame

	# Fijar pivote en el centro exacto del Label
	texto_horda.pivot_offset = texto_horda.size / 2.0

	# Estado inicial de la animación
	texto_horda.modulate.a = 0.0
	texto_horda.scale = Vector2(0.9, 0.9)

	# Posición centrada base
	var pos_centro: Vector2 = (get_viewport_rect().size / 2.0) - (texto_horda.size / 2.0)
	texto_horda.position = pos_centro - Vector2(0, DESPLAZAMIENTO_TEXTO)

	# Secuencia de animación en pantalla
	tween_actual = create_tween()

	# Entrada: Fade in + Zoom + Desplazamiento al centro exacto
	tween_actual.set_parallel(true)
	tween_actual.tween_property(texto_horda, "modulate:a", 1.0, DURACION_ENTRADA_TEXTO)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_actual.tween_property(texto_horda, "scale", Vector2.ONE, DURACION_ENTRADA_TEXTO)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_actual.tween_property(texto_horda, "position", pos_centro, DURACION_ENTRADA_TEXTO)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Mantener visible
	tween_actual.chain().tween_interval(TIEMPO_VISIBLE_TEXTO)

	# Salida: Fade out + Flotación leve hacia arriba
	tween_actual.chain().set_parallel(true)
	tween_actual.tween_property(texto_horda, "modulate:a", 0.0, DURACION_SALIDA_TEXTO)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween_actual.tween_property(texto_horda, "position", pos_centro + Vector2(0, -15.0), DURACION_SALIDA_TEXTO)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
