class_name HazardEnemigo
extends Node2D

## ══════════════════════════════════════════════════════════
##  HAZARD — zona/rastro de daño persistente en el suelo.
##  Daña al jugador y al árbol que estén dentro de su radio
##  cada `intervalo` segundos, y se desvanece tras `duracion`.
##  Se registra en el grupo 'proyectil_enemigo' para que el
##  WaveManager lo limpie al cerrar la oleada.
##  Se construye 100% por código (sin escena).
## ══════════════════════════════════════════════════════════

var radio: float = 60.0
var danio: float = 8.0
var intervalo: float = 0.5
var duracion: float = 4.0
var color: Color = Color(0.55, 0.95, 0.25, 0.35)
var fuente: Node = null

var _t: float = 0.0
var _vida: float = 0.0


func configurar(p_radio: float, p_danio: float, p_intervalo: float, p_duracion: float, p_color: Color, p_fuente: Node = null) -> void:
	radio = maxf(p_radio, 8.0)
	danio = maxf(p_danio, 0.0)
	intervalo = maxf(p_intervalo, 0.1)
	duracion = maxf(p_duracion, 0.1)
	color = p_color
	fuente = p_fuente


func _ready() -> void:
	z_index = 40
	add_to_group("proyectil_enemigo")
	_t = 0.0  # primera pulsación inmediata


func _process(delta: float) -> void:
	_vida += delta
	_t -= delta
	if _t <= 0.0:
		_t = intervalo
		_danio_area()
	if _vida >= duracion:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var f := 1.0 - clampf(_vida / duracion, 0.0, 1.0)
	var c := Color(color.r, color.g, color.b, color.a * f)
	draw_circle(Vector2.ZERO, radio, c)
	draw_arc(Vector2.ZERO, radio, 0.0, TAU, 40, Color(color.r, color.g, color.b, minf(f + 0.25, 1.0)), 2.0)


func _danio_area() -> void:
	for n in get_tree().get_nodes_in_group("jugador"):
		if n is Node2D and n.global_position.distance_to(global_position) <= radio + 8.0:
			if n.has_method("recibir_danio"):
				n.call("recibir_danio", danio)
	for n in get_tree().get_nodes_in_group("arbol"):
		if n is Node2D and n.global_position.distance_to(global_position) <= radio + 8.0:
			if n.has_method("recibir_danio"):
				n.call("recibir_danio", danio, self)
