extends CanvasLayer

# ---------------------------------------------------------------------------
# EducationPopup
# Single reusable popup used by EducationManager for all 4 educational
# features. Built entirely in code (no .tscn dependency). Never pauses
# the game, animates in/out, queues messages if triggered close together.
# ---------------------------------------------------------------------------

signal popup_finished

var _panel: Panel
var _label: Label
var _queue: Array = []
var _busy: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_panel = Panel.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_panel.add_child(_label)


func enqueue(text: String, variant: int, duration: float = 3.0) -> void:
	_queue.append({"text": text, "variant": variant, "duration": duration})
	if not _busy:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_busy = false
		return

	_busy = true
	var data: Dictionary = _queue.pop_front()

	_configure_variant(data["variant"])
	_label.text = data["text"]
	_panel.visible = true
	_panel.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(data["duration"])
	tween.tween_property(_panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(Callable(self, "_on_hidden"))


func _on_hidden() -> void:
	_panel.visible = false
	popup_finished.emit()
	_show_next()


func _configure_variant(variant: int) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	match variant:
		0: # WAVE_BREAK
			_panel.size = Vector2(420, 90)
			_panel.position = Vector2((viewport_size.x - 420) / 2.0, 40)
			_apply_color(Color(0.12, 0.35, 0.16, 0.85))
		1: # DEATH
			_panel.size = Vector2(500, 110)
			_panel.position = Vector2(
				(viewport_size.x - 500) / 2.0,
				(viewport_size.y - 110) / 2.0
			)
			_apply_color(Color(0.08, 0.2, 0.1, 0.9))
		2: # ENEMY_CARD
			_panel.size = Vector2(300, 110)
			_panel.position = Vector2(viewport_size.x - 320, 20)
			_apply_color(Color(0.1, 0.3, 0.32, 0.85))
		3: # SURVIVAL
			_panel.size = Vector2(320, 80)
			_panel.position = Vector2(viewport_size.x - 340, 20)
			_apply_color(Color(0.16, 0.4, 0.2, 0.85))


func _apply_color(color: Color) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	_panel.add_theme_stylebox_override("panel", style)
