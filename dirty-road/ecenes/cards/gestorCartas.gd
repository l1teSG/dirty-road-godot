class_name GestorCartas
extends CanvasLayer

signal mejora_comprada(id_mejora: String)

## Fuente base de nombre / rareza / precio (script sin class_name → preload).
const CATALOGO_CARDS := preload("res://assets/cards/catalogoCards.gd")
const CONFIRMACION := preload("res://ui/confirmacion.gd")

@export_category("Referencias")
@export var constructor: ConstructorCartas
@export var contenedor_visual: HBoxContainer
@export var wave_manager: Node2D

@export_category("Configuración")
## Toda la configuración de las cartas (también editable en el .tres).
@export var config: CartasConfig

@export_category("Depuración")
## Imprime el flujo de las cartas en consola.
@export var debug: bool = true

var _boton_saltar: Button
var _contenido: Control
var _biomasa_label: Label
var _cerrando: bool = false
var _pool: Array[InfoMejora] = []
var _confirm = null
var _pendiente: InfoMejora = null

func _ready() -> void:
	add_to_group("cartas")
	hide()

	if config == null:
		config = CartasConfig.new()

	_build_ui()

	# Modal de confirmación de compra (ajuste "confirmar_compra").
	_confirm = CONFIRMACION.new()
	add_child(_confirm)
	_confirm.confirmado.connect(_on_compra_confirmada)

	if BiomasaManager != null and not BiomasaManager.biomasa_incrementada.is_connected(_on_biomasa_ui):
		BiomasaManager.biomasa_incrementada.connect(_on_biomasa_ui)
	_refrescar_biomasa_ui()

	_pool = _construir_pool()
	_log("Pool listo: %d cartas." % _pool.size())

	_conectar_wave_manager.call_deferred()

	# Si el jugador muere mientras hay cartas abiertas, se cierran.
	var dueno := get_parent()
	if dueno != null and dueno.has_signal("died"):
		dueno.connect("died", _cerrar_interfaz)


## Busca el WaveManager por grupo y conecta sus señales (en diferido).
func _conectar_wave_manager() -> void:
	if wave_manager == null or not is_instance_valid(wave_manager):
		wave_manager = get_tree().get_first_node_in_group("wave_manager")

	if wave_manager == null:
		push_warning("[GestorCartas] No encontré el WaveManager (grupo 'wave_manager'). Las cartas NO aparecerán.")
		return

	if not wave_manager.descanso_iniciado.is_connected(_on_descanso_iniciado):
		wave_manager.descanso_iniciado.connect(_on_descanso_iniciado)
	if not wave_manager.oleada_iniciada.is_connected(_on_oleada_iniciada):
		wave_manager.oleada_iniciada.connect(_on_oleada_iniciada)
	_log("Conectado al WaveManager '%s'." % wave_manager.name)


func _log(msg: String) -> void:
	if debug:
		print("[GestorCartas] ", msg)

# ── UI ─────────────────────────────────────────────────────────────────────

## Construye la interfaz de cartas (fondo oscurecido + título + fila + LISTO).
func _build_ui() -> void:
	if constructor == null:
		constructor = ConstructorCartas.new()
		constructor.name = "ConstructorCartas"
		add_child(constructor)

	if contenedor_visual != null:
		return

	var dim := ColorRect.new()
	dim.name = "Fondo"
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var centro := CenterContainer.new()
	centro.name = "Centro"
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(centro)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", config.sep_vertical)
	centro.add_child(vbox)
	_contenido = vbox

	var titulo := Label.new()
	titulo.text = "ELIGE UNA MEJORA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", config.fuente_titulo)
	titulo.add_theme_font_size_override("font_size", config.tam_titulo)
	titulo.add_theme_color_override("font_color", Color(0.6, 1.0, 0.2))
	vbox.add_child(titulo)

	# Biomasa actual: el gasto de las cartas debe verse aquí (el HUD del
	# jugador queda tapado por esta pantalla).
	_biomasa_label = Label.new()
	_biomasa_label.name = "BiomasaCartas"
	_biomasa_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_biomasa_label.add_theme_font_override("font", config.fuente_boton)
	_biomasa_label.add_theme_font_size_override("font_size", config.tam_titulo)
	_biomasa_label.add_theme_color_override("font_color", Color("ffdd55"))
	vbox.add_child(_biomasa_label)

	var fila := HBoxContainer.new()
	fila.name = "Cartas"
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", config.sep_cartas)
	vbox.add_child(fila)

	contenedor_visual = fila

	_boton_saltar = Button.new()
	_boton_saltar.name = "Listo"
	_boton_saltar.text = "LISTO"
	_boton_saltar.custom_minimum_size = Vector2(240, 62)
	_boton_saltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_boton_saltar.add_theme_font_override("font", config.fuente_boton)
	_boton_saltar.add_theme_font_size_override("font_size", config.tam_boton)
	_boton_saltar.pressed.connect(_on_listo_presionado)
	_estilizar_saltar()
	vbox.add_child(_boton_saltar)


func _estilizar_saltar() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("101d18")
	normal.set_corner_radius_all(8)
	normal.set_border_width_all(2)
	normal.border_color = Color(0.45, 0.5, 0.48)

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.10, 0.20, 0.16)
	hover.border_color = Color("99ff33")

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(0.10, 0.28, 0.22)

	_boton_saltar.add_theme_stylebox_override("normal", normal)
	_boton_saltar.add_theme_stylebox_override("hover", hover)
	_boton_saltar.add_theme_stylebox_override("pressed", pressed)
	_boton_saltar.add_theme_color_override("font_color", Color("cfd8d3"))
	_boton_saltar.add_theme_color_override("font_hover_color", Color("99ff33"))

# ── Construcción del pool ─────────────────────────────────────────────────

func _construir_pool() -> Array[InfoMejora]:
	var descs: Dictionary = DescripcionesCartas.get_datos()
	var figs: Dictionary = FigurasCartas.get_datos()
	var pool: Array[InfoMejora] = []

	for entrada in CATALOGO_CARDS.CATALOGO:
		var nombre: String = str(entrada.get("nombre", ""))
		if nombre.is_empty():
			continue

		var info := InfoMejora.new()
		info.id = _slug(nombre)
		info.nombre = nombre
		info.rareza = str(entrada.get("rareza", "Común"))
		info.costo_orbes = config.costo_de(info.rareza)
		info.descripcion = str(descs.get(nombre, ""))
		info.figura_texto = str(figs.get(nombre, ""))
		info.peso_aparicion = config.peso_de(info.rareza)
		pool.append(info)

	return pool

## 'Bicicleta Ecológica' → 'bicicletaecologica' (id estable, sin tildes).
func _slug(texto: String) -> String:
	var t := texto.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"]]:
		t = t.replace(par[0], par[1])

	var out := ""
	for c in t:
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c

	return out

# ── Flujo de descanso ─────────────────────────────────────────────────────

func _on_descanso_iniciado(_tiempo_total: float) -> void:
	# El descanso NO se pausa: el tiempo sigue corriendo.
	if not _toca_mostrar_cartas():
		_log("Descanso sin cartas (cadencia/gating).")
		return
	_mostrar_con_retraso.call_deferred()

## ¿Toca ofrecer cartas en este descanso? (cadencia + min_oleada).
func _toca_mostrar_cartas() -> bool:
	return hay_cartas_en(_oleada_completada())


## Público: ¿la oleada indicada ofrece cartas? Lo consulta el WaveManager para
## decidir la duración del descanso (corto sin cartas, largo con cartas).
func hay_cartas_en(oleada_completada: int) -> bool:
	if oleada_completada < config.min_oleada:
		return false
	if config.mostrar_cada_n_oleadas <= 1:
		return true
	return oleada_completada % config.mostrar_cada_n_oleadas == 0

## Nº de la última oleada completada (el WaveManager ya incrementó).
func _oleada_completada() -> int:
	if wave_manager == null:
		return 1
	return maxi(int(wave_manager.get("oleada_actual")) - 1, 1)

func _on_oleada_iniciada(_num: int) -> void:
	_log("oleada_iniciada (%d). Cerrando cartas." % _num)
	_cerrar_interfaz()

func _mostrar_con_retraso() -> void:
	if config.retraso_mostrar > 0.0:
		await get_tree().create_timer(config.retraso_mostrar).timeout
	if not is_inside_tree():
		return

	# Espera a que se recojan los orbes de fin de oleada antes de ofrecer cartas.
	if config.esperar_orbes:
		await _esperar_orbes_recogidos()
		if not is_inside_tree():
			return

	if wave_manager != null and not bool(wave_manager.get("en_descanso")):
		_log("El descanso ya terminó antes de mostrar; no se muestran cartas.")
		return
	_mostrar_interfaz_mejoras()


## Espera hasta que no queden orbes en el grupo "orbe". Exige DOS lecturas
## seguidas vacías: los orbes que sueltan los enemigos al cerrar la oleada se
## añaden en diferido (call_deferred), así que un vacío puntual no basta.
## Corta por timeout (config.espera_max_orbes) o si el descanso termina.
func _esperar_orbes_recogidos() -> void:
	if config.espera_max_orbes <= 0.0:
		return
	var t0 := Time.get_ticks_msec()
	var vacios := 0
	while is_inside_tree():
		if wave_manager != null and not bool(wave_manager.get("en_descanso")):
			return
		if get_tree().get_nodes_in_group("orbe").is_empty():
			vacios += 1
			if vacios >= 2:
				_log("Orbes recogidos; mostrando cartas.")
				return
		else:
			vacios = 0
		if (Time.get_ticks_msec() - t0) / 1000.0 >= config.espera_max_orbes:
			_log("Timeout esperando orbes (%.1fs); se muestran las cartas igual." % config.espera_max_orbes)
			return
		await get_tree().create_timer(0.1).timeout

func _mostrar_interfaz_mejoras() -> void:
	if constructor == null or contenedor_visual == null:
		push_warning("[GestorCartas] Falta 'constructor' o 'contenedor_visual'.")
		return

	_limpiar_cartas_viejas()

	var orbes_jugador := BiomasaManager.contador
	var info_sorteada := _obtener_info_cartas(config.cartas_por_descanso)
	_log("Mostrando %d cartas (oleada %d, biomasa=%d):" % [info_sorteada.size(), _oleada_completada(), orbes_jugador])

	for info in info_sorteada:
		_log("   · %s [%s] coste=%d" % [info.nombre, info.rareza, info.costo_orbes])
		var carta_lista := constructor.fabricar_carta(info, orbes_jugador, config)
		contenedor_visual.add_child(carta_lista)
		carta_lista.carta_elegida.connect(_on_carta_elegida)

	show()
	_refrescar_biomasa_ui()
	_log("UI visible=%s" % visible)

	# Animación de apertura: fade del panel + entrada escalonada de las cartas.
	if _contenido != null:
		_contenido.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_contenido, "modulate:a", 1.0, 0.22)
	_animar_entrada_cartas.call_deferred()


func _animar_entrada_cartas() -> void:
	if contenedor_visual == null:
		return
	var hijos := contenedor_visual.get_children()
	for i in hijos.size():
		if hijos[i].has_method("animar_entrada"):
			hijos[i].call("animar_entrada", float(i) * 0.07)

func _on_carta_elegida(info: InfoMejora) -> void:
	# Confirmación opcional antes de gastar biomasa (ajuste "confirmar_compra").
	if info.costo_orbes > 0 and SaveManager != null and _confirm != null \
			and bool(SaveManager.get_ajuste("confirmar_compra", false)):
		_pendiente = info
		_confirm.abrir(
			'¿Comprar "%s"?\nCoste: %d biomasa.' % [info.nombre, info.costo_orbes],
			"COMPRAR", "CANCELAR", false)
		return
	_procesar_compra(info)


func _on_compra_confirmada() -> void:
	if _pendiente == null:
		return
	var info := _pendiente
	_pendiente = null
	_procesar_compra(info)


func _procesar_compra(info: InfoMejora) -> void:
	_log("Elegida: %s" % info.id)
	var ok := false
	if MejorasManager != null:
		ok = MejorasManager.comprar(info.id, info.costo_orbes)
	else:
		push_warning("[GestorCartas] MejorasManager no disponible; no se aplica la mejora.")

	if ok:
		_log("Comprada OK: %s" % info.id)
		mejora_comprada.emit(info.id)
		_animar_carta(info)
		_feedback_gasto(info.costo_orbes)
	else:
		_log("No se pudo comprar: %s (¿sin biomasa?)" % info.id)

	if config.permitir_multi_compra:
		_refrescar_cartas()
	else:
		_cerrar_interfaz()
		_terminar_descanso()

func _on_listo_presionado() -> void:
	_log("LISTO pulsado.")
	_cerrar_interfaz()
	_terminar_descanso()


# ── Biomasa en pantalla: valor + feedback de gasto ────────────────────────

func _on_biomasa_ui() -> void:
	_refrescar_biomasa_ui()


func _refrescar_biomasa_ui() -> void:
	if _biomasa_label == null:
		return
	var valor: int = BiomasaManager.contador if BiomasaManager != null else 0
	_biomasa_label.text = "🌱 %d" % valor


## Feedback al comprar: destello rojo + "pop" del indicador y un "-coste"
## flotante. Necesario porque el HUD del jugador queda debajo de esta pantalla.
func _feedback_gasto(cantidad: int) -> void:
	_refrescar_biomasa_ui()
	if _biomasa_label == null:
		return

	_biomasa_label.pivot_offset = _biomasa_label.size * 0.5
	_biomasa_label.add_theme_color_override("font_color", Color("ff6b6b"))
	var tw := create_tween()
	tw.tween_property(_biomasa_label, "scale", Vector2.ONE * 1.25, 0.08)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_biomasa_label, "scale", Vector2.ONE, 0.24)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		if _biomasa_label != null:
			_biomasa_label.remove_theme_color_override("font_color")
	)

	_flotar_gasto(cantidad)


## Etiqueta "-N" que sube desde el indicador y se desvanece.
func _flotar_gasto(cantidad: int) -> void:
	if _biomasa_label == null:
		return
	var fantasma := Label.new()
	fantasma.text = "-%d" % cantidad
	fantasma.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fantasma.z_index = 10
	fantasma.add_theme_font_override("font", config.fuente_boton)
	fantasma.add_theme_font_size_override("font_size", config.tam_titulo)
	fantasma.add_theme_color_override("font_color", Color("ff6b6b"))
	add_child(fantasma)
	# Justo a la derecha del número (el label ocupa todo el ancho del VBox,
	# así que se usa el ancho real del texto, no el del Control).
	var fuente: Font = _biomasa_label.get_theme_font("font")
	var tam: int = _biomasa_label.get_theme_font_size("font_size")
	var ancho_texto: float = fuente.get_string_size(
		_biomasa_label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, tam).x
	var centro := _biomasa_label.global_position + _biomasa_label.size * 0.5
	fantasma.global_position = centro + Vector2(ancho_texto * 0.5 + 12.0, -tam * 0.5)
	var destino := fantasma.global_position + Vector2(0.0, -38.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fantasma, "global_position", destino, 0.65)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(fantasma, "modulate:a", 0.0, 0.65).set_delay(0.2)
	tw.tween_callback(fantasma.queue_free).set_delay(0.7)

## Refresca la disponibilidad de compra de todas las cartas visibles.
func _refrescar_cartas() -> void:
	if contenedor_visual == null:
		return
	var orbes := BiomasaManager.contador
	for c in contenedor_visual.get_children():
		if c.has_method("actualizar_compra"):
			c.call("actualizar_compra", orbes)

## Anima la carta comprada (pop + destello).
func _animar_carta(info: InfoMejora) -> void:
	if contenedor_visual == null:
		return
	for c in contenedor_visual.get_children():
		if c.get("_info_actual") == info and c.has_method("animar_seleccion"):
			c.call("animar_seleccion")
			break

## Adelanta el fin del descanso (el jugador ya decidió).
func _terminar_descanso() -> void:
	if wave_manager != null and wave_manager.has_method("terminar_descanso"):
		_log("→ WaveManager.terminar_descanso()")
		wave_manager.call("terminar_descanso")
	else:
		_log("WaveManager sin terminar_descanso(); el descanso seguirá su cuenta.")

func _cerrar_interfaz() -> void:
	if _cerrando:
		return
	_cerrando = true
	if visible:
		_log("Cerrando cartas.")
		if _contenido != null:
			_contenido.modulate.a = 1.0
			var tw := create_tween()
			tw.tween_property(_contenido, "modulate:a", 0.0, 0.16)
			await tw.finished
		hide()
	_limpiar_cartas_viejas()
	if _contenido != null:
		_contenido.modulate.a = 1.0
	_cerrando = false

func _limpiar_cartas_viejas() -> void:
	if contenedor_visual == null:
		return
	for hijo in contenedor_visual.get_children():
		hijo.queue_free()

# ── Sorteo: filtra por oleada y pondera por rareza ─────────────────────────

func _obtener_info_cartas(cantidad: int) -> Array[InfoMejora]:
	var oleada := _oleada_completada()
	var suerte := 0.0
	if SaveManager != null:
		suerte = SaveManager.get_stat("jugador.suerte", 0.0)

	var desbloqueadas: Array[InfoMejora] = []
	for info in _pool:
		if config.oleada_min_de(info.rareza) <= oleada:
			desbloqueadas.append(info)

	var seleccion: Array[InfoMejora] = []
	var pool_temp := desbloqueadas.duplicate()

	for i in range(cantidad):
		if pool_temp.is_empty():
			break

		var peso_total := 0.0
		for info in pool_temp:
			peso_total += _peso(info, suerte)

		var tirada := randf() * peso_total
		var acumulado := 0.0

		for j in range(pool_temp.size()):
			acumulado += _peso(pool_temp[j], suerte)
			if tirada <= acumulado:
				seleccion.append(pool_temp[j])
				pool_temp.remove_at(j)
				break

	return seleccion


## Peso de aparición con sesgo de "suerte": las rarezas altas salen más.
func _peso(info: InfoMejora, suerte: float) -> float:
	var factor := 1.0
	match info.rareza:
		"Rara": factor = 1.0 + suerte
		"Épica": factor = 1.0 + suerte * 1.5
		"Legendaria": factor = 1.0 + suerte * 2.0
		_: factor = 1.0
	return maxf(info.peso_aparicion, 0.01) * maxf(factor, 0.01)
