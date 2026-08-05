extends CanvasLayer

# ---------------------------------------------------------------------------
# EducationPopup
# Single reusable popup used by EducationManager for all 4 educational
# features. Presented as a compact bottom "toast" so it never blocks
# gameplay or the existing HUD. Built entirely in code (no .tscn
# dependency). Never pauses the game, animates in/out, queues messages
# if triggered close together.
#
# Public API (unchanged):
#   enqueue(text: String, variant: int, duration: float = 3.0) -> void
#   signal popup_finished
# ---------------------------------------------------------------------------

signal popup_finished

const BOTTOM_MARGIN: float = 30.0
const WIDTH_RATIO: float = 0.38   # ~35-40% of screen width
const TOAST_HEIGHT: float = 90.0
const SLIDE_DURATION_IN: float = 0.35
const SLIDE_DURATION_OUT: float = 0.35
const DEFAULT_VISIBLE_DURATION: float = 3.5

var _panel: Panel
var _title_label: Label
var _body_label: Label
var _queue: Array = []
var _busy: bool = false

# Fallback titles shown when the message text has no explicit title line
# (i.e. no "\n" separating a first line from the rest).
var _default_titles: Dictionary = {
	0: "Dato Ambiental",     # WAVE_BREAK
	1: "Reflexión",          # DEATH
	2: "Nueva Amenaza",      # ENEMY_CARD
	3: "¿Sabías qué?"        # SURVIVAL
}


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_panel = Panel.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.size = Vector2(_toast_width(), TOAST_HEIGHT)
	add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_title_label = Label.new()
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_title_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.55))
	_title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_title_label)

	_body_label = Label.new()
	_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_body_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_body_label)

	_apply_style()

	# Keep the toast centered/sized correctly if the viewport is resized.
	get_viewport().size_changed.connect(_on_viewport_resized)


func enqueue(text: String, variant: int, duration: float = DEFAULT_VISIBLE_DURATION) -> void:
	_queue.append({"text": text, "variant": variant, "duration": duration})
	if not _busy:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_busy = false
		return

	_busy = true
	var data: Dictionary = _queue.pop_front()

	_configure_content(data["text"], data["variant"])
	_position_toast()

	var start_y: float = get_viewport().get_visible_rect().size.y + 10.0
	var end_y: float = _target_y()

	_panel.position.y = start_y
	_panel.visible = true
	_panel.modulate.a = 1.0

	var tween: Tween = create_tween()
	tween.tween_property(_panel, "position:y", end_y, SLIDE_DURATION_IN)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(data["duration"])
	tween.tween_property(_panel, "position:y", start_y, SLIDE_DURATION_OUT)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(self, "_on_hidden"))


func _on_hidden() -> void:
	_panel.visible = false
	popup_finished.emit()
	_show_next()


func _configure_content(text: String, variant: int) -> void:
	var title: String = _default_titles.get(variant, "")
	var body: String = text

	var newline_index: int = text.find("\n")
	if newline_index != -1:
		title = text.substr(0, newline_index)
		body = text.substr(newline_index + 1).replace("\n", "  ·  ")

	_title_label.text = title
	_body_label.text = body

	_apply_border_color(variant)


func _position_toast() -> void:
	_panel.size = Vector2(_toast_width(), TOAST_HEIGHT)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_panel.position.x = (viewport_size.x - _panel.size.x) / 2.0


func _target_y() -> float:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	return viewport_size.y - TOAST_HEIGHT - BOTTOM_MARGIN


func _toast_width() -> float:
	return get_viewport().get_visible_rect().size.x * WIDTH_RATIO


func _on_viewport_resized() -> void:
	if _panel.visible:
		_position_toast()
		_panel.position.y = _target_y()


func _apply_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.8)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.9, 0.45, 1.0)
	_panel.add_theme_stylebox_override("panel", style)


func _apply_border_color(variant: int) -> void:
	var style: StyleBoxFlat = _panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return

	match variant:
		0: # WAVE_BREAK
			style.border_color = Color(0.45, 0.9, 0.45, 1.0)
		1: # DEATH
			style.border_color = Color(0.75, 0.85, 0.55, 1.0)
		2: # ENEMY_CARD
			style.border_color = Color(0.4, 0.85, 0.8, 1.0)
		3: # SURVIVAL
			style.border_color = Color(0.5, 0.95, 0.5, 1.0)
