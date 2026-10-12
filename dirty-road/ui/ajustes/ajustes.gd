extends Control

## ══════════════════════════════════════════════════════════
##  AJUSTES — con CONTROLES PROPIOS neón (nada de Godot por defecto),
##  fondo shader del menú y tamaño pensado para MÓVIL.
## ══════════════════════════════════════════════════════════

const RUTA_MENU := "res://ui/main/main.tscn"
const RUTA_SHADER := "res://ui/main/fondo.gdshader"
const SLIDER_NEON := preload("res://ui/controles/slider_neon.gd")
const INTERRUPTOR_NEON := preload("res://ui/controles/interruptor_neon.gd")

signal volver
@export var volver_a_menu: bool = true

var _fondo: ColorRect = null


func _ready() -> void:
	_construir()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)


func _construir() -> void:
	_fondo = ColorRect.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load(RUTA_SHADER)
	_fondo.material = mat
	add_child(_fondo)
	_aplicar_fondo()

	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.04, 0.03, 0.72)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _estilo_panel())
	centro.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	panel.add_child(col)

	var titulo := Label.new()
	titulo.text = "AJUSTES"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	EstiloUI.titulo(titulo, 84, EstiloUI.NEON)
	col.add_child(titulo)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(880, 780)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	var cont := VBoxContainer.new()
	cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.add_theme_constant_override("separation", 16)
	scroll.add_child(cont)

	_seccion(cont, "General")
	_fila_check(cont, "Disparo automático", "disparo_automatico")
	_fila_check(cont, "Fondo animado (shader)", "fondo_shader")

	_seccion(cont, "Educación")
	_fila_slider(cont, "Tamaño de los popups", "edu_escala", 0.6, 1.6, 0.05)
	_fila_opcion(cont, "Posición de los popups", "edu_posicion", ["Arriba", "Centro", "Abajo"])
	_fila_slider(cont, "Duración de los mensajes", "edu_duracion_mult", 0.5, 2.0, 0.1)
	_fila_check(cont, "Mostrar insignia", "edu_insignia")
	_fila_check(cont, "Sonido de popups", "edu_sonido")

	_seccion(cont, "Audio")
	_fila_slider(cont, "Volumen general", "vol_master", 0.0, 1.0, 0.05)
	_fila_slider(cont, "Música", "vol_musica", 0.0, 1.0, 0.05)
	_fila_slider(cont, "Efectos", "vol_efectos", 0.0, 1.0, 0.05)

	_seccion(cont, "Controles")
	_fila_slider(cont, "Tamaño del HUD (joystick/botones)", "hud_escala", 0.6, 1.8, 0.05)
	_fila_slider(cont, "Opacidad del HUD", "hud_opacidad", 0.3, 1.0, 0.05)

	var volver := Button.new()
	volver.text = "VOLVER"
	volver.custom_minimum_size = Vector2(320, 76)
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.focus_mode = Control.FOCUS_NONE
	EstiloUI.boton_menu(volver, 36)
	volver.pressed.connect(_volver)
	col.add_child(volver)


func _estilo_panel() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.07, 0.05, 0.92)
	sb.border_color = EstiloUI.NEON
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	sb.shadow_color = Color(EstiloUI.NEON.r, EstiloUI.NEON.g, EstiloUI.NEON.b, 0.25)
	sb.shadow_size = 18
	return sb


func _aplicar_fondo() -> void:
	if _fondo != null:
		_fondo.visible = bool(SaveManager.get_ajuste("fondo_shader", true))


func _seccion(padre: Node, texto: String) -> void:
	padre.add_child(HSeparator.new())
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	var barra := ColorRect.new()
	barra.color = EstiloUI.NEON
	barra.custom_minimum_size = Vector2(6, 30)
	fila.add_child(barra)
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", EstiloUI.F_BOLD)
	l.add_theme_font_size_override("font_size", 38)
	l.add_theme_color_override("font_color", EstiloUI.NEON)
	fila.add_child(l)
	padre.add_child(fila)


func _fila_base(padre: Node, etiqueta: String) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	var l := Label.new()
	l.text = etiqueta
	l.add_theme_font_size_override("font_size", 28)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(l)
	padre.add_child(hb)
	return hb


func _fila_check(padre: Node, etiqueta: String, clave: String) -> void:
	var hb := _fila_base(padre, etiqueta)
	var chk = INTERRUPTOR_NEON.new()
	chk.color = EstiloUI.NEON
	chk.button_pressed = bool(SaveManager.get_ajuste(clave, true))
	chk.toggled.connect(func(v: bool) -> void:
		SaveManager.set_ajuste(clave, v)
		if clave == "fondo_shader":
			_aplicar_fondo()
	)
	hb.add_child(chk)


func _fila_slider(padre: Node, etiqueta: String, clave: String, mn: float, mx: float, paso: float) -> void:
	var hb := _fila_base(padre, etiqueta)
	var valor := Label.new()
	valor.custom_minimum_size = Vector2(90, 0)
	valor.add_theme_font_size_override("font_size", 26)
	hb.add_child(valor)
	var sl = SLIDER_NEON.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = paso
	sl.color = EstiloUI.NEON
	sl.custom_minimum_size = Vector2(380, 56)
	sl.set_value(float(SaveManager.get_ajuste(clave, mn)))
	valor.text = "%.2f" % sl.value
	sl.value_changed.connect(func(v: float) -> void:
		valor.text = "%.2f" % v
		SaveManager.set_ajuste(clave, v)
	)
	hb.add_child(sl)


func _fila_opcion(padre: Node, etiqueta: String, clave: String, opciones: Array) -> void:
	var hb := _fila_base(padre, etiqueta)
	var opt := OptionButton.new()
	opt.focus_mode = Control.FOCUS_NONE
	opt.custom_minimum_size = Vector2(320, 68)
	for o in opciones:
		opt.add_item(str(o))
	opt.selected = clampi(int(SaveManager.get_ajuste(clave, 0)), 0, opciones.size() - 1)
	_estilizar_option(opt)
	opt.item_selected.connect(func(i: int) -> void: SaveManager.set_ajuste(clave, i))
	hb.add_child(opt)


func _estilizar_option(opt: OptionButton) -> void:
	opt.add_theme_font_override("font", EstiloUI.F_SEMI)
	opt.add_theme_font_size_override("font_size", 24)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("0d2015")
	normal.border_color = EstiloUI.NEON
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("122a1c")
	opt.add_theme_stylebox_override("normal", normal)
	opt.add_theme_stylebox_override("hover", hover)
	opt.add_theme_stylebox_override("pressed", hover)
	opt.add_theme_stylebox_override("focus", normal)
	var pop := opt.get_popup()
	if pop != null:
		pop.add_theme_font_override("font", EstiloUI.F_SEMI)
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color("0a1710")
		psb.border_color = EstiloUI.NEON
		psb.set_border_width_all(2)
		psb.set_corner_radius_all(12)
		pop.add_theme_stylebox_override("panel", psb)
		var hsb := StyleBoxFlat.new()
		hsb.bg_color = Color("16341f")
		pop.add_theme_stylebox_override("hover", hsb)


func _volver() -> void:
	if volver_a_menu:
		get_tree().change_scene_to_file(RUTA_MENU)
	else:
		volver.emit()
		queue_free()
