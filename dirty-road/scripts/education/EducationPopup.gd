extends CanvasLayer

# EducationPopup
# Toast inferior reutilizable. Se construye por código, no pausa el juego
# y encola mensajes.
#
# API:
#   enqueue(text: String, variant: int, duration: float = -1.0, subtitle: String = "") -> void
#   signal popup_finished
#
# "text" puede traer título en la primera línea: "Título\nCuerpo".
# "subtitle" es opcional (ej. "Etapa 3 · Océanos y plástico").

signal popup_finished

@export_category("Layout")
@export var bottom_margin: float = 70.0
@export_range(0.2, 1.0) var width_ratio: float = 0.5
@export var toast_height: float = 200.0
@export var slide_in: float = 0.35
@export var slide_out: float = 0.35
@export var default_duration: float = 3.5

@export_category("Texto")
@export var title_font_size: int = 28
@export var subtitle_font_size: int = 18
@export var body_font_size: int = 24

@export_category("Colores")
@export var bg_color: Color = Color(0.0, 0.0, 0.0, 0.8)
@export var title_color: Color = Color(0.6, 1.0, 0.55)
@export var body_color: Color = Color(1, 1, 1)
@export var color_wave_break: Color = Color(0.45, 0.9, 0.45)
@export var color_death: Color = Color(0.75, 0.85, 0.55)
@export var color_enemy_card: Color = Color(0.4, 0.85, 0.8)
@export var color_survival: Color = Color(0.5, 0.95, 0.5)

var _panel: Panel
var _style: StyleBoxFlat
var _title_label: Label
var _subtitle_label: Label
var _body_label: Label
var _tween: Tween
var _queue: Array = []
var _busy: bool = false
var _current_text: String = ""

# 0 WAVE_BREAK, 1 DEATH, 2 ENEMY_CARD, 3 SURVIVAL
var _default_titles: Dictionary = {
	0: "Dato Ambiental",
	1: "Reflexión",
	2: "Nueva Amenaza",
	3: "¿Sabías qué?"
}


func _ready() -> void:
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS

	_panel = Panel.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.size = Vector2(_toast_width(), toast_height)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_title_label = _make_label(title_font_size)
	vbox.add_child(_title_label)

	_subtitle_label = _make_label(subtitle_font_size)
	_subtitle_label.modulate = Color(1, 1, 1, 0.7)
	_subtitle_label.visible = false
	vbox.add_child(_subtitle_label)

	_body_label = _make_label(body_font_size)
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_label.add_theme_color_override("font_color", body_color)
	vbox.add_child(_body_label)

	_apply_style()
	get_viewport().size_changed.connect(_on_viewport_resized)


func _make_label(font_size: int) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.add_theme_font_size_override("font_size", font_size)
	return l


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

	_configure_content(data["text"], data["variant"], data["subtitle"])
	_position_toast()

	var start_y: float = get_viewport().get_visible_rect().size.y + 10.0
	var end_y: float = _target_y()

	_panel.position.y = start_y
	_panel.visible = true

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "position:y", end_y, slide_in)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
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
	var title: String = _default_titles.get(variant, "")
	var body: String = text

	var idx: int = text.find("\n")
	if idx != -1:
		title = text.substr(0, idx)
		body = text.substr(idx + 1).replace("\n", "  ·  ")

	var accent: Color = _variant_color(variant)
	_title_label.text = title
	_title_label.add_theme_color_override("font_color", title_color)
	_subtitle_label.text = subtitle
	_subtitle_label.visible = subtitle != ""
	_subtitle_label.add_theme_color_override("font_color", title_color)
	_body_label.text = body
	_style.border_color = accent


func _variant_color(variant: int) -> Color:
	match variant:
		0: return color_wave_break
		1: return color_death
		2: return color_enemy_card
		3: return color_survival
	return color_wave_break


func _position_toast() -> void:
	_panel.size = Vector2(_toast_width(), toast_height)
	_panel.position.x = (get_viewport().get_visible_rect().size.x - _panel.size.x) / 2.0


func _target_y() -> float:
	return get_viewport().get_visible_rect().size.y - toast_height - bottom_margin


func _toast_width() -> float:
	return get_viewport().get_visible_rect().size.x * width_ratio


func _on_viewport_resized() -> void:
	if not _panel.visible:
		return
	# Recalcula tamaño y X; el tween sigue controlando Y.
	_panel.size = Vector2(_toast_width(), toast_height)
	_panel.position.x = (get_viewport().get_visible_rect().size.x - _panel.size.x) / 2.0


func _apply_style() -> void:
	_style = StyleBoxFlat.new()
	_style.bg_color = bg_color
	_style.set_corner_radius_all(16)
	_style.set_border_width_all(2)
	_style.border_color = color_wave_break
	_panel.add_theme_stylebox_override("panel", _style)
