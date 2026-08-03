extends Node


signal biomasa_incrementada

const MAX_BIOMASA := 10
var contador: int = 0


func emitir_biomasa(desde_global: Vector2, destino_screen_pos: Vector2, canvas_layer: CanvasLayer) -> void:
	var orbe := _crear_orbe()
	var viewport = canvas_layer.get_viewport()
	var pos_pantalla = viewport.get_canvas_transform() * desde_global
	orbe.position = pos_pantalla
	canvas_layer.add_child(orbe)

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(orbe, 'position', destino_screen_pos, 0.5)
	tween.parallel().tween_property(orbe, 'scale', Vector2(0.2, 0.2), 0.5)
	tween.tween_callback(func():
		orbe.queue_free()
		_incrementar()
	)


func _crear_orbe() -> Node2D:
	var orbe := Node2D.new()
	orbe.z_index = 4096
	orbe.z_as_relative = false
	orbe.draw.connect(func():
		orbe.draw_circle(Vector2.ZERO, 8.0, Color(0.4, 1.0, 0.6))
		orbe.draw_circle(Vector2.ZERO, 4.0, Color(0.9, 1.0, 0.9))
	)
	orbe.queue_redraw()
	return orbe


func _incrementar() -> void:
	contador += 1
	if contador >= MAX_BIOMASA:
		contador = 0
	biomasa_incrementada.emit()


func reiniciar_biomasa() -> void:
	contador = 0
	biomasa_incrementada.emit()
