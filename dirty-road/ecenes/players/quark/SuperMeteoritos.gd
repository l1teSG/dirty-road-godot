class_name SuperMeteoritos
extends Node
## Super: un meteorito sobre cada enemigo vivo en el momento del lanzamiento.
## El punto de impacto se fija al lanzar (+ jitter), así que es esquivable.

const COLOR_ANILLO := Color(1.0, 0.3, 0.1, 0.9)
const COLOR_EXPLOSION := Color(1.0, 0.55, 0.1, 0.55)
const JITTER: float = 25.0

var danio: float = 40.0
var radio: float = 90.0
var tiempo_advertencia: float = 0.6
var retraso_entre: float = 0.08
var fuente: Node = null


func configurar(p_danio: float, p_radio: float, p_advertencia: float, p_retraso: float, p_fuente: Node) -> void:
	danio = p_danio
	radio = p_radio
	tiempo_advertencia = p_advertencia
	retraso_entre = p_retraso
	fuente = p_fuente


func lanzar() -> void:
	var i: int = 0
	for enemigo in EnemigosUtil.vivos(get_tree()):
		var pos: Vector2 = enemigo.global_position + Vector2(
			randf_range(-JITTER, JITTER), randf_range(-JITTER, JITTER))
		get_tree().create_timer(retraso_entre * i).timeout.connect(_spawn.bind(pos))
		i += 1


func _crear_marca(pos: Vector2) -> Node2D:
	var nodo := Node2D.new()
	nodo.z_index = 500
	get_tree().current_scene.add_child(nodo)
	nodo.global_position = pos
	return nodo


func _spawn(pos: Vector2) -> void:
	if get_tree().current_scene == null:
		return
	var r: float = radio
	var anillo := _crear_marca(pos)
	anillo.draw.connect(func():
		anillo.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, COLOR_ANILLO, 4.0)
	)
	anillo.queue_redraw()

	var tween: Tween = anillo.create_tween()
	tween.tween_property(anillo, "scale", Vector2(0.3, 0.3), tiempo_advertencia)
	tween.tween_callback(func():
		_impactar(pos)
		anillo.queue_free()
	)


func _impactar(pos: Vector2) -> void:
	if get_tree().current_scene == null:
		return
	var r: float = radio
	var explosion := _crear_marca(pos)
	explosion.draw.connect(func():
		explosion.draw_circle(Vector2.ZERO, r, COLOR_EXPLOSION)
	)
	explosion.queue_redraw()

	var tween: Tween = explosion.create_tween()
	tween.tween_property(explosion, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)

	var r2: float = r * r
	var origen: Node = fuente if is_instance_valid(fuente) else null
	for enemigo in EnemigosUtil.vivos(get_tree()):
		if enemigo.global_position.distance_squared_to(pos) <= r2:
			EnemigosUtil.danar(enemigo, danio, origen)
