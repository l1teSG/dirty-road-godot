class_name BossAttackComponent
extends Node2D

## ══════════════════════════════════════════════════════════
##  BOSS ATTACK COMPONENT — kits de ataque telegrafiados y muy visuales
##  para los jefes. Se configura por parámetros desde el Inspector.
##
##  Patrones (se activan por interruptor):
##   • meteoros    → lluvia de impactos en área con marca en el suelo
##   • rayo        → beam que barre/atraviesa (línea telegrafiada)
##   • onda        → onda expansiva desde el jefe
##   • abanico     → ráfaga de proyectiles en cono
##   • invocar     → genera minions
##   • aura_pulso  → pulso de daño en área
##
##  Todos avisan antes de golpear (justo y esquivable) y añaden
##  marcas, destellos y expansiones. NO requiere tocar Enemigo.gd.
## ══════════════════════════════════════════════════════════

@export_group("Ciclo")
@export var activo: bool = true
@export var primer_ataque: float = 2.0
@export var cooldown_min: float = 3.0
@export var cooldown_max: float = 5.0

@export_group("Ataques habilitados")
@export var meteoros: bool = false
@export var rayo: bool = false
@export var onda: bool = false
@export var abanico: bool = false
@export var invocar: bool = false
@export var aura_pulso: bool = false

@export_group("Meteoros")
@export var met_cantidad: int = 5
@export var met_radio: float = 85.0
@export var met_danio: float = 24.0
@export var met_aviso: float = 0.9
@export var met_dispersion: float = 160.0
@export var met_color: Color = Color(1.0, 0.55, 0.12, 0.6)

@export_group("Rayo")
@export var rayo_longitud: float = 950.0
@export var rayo_ancho: float = 26.0
@export var rayo_danio: float = 30.0
@export var rayo_aviso: float = 0.8
@export var rayo_color: Color = Color(1.0, 0.92, 0.35, 0.85)

@export_group("Onda")
@export var onda_radio: float = 320.0
@export var onda_danio: float = 26.0
@export var onda_color: Color = Color(1.0, 0.5, 0.2, 0.5)

@export_group("Abanico")
@export var ab_cantidad: int = 7
@export var ab_danio: float = 16.0
@export var ab_velocidad: float = 260.0
@export var ab_dispersion: float = 70.0
@export var ab_radio: float = 9.0
@export var ab_color: Color = Color(0.95, 0.4, 0.6, 1.0)

@export_group("Invocar")
@export var inv_cantidad: int = 3
@export var inv_escena: PackedScene
@export var inv_dispersion: float = 90.0

@export_group("Aura / pulso")
@export var pulso_radio: float = 150.0
@export var pulso_danio: float = 22.0
@export var pulso_color: Color = Color(0.7, 1.0, 0.3, 0.5)

var _e: Node2D = null
var _t: float = 0.0
var _vivo: bool = true


func _ready() -> void:
	_e = get_parent() as Node2D
	z_index = 41
	_t = primer_ataque
	if _e != null and _e.has_signal("murio"):
		_e.connect("murio", func(_x = null): _vivo = false)


func _process(delta: float) -> void:
	if not activo or not _vivo or _e == null or not is_instance_valid(_e):
		return
	_t -= delta
	if _t > 0.0:
		return
	_ejecutar_ataque()
	_t = randf_range(minf(cooldown_min, cooldown_max), maxf(cooldown_min, cooldown_max))


func _ejecutar_ataque() -> void:
	var opciones: Array = []
	if meteoros: opciones.append("meteoros")
	if rayo: opciones.append("rayo")
	if onda: opciones.append("onda")
	if abanico: opciones.append("abanico")
	if invocar: opciones.append("invocar")
	if aura_pulso: opciones.append("pulso")
	if opciones.is_empty():
		return
	var elegido: String = opciones.pick_random()
	_fx_pulso_jefe()
	match elegido:
		"meteoros": _atk_meteoros()
		"rayo": _atk_rayo()
		"onda": _atk_onda()
		"abanico": _atk_abanico()
		"invocar": _atk_invocar()
		"pulso": _atk_pulso()


# ───────────── ATAQUES ─────────────

func _atk_meteoros() -> void:
	var obj := _objetivo()
	var centro := obj.global_position if obj != null else _e.global_position
	for i in maxi(met_cantidad, 1):
		var pos := centro + Vector2(randf_range(-met_dispersion, met_dispersion), randf_range(-met_dispersion, met_dispersion))
		var marca := _crear_marca(pos, met_radio, met_color)
		var tw := marca.create_tween()
		tw.tween_property(marca, "scale", Vector2(0.25, 0.25), met_aviso)
		tw.tween_callback(func():
			_danio_punto(pos, met_radio, met_danio)
			_explosion(pos, met_radio, met_color)
			marca.queue_free()
		)


func _atk_rayo() -> void:
	var obj := _objetivo()
	if obj == null:
		return
	var origen := _e.global_position
	var dir := (obj.global_position - origen).normalized()
	var tel := _crear_rayo(origen, dir, rayo_longitud, rayo_ancho, Color(rayo_color.r, rayo_color.g, rayo_color.b, 0.3))
	var tw := tel.create_tween()
	tw.tween_property(tel, "modulate:a", 1.0, rayo_aviso)
	tw.tween_callback(func():
		var beam := _crear_rayo(origen, dir, rayo_longitud, rayo_ancho, rayo_color)
		_danio_rayo(origen, dir, rayo_longitud, rayo_ancho, rayo_danio)
		var btw := beam.create_tween()
		btw.tween_property(beam, "modulate:a", 0.0, 0.35)
		btw.tween_callback(beam.queue_free)
		tel.queue_free()
	)


func _atk_onda() -> void:
	var centro := _e.global_position
	var marca := _crear_marca(centro, onda_radio, onda_color)
	marca.scale = Vector2(0.15, 0.15)
	var tw := marca.create_tween()
	tw.tween_property(marca, "scale", Vector2.ONE, 0.45)
	tw.tween_callback(func():
		_danio_punto(centro, onda_radio, onda_danio)
		marca.queue_free()
	)


func _atk_abanico() -> void:
	var obj := _objetivo()
	if obj == null:
		return
	var escena := get_tree().current_scene
	if escena == null:
		return
	var base := (obj.global_position - _e.global_position).normalized()
	var n := maxi(ab_cantidad, 1)
	for i in n:
		var f := 0.0 if n <= 1 else (float(i) - float(n - 1) * 0.5) / (float(n - 1) * 0.5)
		var dir := base.rotated(deg_to_rad(ab_dispersion) * f)
		var p := ProyectilJefe.new()
		p.configurar(dir, ab_velocidad, ab_danio, ab_radio, ab_color, _e)
		p.global_position = _e.global_position
		escena.call_deferred("add_child", p)


func _atk_invocar() -> void:
	if inv_escena == null:
		return
	var escena := get_tree().current_scene
	if escena == null:
		return
	for i in maxi(inv_cantidad, 1):
		var m := inv_escena.instantiate() as Node2D
		if m == null:
			continue
		m.global_position = _e.global_position + Vector2(randf_range(-inv_dispersion, inv_dispersion), randf_range(-inv_dispersion, inv_dispersion))
		escena.call_deferred("add_child", m)


func _atk_pulso() -> void:
	var centro := _e.global_position
	_danio_punto(centro, pulso_radio, pulso_danio)
	_explosion(centro, pulso_radio, pulso_color)


# ───────────── DAÑO ─────────────

func _danio_punto(pos: Vector2, radio: float, danio: float) -> void:
	for g in ["jugador", "arbol"]:
		for n in get_tree().get_nodes_in_group(g):
			if n is Node2D and n.global_position.distance_to(pos) <= radio + 8.0:
				if n.has_method("recibir_danio"):
					if g == "arbol":
						n.call("recibir_danio", danio, _e)
					else:
						n.call("recibir_danio", danio)


func _danio_rayo(origen: Vector2, dir: Vector2, largo: float, ancho: float, danio: float) -> void:
	var fin := origen + dir * largo
	for g in ["jugador", "arbol"]:
		for n in get_tree().get_nodes_in_group(g):
			if n is Node2D and _dist_a_segmento(n.global_position, origen, fin) <= ancho * 0.5 + 14.0:
				if n.has_method("recibir_danio"):
					if g == "arbol":
						n.call("recibir_danio", danio, _e)
					else:
						n.call("recibir_danio", danio)


func _dist_a_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 <= 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return (a + ab * t).distance_to(p)


# ───────────── VISUAL ─────────────

func _objetivo() -> Node2D:
	var j := get_tree().get_first_node_in_group("jugador")
	if j is Node2D:
		return j
	var a := get_tree().get_first_node_in_group("arbol")
	if a is Node2D:
		return a
	return null


func _crear_marca(pos: Vector2, radio: float, color: Color) -> Node2D:
	var escena := get_tree().current_scene
	if escena == null:
		return Node2D.new()
	var n := Node2D.new()
	n.z_index = 58
	var r := radio
	var c := color
	n.draw.connect(func():
		n.draw_circle(Vector2.ZERO, r, Color(c.r, c.g, c.b, c.a * 0.3))
		n.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, c, 4.0)
	)
	n.global_position = pos
	escena.add_child(n)
	return n


func _crear_rayo(origen: Vector2, dir: Vector2, largo: float, ancho: float, color: Color) -> Node2D:
	var escena := get_tree().current_scene
	if escena == null:
		return Node2D.new()
	var n := Node2D.new()
	n.z_index = 59
	var l := largo
	var a := ancho
	var c := color
	n.draw.connect(func():
		n.draw_rect(Rect2(Vector2(0, -a * 0.5), Vector2(l, a)), Color(c.r, c.g, c.b, c.a * 0.6))
		n.draw_rect(Rect2(Vector2(0, -a * 0.15), Vector2(l, a * 0.3)), c)
	)
	n.global_position = origen
	n.rotation = dir.angle()
	n.modulate.a = 0.0
	escena.add_child(n)
	return n


func _explosion(pos: Vector2, radio: float, color: Color) -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return
	var n := Node2D.new()
	n.z_index = 60
	var r := radio
	var c := color
	n.draw.connect(func():
		n.draw_circle(Vector2.ZERO, r, c)
		n.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(1, 1, 1, 0.85), 3.0)
	)
	n.global_position = pos
	n.scale = Vector2(0.25, 0.25)
	escena.add_child(n)
	var tw := n.create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "scale", Vector2.ONE, 0.3)
	tw.tween_property(n, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(n.queue_free)


func _fx_pulso_jefe() -> void:
	# Pequeño "aviso" en el propio jefe al iniciar un ataque (estirón visual).
	if _e != null and _e.has_method("_fx_ataque"):
		_e.call("_fx_ataque")
