extends Control
class_name SliderNeon

## Slider propio con estilo del juego (pista + perilla neón), táctil.

signal value_changed(v: float)

var min_value: float = 0.0
var max_value: float = 1.0
var step: float = 0.05
var value: float = 0.0
var color: Color = Color("99ff33")

var _arrastrando: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(360, 56)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func set_value(v: float) -> void:
	value = clampf(v, min_value, max_value)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_arrastrando = mb.pressed
			if mb.pressed:
				_desde_x(mb.position.x)
	elif event is InputEventMouseMotion and _arrastrando:
		_desde_x((event as InputEventMouseMotion).position.x)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		_arrastrando = st.pressed
		if st.pressed:
			_desde_x(st.position.x)
	elif event is InputEventScreenDrag:
		_desde_x((event as InputEventScreenDrag).position.x)


func _desde_x(x: float) -> void:
	var t := clampf(x / maxf(size.x, 1.0), 0.0, 1.0)
	var v := min_value + t * (max_value - min_value)
	if step > 0.0:
		v = round(v / step) * step
	v = clampf(v, min_value, max_value)
	if not is_equal_approx(v, value):
		value = v
		value_changed.emit(v)
	queue_redraw()


func _draw() -> void:
	var cy := size.y * 0.5
	var x0 := 12.0
	var x1 := size.x - 12.0
	draw_line(Vector2(x0, cy), Vector2(x1, cy), Color(0, 0, 0, 0.55), 12.0)
	var t := (value - min_value) / maxf(max_value - min_value, 0.001)
	var xv := lerpf(x0, x1, t)
	draw_line(Vector2(x0, cy), Vector2(xv, cy), color, 8.0)
	draw_circle(Vector2(xv, cy), 17.0, color)
	draw_circle(Vector2(xv, cy), 9.0, Color(0.05, 0.1, 0.07))
