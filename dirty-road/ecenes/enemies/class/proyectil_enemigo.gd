class_name ProyectilEnemigo
extends Node2D

## ══════════════════════════════════════════════════════════
##  PROYECTIL ENEMIGO — temático y por código (sin escenas).
##  Lo usan los enemigos de rango/torreta cuando su `proyectil` está vacío.
##
##  • ESTILO visual según el material del enemigo: humo, acido, fuego,
##    toxico, electrico, agua o generico.
##  • ESTELA: guarda las últimas posiciones y dibuja un rastro que se
##    desvanece, para que la trayectoria quede marcada en vuelo.
##  • Impacta UNA vez al jugador o al árbol y se desvanece. Al árbol le
##    pasa `fuente` (el enemigo que disparó) para atribución/espinas.
##  • Se registra en el grupo 'proyectil_enemigo' (el WaveManager lo limpia).
## ══════════════════════════════════════════════════════════

var direccion: Vector2 = Vector2.RIGHT
var velocidad: float = 220.0
var danio: float = 6.0
var radio: float = 8.0
var color: Color = Color(0.35, 0.9, 0.5, 1.0)
var estilo: String = "generico"
var vida_util: float = 4.0
var fuente: Node = null

var _vida: float = 0.0
var _muerto: bool = false
var _golpeado: bool = false
var _trail: Array[Vector2] = []
const TRAIL_MAX := 14


## Compatible con la cadena de disparar_desde(): (dir, danio) + overrides.
func configurar(dir: Vector2, danio_nuevo: float,
		color_override: Color = Color(0, 0, 0, 0), radio_override: float = -1.0) -> void:
	direccion = dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT
	danio = danio_nuevo
	_aplicar_estilo()
	if color_override.a > 0.0:
		color = color_override
	if radio_override > 0.0:
		radio = radio_override
	rotation = direccion.angle()


func _ready() -> void:
	z_index = 50
	add_to_group("proyectil_enemigo")
	rotation = direccion.angle()


## Color y tamaño base por estilo (se puede sobreescribir en configurar()).
func _aplicar_estilo() -> void:
	match estilo:
		"humo":
			color = Color(0.72, 0.76, 0.78, 0.85)
			radio = maxf(radio, 13.0)
		"acido":
			color = Color(0.55, 0.95, 0.25, 1.0)
		"fuego":
			color = Color(1.0, 0.55, 0.15, 1.0)
		"toxico":
			color = Color(0.72, 0.35, 0.95, 1.0)
		"electrico":
			color = Color(1.0, 0.95, 0.35, 1.0)
		"agua":
			color = Color(0.35, 0.7, 1.0, 1.0)
		_:
			color = Color(0.35, 0.9, 0.5, 1.0)


func _process(delta: float) -> void:
	if _muerto:
		return
	_vida += delta
	global_position += direccion * velocidad * delta
	_trail.append(global_position)
	if _trail.size() > TRAIL_MAX:
		_trail.pop_front()
	queue_redraw()
	if _vida >= vida_util:
		queue_free()
		return
	_comprobar_impacto()


func _comprobar_impacto() -> void:
	if _golpeado:
		return
	for g in ["jugador", "arbol"]:
		for n in get_tree().get_nodes_in_group(g):
			if not (n is Node2D):
				continue
			if n.global_position.distance_to(global_position) > radio + 14.0:
				continue
			if n.has_method("recibir_danio"):
				if g == "arbol":
					n.call("recibir_danio", danio, fuente if fuente != null else self)
				else:
					n.call("recibir_danio", danio)
			_golpeado = true
			_desvanecer()
			return


func _desvanecer() -> void:
	_muerto = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(queue_free)


func _draw() -> void:
	# Estela: rastro que se desvanece hacia atrás.
	var n := _trail.size()
	for i in n:
		var t := float(i) / float(maxi(n, 1))
		var p := to_local(_trail[i])
		draw_circle(p, radio * (0.3 + 0.45 * t), Color(color.r, color.g, color.b, 0.28 * t))
	# Cuerpo por estilo (en coordenadas locales; el nodo está rotado).
	match estilo:
		"humo":
			draw_circle(Vector2.ZERO, radio, Color(color.r, color.g, color.b, 0.5))
			draw_circle(Vector2.ZERO, radio * 0.6, Color(color.r, color.g, color.b, 0.9))
		"electrico":
			var pts := PackedVector2Array([
				Vector2(-11, 0), Vector2(-4, -5), Vector2(0, 0), Vector2(4, 5), Vector2(11, 0)])
			draw_polyline(pts, color, 2.5)
			draw_circle(Vector2.ZERO, 3.0, Color(1, 1, 1, 0.9))
		_:
			draw_circle(Vector2.ZERO, radio, color)
			draw_circle(Vector2.ZERO, radio * 1.6, Color(color.r, color.g, color.b, 0.22))
			draw_circle(Vector2.ZERO, radio * 0.45, Color(1, 1, 1, 0.85))