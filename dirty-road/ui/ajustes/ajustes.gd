extends Control

## ══════════════════════════════════════════════════════════
##  AJUSTES — pantalla con PESTAÑAS (General / Educación / Audio /
##  Controles), controles neón propios y tamaño pensado para MÓVIL.
##
##  Toda la persistencia se centraliza en `SaveManager.set_ajuste()`
##  (que guarda en `user://ajustes.save` con escritura diferida).
## ══════════════════════════════════════════════════════════

signal volver
@export var volver_a_menu: bool = true

const RUTA_MENU := "res://ui/main/main.tscn"
const RUTA_SHADER := "res://ui/main/fondo.gdshader"
const SLIDER_NEON := preload("res://ui/controles/slider_neon.gd")
const INTERRUPTOR_NEON := preload("res://ui/controles/interruptor_neon.gd")
const CONFIRMACION := preload("res://ui/confirmacion.gd")

## Margen base del panel (además del safe-area).
const MARGEN := 40
## Alto mínimo de una fila/control táctil.
const ALTO_FILA := 64

var _raiz: Control = null
var _fondo: ColorRect = null
var _chip_guardado: PanelContainer = null
var _tween_guardado: Tween = null
var _confirm = null


func _ready() -> void:
	# Contenedor raíz reconstruible (para poder refrescar tras RESTABLECER).
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_raiz)

	# Modal de confirmación (fuera de _raiz para que sobreviva al refresco).
	_confirm = CONFIRMACION.new()
	add_child(_confirm)
	_confirm.confirmado.connect(_on_reset_confirmado)

	_construir()

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)


func _exit_tree() -> void:
	# Asegura la escritura de ajustes al salir de la pantalla.
	if SaveManager != null:
		SaveManager.flush_ajustes()


# ───────────────────────── CONSTRUCCIÓN ─────────────────────────

func _construir() -> void:
	_fondo = ColorRect.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load(RUTA_SHADER)
	_fondo.material = mat
	_fondo.visible = bool(SaveManager.get_ajuste("fondo_shader", true))
	_raiz.add_child(_fondo)

	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.04, 0.03, 0.72)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(velo)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ins := _insets()
	margen.add_theme_constant_override("margin_left", MARGEN + int(ins.x))
	margen.add_theme_constant_override("margin_top", MARGEN + int(ins.y))
	margen.add_theme_constant_override("margin_right", MARGEN + int(ins.z))
	margen.add_theme_constant_override("margin_bottom", MARGEN + int(ins.w))
	_raiz.add_child(margen)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _estilo_panel())
	margen.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	panel.add_child(col)

	col.add_child(_header())

	var tabs := TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_estilizar_tabs(tabs)
	col.add_child(tabs)

	# ── General ──
	var g := _tab(tabs, "General")
	var cg := _tarjeta(g, "Interfaz")
	_fila_check(cg, "Disparo automático", "disparo_automatico")
	_fila_check(cg, "Fondo animado (shader)", "fondo_shader")
	_fila_check(cg, "Mostrar FPS", "mostrar_fps")
	_fila_check(cg, "Flecha hacia el árbol", "mostrar_flecha_arbol")
	_fila_check(cg, "Cartel de oleada (HORDA)", "mostrar_cartel_horda")
	_fila_check(cg, "Confirmar al comprar mejoras", "confirmar_compra")
	_fila_check(cg, "Pausar al perder el foco", "pausa_al_perder_foco")
	_fila_check(cg, "Pantalla completa (escritorio)", "pantalla_completa")

	var cimg := _tarjeta(g, "Imagen")
	_fila_slider(cimg, "Brillo", "brillo", 0.5, 1.5, 0.05, "mult")
	_fila_slider(cimg, "Contraste", "contraste", 0.5, 1.5, 0.05, "mult")
	_fila_slider(cimg, "Saturación", "saturacion", 0.0, 2.0, 0.05, "mult")

	# ── Educación ──
	var e := _tab(tabs, "Educación")
	var ce := _tarjeta(e, "Popups educativos")
	_fila_slider(ce, "Tamaño de los popups", "edu_escala", 0.6, 1.6, 0.05, "mult")
	_fila_opcion(ce, "Posición de los popups", "edu_posicion", ["Arriba", "Centro", "Abajo"])
	_fila_slider(ce, "Duración de los mensajes", "edu_duracion_mult", 0.5, 2.0, 0.1, "mult")
	_fila_check(ce, "Mostrar insignia", "edu_insignia")
	_fila_check(ce, "Sonido de popups", "edu_sonido")

	# ── Audio ──
	var a := _tab(tabs, "Audio")
	var ca := _tarjeta(a, "Volúmenes")
	_fila_slider(ca, "Volumen general", "vol_master", 0.0, 1.0, 0.05, "pct")
	_fila_slider(ca, "Música", "vol_musica", 0.0, 1.0, 0.05, "pct")
	_fila_slider(ca, "Efectos", "vol_efectos", 0.0, 1.0, 0.05, "pct")

	# ── Controles ──
	var c := _tab(tabs, "Controles")
	var cc := _tarjeta(c, "HUD (joystick y botones)")
	_fila_slider(cc, "Tamaño del HUD", "hud_escala", 0.6, 1.2, 0.05, "mult")
	_fila_slider(cc, "Opacidad del HUD", "hud_opacidad", 0.3, 1.0, 0.05, "pct")
	_fila_slider(cc, "Zoom de cámara", "camara_zoom", 1.5, 3.0, 0.1, "mult")
	_fila_opcion(cc, "Mano de los controles", "hud_mano", ["Diestro", "Zurdo"])
	_fila_slider(cc, "Tamaño de botones", "hud_botones_escala", 0.5, 1.5, 0.05, "mult")
	_fila_slider(cc, "Tamaño del joystick", "hud_joystick_escala", 0.5, 1.5, 0.05, "mult")

	var cb := _tarjeta(c, "Disparo manual (sin automático)")
	_fila_check(cb, "Disparo continuo al apuntar", "disparo_continuo_manual")
	_fila_slider(cb, "Asistencia de apuntado", "autoapuntado", 0.0, 1.0, 0.05, "pct")

	# ── Accesibilidad ──
	var ac := _tab(tabs, "Accesibilidad")
	var cacc := _tarjeta(ac, "Accesibilidad")
	_fila_check(cacc, "Reducir destellos", "reducir_flashes")
	_fila_check(cacc, "Reducir partículas", "reducir_particulas")
	_fila_check(cacc, "Vibración (móvil)", "vibracion")
	_fila_check(cacc, "Silenciar audio en segundo plano", "audio_en_foco")

	col.add_child(_footer())


func _header() -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)

	var titulo := Label.new()
	titulo.text = "AJUSTES"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EstiloUI.titulo(titulo, 64, EstiloUI.NEON)
	hb.add_child(titulo)

	# Chip "Guardado ✓": feedback de que el cambio se comunicó al SaveManager.
	_chip_guardado = PanelContainer.new()
	_chip_guardado.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_chip_guardado.modulate.a = 0.0
	var cs := StyleBoxFlat.new()
	cs.bg_color = EstiloUI.NEON
	cs.set_corner_radius_all(18)
	cs.content_margin_left = 20
	cs.content_margin_right = 20
	cs.content_margin_top = 8
	cs.content_margin_bottom = 8
	_chip_guardado.add_theme_stylebox_override("panel", cs)
	var lbl := Label.new()
	lbl.text = "Guardado ✓"
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_override("font", EstiloUI.F_BOLD)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.04, 0.09, 0.06))
	_chip_guardado.add_child(lbl)
	hb.add_child(_chip_guardado)

	return hb


func _footer() -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)

	var reset := Button.new()
	reset.text = "RESTABLECER"
	reset.custom_minimum_size = Vector2(300, 76)
	reset.focus_mode = Control.FOCUS_NONE
	EstiloUI.boton_menu(reset, 30, false)
	reset.add_theme_color_override("font_color", EstiloUI.PELIGRO)
	reset.pressed.connect(_pedir_reset)
	hb.add_child(reset)

	var volver := Button.new()
	volver.text = "VOLVER"
	volver.custom_minimum_size = Vector2(300, 76)
	volver.focus_mode = Control.FOCUS_NONE
	EstiloUI.boton_menu(volver, 30, false)
	volver.pressed.connect(_volver)
	hb.add_child(volver)

	return hb


## Crea una pestaña con scroll y devuelve su VBox para colgar contenido.
func _tab(tabs: TabContainer, nombre: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = nombre
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 16)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(vb)
	tabs.add_child(scroll)
	return vb


## Tarjeta de sección con cabecera. Devuelve el VBox interno para las filas.
func _tarjeta(padre: Node, texto: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _estilo_tarjeta())
	padre.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vb)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var barra := ColorRect.new()
	barra.color = EstiloUI.NEON
	barra.custom_minimum_size = Vector2(6, 30)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(barra)
	var l := Label.new()
	l.text = texto
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", EstiloUI.F_BOLD)
	l.add_theme_font_size_override("font_size", 34)
	l.add_theme_color_override("font_color", EstiloUI.NEON)
	fila.add_child(l)
	vb.add_child(fila)

	return vb


# ───────────────────────── FILAS ─────────────────────────

func _fila_base(padre: Node, etiqueta: String) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	hb.custom_minimum_size = Vector2(0, ALTO_FILA)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = etiqueta
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 28)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(l)
	padre.add_child(hb)
	return hb


func _fila_check(padre: Node, etiqueta: String, clave: String) -> void:
	var hb := _fila_base(padre, etiqueta)
	var chk = INTERRUPTOR_NEON.new()
	chk.color = EstiloUI.NEON
	# Primero al árbol: InterruptorNeon._ready() activa toggle_mode. Si se fija
	# button_pressed antes, BaseButton lo IGNORA (solo funciona en toggle_mode)
	# y el switch arrancaría siempre en OFF aunque el valor guardado sea true.
	hb.add_child(chk)
	chk.set_pressed_no_signal(bool(SaveManager.get_ajuste(clave, true)))
	chk.toggled.connect(func(v: bool) -> void:
		_guardar(clave, v)
		if clave == "fondo_shader":
			_aplicar_fondo()
	)


func _fila_slider(padre: Node, etiqueta: String, clave: String,
		mn: float, mx: float, paso: float, tipo: String) -> void:
	var hb := _fila_base(padre, etiqueta)

	var b_menos := _boton_paso("−")
	hb.add_child(b_menos)

	var sl = SLIDER_NEON.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = paso
	sl.color = EstiloUI.NEON
	sl.custom_minimum_size = Vector2(420, ALTO_FILA)
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.set_value(float(SaveManager.get_ajuste(clave, mn)))
	hb.add_child(sl)

	var b_mas := _boton_paso("+")
	hb.add_child(b_mas)

	var valor := Label.new()
	valor.custom_minimum_size = Vector2(96, 0)
	valor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	valor.add_theme_font_override("font", EstiloUI.F_BOLD)
	valor.add_theme_font_size_override("font_size", 28)
	valor.add_theme_color_override("font_color", EstiloUI.NEON)
	valor.text = _formato(tipo, float(sl.value))
	hb.add_child(valor)

	b_menos.pressed.connect(func() -> void: _mover(sl, valor, clave, tipo, -paso))
	b_mas.pressed.connect(func() -> void: _mover(sl, valor, clave, tipo, paso))
	sl.value_changed.connect(func(v: float) -> void:
		valor.text = _formato(tipo, v)
		_guardar(clave, v)
	)


func _fila_opcion(padre: Node, etiqueta: String, clave: String, opciones: Array) -> void:
	var hb := _fila_base(padre, etiqueta)
	var opt := OptionButton.new()
	opt.focus_mode = Control.FOCUS_NONE
	opt.custom_minimum_size = Vector2(320, ALTO_FILA)
	for o in opciones:
		opt.add_item(str(o))
	opt.selected = clampi(int(SaveManager.get_ajuste(clave, 0)), 0, opciones.size() - 1)
	_estilizar_option(opt)
	opt.item_selected.connect(func(i: int) -> void: _guardar(clave, i))
	hb.add_child(opt)


func _boton_paso(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(ALTO_FILA, ALTO_FILA)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_override("font", EstiloUI.F_BOLD)
	b.add_theme_font_size_override("font_size", 32)
	return b


## Ajusta el slider con −/+ (precisión táctil) y persiste el valor.
func _mover(sl, valor: Label, clave: String, tipo: String, delta: float) -> void:
	var v: float = float(sl.value) + delta
	if float(sl.step) > 0.0:
		v = snappedf(v, float(sl.step))
	v = clampf(v, float(sl.min_value), float(sl.max_value))
	sl.set_value(v)
	valor.text = _formato(tipo, v)
	_guardar(clave, v)


# ───────────────────────── PERSISTENCIA ─────────────────────────

## Único punto de guardado: delega SIEMPRE en SaveManager.
func _guardar(clave: String, valor: Variant) -> void:
	if SaveManager == null:
		push_warning("[Ajustes] SaveManager no disponible; no se guardó '%s'." % clave)
		return
	SaveManager.set_ajuste(clave, valor)
	_mostrar_guardado()


func _mostrar_guardado() -> void:
	if _chip_guardado == null:
		return
	if _tween_guardado != null and _tween_guardado.is_valid():
		_tween_guardado.kill()
	_chip_guardado.modulate.a = 1.0
	_tween_guardado = create_tween()
	_tween_guardado.tween_interval(1.0)
	_tween_guardado.tween_property(_chip_guardado, "modulate:a", 0.0, 0.5)


func _formato(tipo: String, v: float) -> String:
	if tipo == "pct":
		return "%d %%" % roundi(v * 100.0)
	return "%.2f×" % v


# ───────────────────────── ESTILOS ─────────────────────────

func _estilo_panel() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.07, 0.05, 0.94)
	sb.border_color = EstiloUI.NEON
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(22)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	sb.shadow_color = Color(EstiloUI.NEON.r, EstiloUI.NEON.g, EstiloUI.NEON.b, 0.25)
	sb.shadow_size = 18
	return sb


func _estilo_tarjeta() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.07, 0.05, 0.85)
	sb.border_color = Color(EstiloUI.NEON.r, EstiloUI.NEON.g, EstiloUI.NEON.b, 0.35)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb


func _estilizar_tabs(tabs: TabContainer) -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.02, 0.05, 0.04, 0.55)
	panel.set_corner_radius_all(14)
	panel.content_margin_left = 18
	panel.content_margin_right = 18
	panel.content_margin_top = 18
	panel.content_margin_bottom = 18
	tabs.add_theme_stylebox_override("panel", panel)

	var sel := StyleBoxFlat.new()
	sel.bg_color = EstiloUI.NEON
	sel.set_corner_radius_all(12)
	sel.content_margin_left = 24
	sel.content_margin_right = 24
	sel.content_margin_top = 12
	sel.content_margin_bottom = 12
	tabs.add_theme_stylebox_override("tab_selected", sel)

	var uns := StyleBoxFlat.new()
	uns.bg_color = Color(0.06, 0.12, 0.09, 0.9)
	uns.set_corner_radius_all(12)
	uns.content_margin_left = 24
	uns.content_margin_right = 24
	uns.content_margin_top = 12
	uns.content_margin_bottom = 12
	tabs.add_theme_stylebox_override("tab_unselected", uns)

	var hov: StyleBoxFlat = uns.duplicate()
	hov.bg_color = Color(0.09, 0.18, 0.13, 1.0)
	tabs.add_theme_stylebox_override("tab_hover", hov)
	tabs.add_theme_stylebox_override("tab_hovered", hov)

	tabs.add_theme_font_override("font", EstiloUI.F_SEMI)
	tabs.add_theme_font_size_override("font_size", 26)
	tabs.add_theme_color_override("font_selected_color", Color(0.04, 0.09, 0.06))
	tabs.add_theme_color_override("font_unselected_color", EstiloUI.VERDE_CLARO)
	tabs.add_theme_color_override("font_hovered_color", EstiloUI.TEXTO)
	tabs.add_theme_color_override("font_hover_color", EstiloUI.TEXTO)


func _estilizar_option(opt: OptionButton) -> void:
	opt.add_theme_font_override("font", EstiloUI.F_SEMI)
	opt.add_theme_font_size_override("font_size", 26)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("0d2015")
	normal.border_color = EstiloUI.NEON
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("122a1c")
	opt.add_theme_stylebox_override("normal", normal)
	opt.add_theme_stylebox_override("hover", hover)
	opt.add_theme_stylebox_override("pressed", hover)
	opt.add_theme_stylebox_override("focus", normal)
	var pop := opt.get_popup()
	if pop != null:
		pop.add_theme_font_override("font", EstiloUI.F_SEMI)
		pop.add_theme_font_size_override("font_size", 26)
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color("0a1710")
		psb.border_color = EstiloUI.NEON
		psb.set_border_width_all(2)
		psb.set_corner_radius_all(12)
		pop.add_theme_stylebox_override("panel", psb)
		var hsb := StyleBoxFlat.new()
		hsb.bg_color = Color("16341f")
		pop.add_theme_stylebox_override("hover", hsb)


# ───────────────────────── ACCIONES ─────────────────────────

func _aplicar_fondo() -> void:
	if _fondo != null:
		_fondo.visible = bool(SaveManager.get_ajuste("fondo_shader", true))


func _pedir_reset() -> void:
	if _confirm == null:
		return
	_confirm.abrir(
		"¿Restablecer todos los ajustes a sus valores por defecto?\n\n"
		+ "Se perderán tus preferencias actuales.",
		"RESTABLECER", "CANCELAR", true
	)


func _on_reset_confirmado() -> void:
	SaveManager.reset_ajustes()
	_reconstruir()
	_mostrar_guardado()


func _reconstruir() -> void:
	if _raiz == null:
		return
	for c in _raiz.get_children():
		_raiz.remove_child(c)
		c.queue_free()
	_construir()


func _volver() -> void:
	if SaveManager != null:
		SaveManager.flush_ajustes()
	if volver_a_menu:
		get_tree().change_scene_to_file(RUTA_MENU)
	else:
		volver.emit()
		queue_free()


# ───────────────────────── SAFE AREA ─────────────────────────

## Insets (izq, arriba, der, abajo) en píxeles lógicos, acotados a 80.
## Solo se aplican en móvil (en escritorio la ventana puede no ser fullscreen
## y daría márgenes falsos).
func _insets() -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var vp := get_viewport_rect().size
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0 or vp.x <= 0.0 or vp.y <= 0.0:
		return Vector4.ZERO
	var sx := vp.x / win.x
	var sy := vp.y / win.y
	var safe := DisplayServer.get_display_safe_area()
	var izq := maxf(safe.position.x * sx, 0.0)
	var arr := maxf(safe.position.y * sy, 0.0)
	var der := maxf((win.x - safe.end.x) * sx, 0.0)
	var aba := maxf((win.y - safe.end.y) * sy, 0.0)
	return Vector4(
		minf(izq, 80.0), minf(arr, 80.0), minf(der, 80.0), minf(aba, 80.0)
	)