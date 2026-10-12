class_name ProyectilJefe
extends Node2D

## Proyectil de jefe construido por código: viaja en línea, gira, daña al
## jugador y al árbol al impactar y se desvanece. Muy visual (núcleo + halo).
## Se registra en 'proyectil_enemigo' para que el WaveManager lo limpie.

var direccion: Vector2 = Vector2.RIGHT
var velocidad: float = 260.0
var danio: float = 18.0
var radio: float = 10.0
var color: Color = Color(0.9, 0.4, 0.6, 1.0)
var vida_util: float = 6.0
var fuente: Node = null

var _vida: float = 0.0
var _muerto: bool = false
var _golpeados: Dictionary = {}


func configurar(p_dir: Vector2, p_vel: float, p_danio: float, p_radio: float, p_color: Color, p_fuente: Node = null) -> void:
	direccion = p_dir.normalized() if p_dir != Vector2.ZERO else Vector2.RIGHT
	velocidad = p_vel
	danio = p_danio
	radio = maxf(p_radio, 3.0)
	color = p_color
	fuente = p_fuente


func _ready() -> void:
	z_index = 55
	add_to_group("proyectil_enemigo")
	rotation = direccion.angle()


func _process(delta: float) -> void:
	if _muerto:
		return
	_vida += delta
	global_position += direccion * velocidad * delta
	# Destello pulsante.
	queue_redraw()
	if _vida >= vida_util:
		queue_free()
		return
	_comprobar_impacto()


func _comprobar_impacto() -> void:
	for g in ["jugador", "arbol"]:
		for n in get_tree().get_nodes_in_group(g):
			if not (n is Node2D) or _golpeados.has(n.get_instance_id()):
				continue
			if n.global_position.distance_to(global_position) <= radio + 14.0:
				_golpeados[n.get_instance_id()] = true
				if n.has_method("recibir_danio"):
					if g == "arbol":
						n.call("recibir_danio", danio, fuente)
					else:
						n.call("recibir_danio", danio)
				if g == "jugador":
					_explotar()


func _explotar() -> void:
	_muerto = true
	var escena := get_tree().current_scene
	if escena != null:
		_danio_area()
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.8, 0.1)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(queue_free)


func _danio_area() -> void:
	for g in ["jugador", "arbol"]:
		for n in get_tree().get_nodes_in_group(g):
			if n is Node2D and n.global_position.distance_to(global_position) <= radio * 2.0:
				if n.has_method("recibir_danio"):
					if g == "arbol":
						n.call("recibir_danio", danio * 0.5, fuente)
					else:
						n.call("recibir_danio", danio * 0.5)


func _draw() -> void:
	var pulso := 1.0 + sin(_vida * 20.0) * 0.15
	draw_circle(Vector2.ZERO, radio * pulso, color)
	draw_circle(Vector2.ZERO, radio * 1.7 * pulso, Color(color.r, color.g, color.b, 0.22))
	draw_circle(Vector2.ZERO, radio * 0.5, Color(1, 1, 1, 0.85))
