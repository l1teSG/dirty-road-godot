extends CanvasLayer

# EducationPopup v2.3
# Dos estilos: TARJETA (cuadro con chip, título, cuerpo y barra de tiempo)
# o SUBTITULOS (texto con contorno, sin cuadro). Posición inferior o superior.
# Cada tipo puede forzarse a subtítulos con subtitle_style_variants.
# API:
#   enqueue(text: String, variant: int, duration: float = -1.0, subtitle: String = "")
#   signal popup_finished
# "text": "Título\nLínea 1\nLínea 2". Si no hay "\n", todo es cuerpo (sin título).

signal popup_finished

enum ToastPosition { BOTTOM, TOP }
enum DisplayStyle { CARD, SUBTITLES }

@export_category("Layout")
@export var display_style: DisplayStyle = DisplayStyle.CARD
## Tipos que se muestran como subtítulos aunque display_style sea Tarjeta
## 0 WAVE_BREAK, 1 DEATH, 2 ENEMY_CARD, 3 SURVIVAL
@export var subtitle_style_variants: Array[int] = [3]
@export var toast_position: ToastPosition = ToastPosition.BOTTOM
@export var bottom_margin: float = 40.0
@export var top_margin: float = 110.0
@export_range(0.2, 1.0) var width_ratio: float = 0.5
@export_range(0.2, 1.0) var subtitles_width_ratio: float = 0.7
@export var slide_in: float = 0.35
@export var slide_out: float = 0.3
@export var default_duration: float = 3.5
@export var corner_radius: int = 14
@export var accent_bar_width: int = 6
@export var padding: Vector2 = Vector2(20, 14)

@export_category("Texto")
@export var chip_font_size: int = 14
@export var subtitle_font_size: int = 15
@export var title_font_size: int = 26
@export var body_font_size: int = 20
@export var show_time_bar: bool = true

@export_category("Estilo Subtítulos")
## Opacidad de un fondo suave detrás del texto (0 = sin fondo)
@export_range(0.0, 1.0) var subtitles_bg_alpha: float = 0.0
@export var outline_size: int = 6
@export var outline_color: Color = Color(0, 0, 0, 0.95)
@export var shadow_color: Color = Color(0, 0, 0, 0.6)
@export var shadow_offset: Vector2 = Vector2(2, 2)

@export_category("Colores")
@export var bg_color: Color = Color(0.0, 0.0, 0.0, 0.8)
@export var title_color: Color = Color(0.6, 1.0, 0.55)
@export var body_color: Color = Color(1, 1, 1)
@export var subtitle_color: Color = Color(1, 1, 1, 0.65)
@export var chip_text_color: Color = Color(0, 0, 0)
@export var color_wave_break: Color = Color(0.45, 0.9, 0.45)
@export var color_death: Color = Color(0.75, 0.85, 0.55)
@export var color_enemy_card: Color = Color(0.4, 0.85, 0.8)
@export var color_survival: Color = Color(0.5, 0.95, 0.5)

# 0 WAVE_BREAK, 1 DEATH, 2 ENEMY_CARD, 3 SURVIVAL
const CHIP_NAMES: Dictionary = {
	0: "DATO AMBIENTAL",
	1: "REFLEXIÓN",
	2: "NUEVA AMENAZA",
	3: "¿SABÍAS QUÉ?"
}

var _panel: PanelContainer
var _style: StyleBoxFlat
var _chip: Label
var _chip_style: StyleBoxFlat
var _subtitle_label: Label
var _title_label: Label
var _separator: ColorRect
var _body_label: Label
var _time_bar: ProgressBar
var _time_fill: StyleBoxFlat

var _tween: Tween
var _queue: Array = []
var _busy: bool = false
var _current_text: String = ""
var _card_mode: bool = true


func _ready() -> void:
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	get_viewport().size_changed.connect(_on_viewport_resized)


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = StyleBoxFlat.new()
	_style.bg_color = bg_color
	_style.set_corner_radius_all(corner_radius)
	_style.set_border_width_all(2)
	_style.border_width_left = accent_bar_width
	_style.border_color = color_wave_break
	_panel.add_theme_stylebox_override("panel", _style)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", int(padding.x))
	margin.add_theme_constant_override("margin_right", int(padding.x))
	margin.add_theme_constant_override("margin_top", int(padding.y))
	margin.add_theme_constant_override("margin_bottom", int(padding.y))
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Fila superior: chip (izq) + etapa (der)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	_chip = Label.new()
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.add_theme_font_size_override("font_size", chip_font_size)
	_chip.add_theme_color_override("font_color", chip_text_color)
	_chip_style = StyleBoxFlat.new()
	_chip_style.set_corner_radius_all(8)
	_chip_style.content_margin_left = 10
	_chip_style.content_margin_right = 10
	_chip_style.content_margin_top = 2
	_chip_style.content_margin_bottom = 2
	_chip.add_theme_stylebox_override("normal", _chip_style)
	header.add_child(_chip)

	_subtitle_label = Label.new()
	_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_subtitle_label.clip_text = true
	_subtitle_label.add_theme_font_size_override("font_size", subtitle_font_size)
	_subtitle_label.add_theme_color_override("font_color", subtitle_color)
	header.add_child(_subtitle_label)

	_title_label = Label.new()
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", title_font_size)
	_title_label.add_theme_color_override("font_color", title_color)
	vbox.add_child(_title_label)

	_separator = ColorRect.new()
	_separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_separator.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(_separator)

	_body_label = Label.new()
	_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", body_font_size)
	_body_label.add_theme_color_override("font_color", body_color)
	_body_label.add_theme_constant_override("line_spacing", 6)
	vbox.add_child(_body_label)

	# Barra de tiempo
	_time_bar = ProgressBar.new()
	_time_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time_bar.show_percentage = false
	_time_bar.min_value = 0.0
	_time_bar.max_value = 1.0
	_time_bar.value = 1.0
	_time_bar.custom_minimum_size = Vector2(0, 4)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.08)
	bg.set_corner_radius_all(2)
	_time_fill = StyleBoxFlat.new()
	_time_fill.set_corner_radius_all(2)
	_time_bar.add_theme_stylebox_override("background", bg)
	_time_bar.add_theme_stylebox_override("fill", _time_fill)
	vbox.add_child(_time_bar)


func enqueue(text: String, variant: int, duration: float = -1.0, subtitle: String = "") -> void:
	if duration < 0.0:
		duration = default_duration
	# Protección contra duplicados (mensaje actual o ya en cola)
	if _busy and text == _current_text:
		return
	for item in _queue:
		if item["text"] == text:
			return
	_queue.append({"text": text, "variant": variant, "duration": duration, "subtitle": subtitle})
	if not _busy:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_busy = false
		return

	_busy = true
	var data: Dictionary = _queue.pop_front()
	_current_text = data["text"]
	_card_mode = _resolve_card(data["variant"])
	_configure_content(data["text"], data["variant"], data["subtitle"])

	# Ancho fijo ANTES de medir, para que el autowrap calcule bien la altura
	_apply_widths()
	_panel.modulate.a = 0.0
	_panel.visible = true
	await get_tree().process_frame

	# Reiniciar la altura: el panel se encoge al tamaño real del contenido
	_panel.size = Vector2(_toast_width(), 0)
	await get_tree().process_frame

	var vp: Vector2 = get_viewport().get_visible_rect().size
	_panel.position.x = (vp.x - _panel.size.x) / 2.0
	var start_y: float = _hidden_y()
	var end_y: float = _target_y()
	_panel.position.y = start_y
	_panel.modulate.a = 1.0
	_time_bar.value = 1.0

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "position:y", end_y, slide_in)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _is_card() and show_time_bar:
		_tween.tween_property(_time_bar, "value", 0.0, data["duration"])
	else:
		_tween.tween_interval(data["duration"])
	_tween.tween_property(_panel, "position:y", start_y, slide_out)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_on_hidden)


func _on_hidden() -> void:
	_current_text = ""
	_panel.visible = false
	popup_finished.emit()
	_show_next()


func _configure_content(text: String, variant: int, subtitle: String) -> void:
	var accent: Color = _variant_color(variant)
	var title: String = ""
	var body: String = text

	var idx: int = text.find("\n")
	if idx != -1:
		title = text.substr(0, idx)
		body = text.substr(idx + 1)

	var card: bool = _is_card()

	_chip.text = CHIP_NAMES.get(variant, "DATO")
	_chip_style.bg_color = accent
	_chip.visible = card

	_subtitle_label.text = subtitle
	_subtitle_label.visible = subtitle != ""

	_title_label.text = title
	_title_label.visible = title != ""
	_separator.visible = card and title != ""
	_separator.color = Color(accent, 0.35)

	_body_label.text = body
	_body_label.add_theme_font_size_override("font_size",
		body_font_size if title != "" else body_font_size + 2)

	_time_bar.visible = card and show_time_bar
	_time_fill.bg_color = accent

	_apply_style_mode(card, accent)


## Cambia entre tarjeta y subtítulos (fondo, bordes, alineación, contorno)
func _apply_style_mode(card: bool, accent: Color) -> void:
	var align: int = HORIZONTAL_ALIGNMENT_LEFT if card else HORIZONTAL_ALIGNMENT_CENTER
	_title_label.horizontal_alignment = align as HorizontalAlignment
	_body_label.horizontal_alignment = align as HorizontalAlignment
	_subtitle_label.horizontal_alignment = (HORIZONTAL_ALIGNMENT_RIGHT if card else HORIZONTAL_ALIGNMENT_CENTER) as HorizontalAlignment

	if card:
		_style.bg_color = bg_color
		_style.set_corner_radius_all(corner_radius)
		_style.set_border_width_all(2)
		_style.border_width_left = accent_bar_width
		_style.border_color = accent
		_title_label.add_theme_color_override("font_color", title_color)
	else:
		_style.bg_color = Color(0, 0, 0, subtitles_bg_alpha)
		_style.set_corner_radius_all(corner_radius)
		_style.set_border_width_all(0)
		# En subtítulos el título toma el color de acento de cada tipo
		_title_label.add_theme_color_override("font_color", accent.lightened(0.25))

	for lbl in [_title_label, _body_label, _subtitle_label]:
		_set_text_fx(lbl, not card)


func _set_text_fx(lbl: Label, enabled: bool) -> void:
	if enabled:
		lbl.add_theme_constant_override("outline_size", outline_size)
		lbl.add_theme_color_override("font_outline_color", outline_color)
		lbl.add_theme_color_override("font_shadow_color", shadow_color)
		lbl.add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
		lbl.add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
	else:
		lbl.add_theme_constant_override("outline_size", 0)
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		lbl.add_theme_constant_override("shadow_offset_x", 0)
		lbl.add_theme_constant_override("shadow_offset_y", 0)


func _is_card() -> bool:
	return _card_mode


func _resolve_card(variant: int) -> bool:
	if variant in subtitle_style_variants:
		return false
	return display_style == DisplayStyle.CARD


func _variant_color(variant: int) -> Color:
	match variant:
		0: return color_wave_break
		1: return color_death
		2: return color_enemy_card
		3: return color_survival
	return color_wave_break


func _apply_widths() -> void:
	var w: float = _content_width()
	_title_label.custom_minimum_size.x = w
	_body_label.custom_minimum_size.x = w
	_panel.custom_minimum_size = Vector2(_toast_width(), 0)
	_panel.size = Vector2(_toast_width(), 0)


## Ancho útil del texto dentro del contenedor
func _content_width() -> float:
	var border: float = (accent_bar_width + 2.0) if _is_card() else 0.0
	return max(100.0, _toast_width() - padding.x * 2.0 - border)


func _target_y() -> float:
	var vp_h: float = get_viewport().get_visible_rect().size.y
	if toast_position == ToastPosition.TOP:
		return top_margin
	return vp_h - _panel.size.y - bottom_margin


## Posición fuera de pantalla desde donde entra y hacia donde sale
func _hidden_y() -> float:
	if toast_position == ToastPosition.TOP:
		return -_panel.size.y - 10.0
	return get_viewport().get_visible_rect().size.y + 10.0


func _toast_width() -> float:
	var ratio: float = width_ratio if _is_card() else subtitles_width_ratio
	return get_viewport().get_visible_rect().size.x * ratio


func _on_viewport_resized() -> void:
	if not _panel.visible:
		return
	_apply_widths()
	_panel.position.x = (get_viewport().get_visible_rect().size.x - _panel.size.x) / 2.0
