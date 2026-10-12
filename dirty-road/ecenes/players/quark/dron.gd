extends Node2D
class_name DronConservacionista

## Dron compañero: orbita al jugador y dispara al enemigo más cercano.
## Se crea cuando el jugador tiene el stat "jugador.dron".

const PROYECTIL := preload("res://ecenes/players/projectile/quark/playerProyectil.tscn")

var jugador: Node2D = null
var radio: float = 54.0
var cadencia: float = 0.8
var danio: float = 8.0

var _t: float = 0.0
var _ang: float = 0.0


func _ready() -> void:
	z_index = 12
	var cuerpo := Polygon2D.new()
	cuerpo.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(9, -3), Vector2(6, 9), Vector2(-6, 9), Vector2(-9, -3)])
	cuerpo.color = Color("99ff33")
	add_child(cuerpo)
	var nucleo := Polygon2D.new()
	nucleo.polygon = PackedVector2Array([
		Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0)])
	nucleo.color = Color(0.05, 0.1, 0.07)
	add_child(nucleo)


func _process(delta: float) -> void:
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D
		if jugador == null:
			return
	_ang += delta * 1.2
	global_position = jugador.global_position + Vector2.RIGHT.rotated(_ang) * radio
	rotation = _ang
	_t -= delta
	if _t <= 0.0:
		_t = maxf(cadencia, 0.2)
		_disparar()


func _disparar() -> void:
	var objetivo := _mas_cercano()
	if objetivo == null:
		return
	var dir := (objetivo.global_position - global_position).normalized()
	var b = PROYECTIL.instantiate()
	if b == null:
		return
	b.scale = Vector2(0.4, 0.4)
	b.rotation = dir.angle()
	b.add_to_group("bullet")
	b.global_position = global_position
	b.positionEnemi = dir
	b.set("dano", danio)
	b.set("sped", 440.0)
	b.set("vida_util", 1.6)
	get_tree().current_scene.add_child(b)


func _mas_cercano() -> Node2D:
	var mejor: Node2D = null
	var dist := 9.0e9
	for e in get_tree().get_nodes_in_group("enemigos"):
		if e is Node2D:
			var d := global_position.distance_squared_to((e as Node2D).global_position)
			if d < dist:
				dist = d
				mejor = e as Node2D
	return mejor
