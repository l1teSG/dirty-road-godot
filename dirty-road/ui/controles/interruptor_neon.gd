extends BaseButton
class_name InterruptorNeon

## Interruptor (toggle) propio con estilo del juego: pastilla + perilla.

var color: Color = Color("99ff33")


func _ready() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(104, 56)
	toggled.connect(func(_v: bool) -> void: queue_redraw())
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var r := h * 0.5
	var on := button_pressed
	var track := color if on else Color(0.16, 0.21, 0.19)
	draw_circle(Vector2(r, r), r, track)
	draw_circle(Vector2(w - r, r), r, track)
	draw_rect(Rect2(r, 0, w - 2.0 * r, h), track, true)
	# borde
	draw_arc(Vector2(r, r), r, PI * 0.5, PI * 1.5, 16, Color(0, 0, 0, 0.4), 3.0)
	var kx := (w - r) if on else r
	draw_circle(Vector2(kx, r), r - 5.0, Color(0.05, 0.1, 0.07))
	draw_circle(Vector2(kx, r), r - 5.0, Color(1, 1, 1, 0.15), false, 2.0)
