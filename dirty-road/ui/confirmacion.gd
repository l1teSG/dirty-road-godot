class_name Confirmacion
extends CanvasLayer

## ══════════════════════════════════════════════════════════
##  MODAL DE CONFIRMACIÓN táctil (pensado para móvil).
##  Sustituye a `ConfirmationDialog` (que trae botones y barra de
##  ventana pequeños, de escritorio).
##
##  Uso:
##    var c := CONFIRMACION.new()
##    add_child(c)
##    c.confirmado.connect(_hacer_algo)
##    c.abrir("¿Seguro?", "BORRAR", "CANCELAR", true)
##
##  Señales: confirmado / cancelado
## ══════════════════════════════════════════════════════════

signal confirmado
signal cancelado

## Título que aparece arriba del mensaje.
@export var titulo: String = "Confirmar"

var _overlay: Control
var _lbl_mensaje: Label
var _btn_ok: Button
var _btn_cancel: Button


func _ready() -> void:
	layer = 210
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir()
	set_visible(false)


func _construir() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	add_child(_overlay)

	var fondo := ColorRect.new()
	fondo.color = Color(0.0, 0.0, 0.0, 0.6)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(centro)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	panel.add_theme_stylebox_override("panel", _estilo_panel())
	centro.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 26)
	panel.add_child(vb)

	var lbl_titulo := Label.new()
	lbl_titulo.text = titulo
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	EstiloUI.titulo(lbl_titulo, 52, EstiloUI.NEON)
	vb.add_child(lbl_titulo)

	_lbl_mensaje = Label.new()
	_lbl_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_mensaje.custom_minimum_size = Vector2(680, 0)
	_lbl_mensaje.add_theme_font_size_override("font_size", 30)
	_lbl_mensaje.add_theme_color_override("font_color", EstiloUI.TEXTO)
	vb.add_child(_lbl_mensaje)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 24)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)

	_btn_cancel = Button.new()
	_btn_cancel.text = "CANCELAR"
	_btn_cancel.custom_minimum_size = Vector2(280, 80)
	_btn_cancel.focus_mode = Control.FOCUS_NONE
	EstiloUI.boton_menu(_btn_cancel, 30)
	_btn_cancel.pressed.connect(_on_cancel)
	hb.add_child(_btn_cancel)

	_btn_ok = Button.new()
	_btn_ok.text = "ACEPTAR"
	_btn_ok.custom_minimum_size = Vector2(280, 80)
	_btn_ok.focus_mode = Control.FOCUS_NONE
	EstiloUI.boton_menu(_btn_ok, 30)
	_btn_ok.pressed.connect(_on_ok)
	hb.add_child(_btn_ok)


## Muestra el modal. `peligro` pinta el botón de aceptar en rojo.
func abrir(mensaje: String, texto_ok: String = "ACEPTAR",
		texto_cancelar: String = "CANCELAR", peligro: bool = false) -> void:
	_lbl_mensaje.text = mensaje
	_btn_ok.text = texto_ok
	_btn_cancel.text = texto_cancelar
	_aplicar_estilo_boton(_btn_ok, peligro)
	_overlay.visible = true
	set_visible(true)

	var panel := _overlay.get_child(1).get_child(0) as Control
	if panel != null:
		panel.pivot_offset = panel.size * 0.5
		panel.scale = Vector2(0.9, 0.9)
		var tw := create_tween()
		tw.tween_property(panel, "scale", Vector2.ONE, 0.18)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func cerrar() -> void:
	_overlay.visible = false
	set_visible(false)


func _on_ok() -> void:
	cerrar()
	confirmado.emit()


func _on_cancel() -> void:
	cerrar()
	cancelado.emit()


func _estilo_panel() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.07, 0.05, 0.98)
	sb.border_color = EstiloUI.NEON
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	sb.shadow_color = Color(EstiloUI.NEON.r, EstiloUI.NEON.g, EstiloUI.NEON.b, 0.25)
	sb.shadow_size = 18
	return sb


func _aplicar_estilo_boton(boton: Button, peligro: bool) -> void:
	var acento: Color = EstiloUI.PELIGRO if peligro else EstiloUI.NEON
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.03, 0.05) if peligro else Color("0d2015")
	normal.border_color = acento
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	normal.content_margin_top = 14
	normal.content_margin_bottom = 14

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(acento.r, acento.g, acento.b, 0.22)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(acento.r, acento.g, acento.b, 0.35)

	boton.add_theme_stylebox_override("normal", normal)
	boton.add_theme_stylebox_override("hover", hover)
	boton.add_theme_stylebox_override("pressed", pressed)
	boton.add_theme_color_override("font_color", acento)
	boton.add_theme_color_override("font_hover_color", Color.WHITE)