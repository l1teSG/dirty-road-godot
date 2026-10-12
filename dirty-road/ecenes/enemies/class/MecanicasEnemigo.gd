class_name MecanicasEnemigo
extends Node2D

## ══════════════════════════════════════════════════════════
##  MECÁNICAS ENEMIGO — componente reutilizable (hijo de cada enemigo).
##  Añade las mecánicas especiales que pide el diseño, configuradas
##  por parámetros desde el Inspector. Todo visual y auto-contenido:
##  NO requiere tocar Enemigo.gd.
##
##  Mecánicas:
##   • es_aereo         → levanta la figura (vuela, solo visual)
##   • aura_danio       → daño periódico en área
##   • aura_ralentiza   → ralentiza al jugador dentro del radio
##   • explota_al_morir → explosión en área al morir
##   • divide_al_morir  → spawnea hijxs al morir
##   • deja_zona        → deja una zona de daño al morir
##   • rastro_danio     → deja zonas de daño mientras vive
##   • regeneracion_hps → se cura con el tiempo (tras un retraso)
## ══════════════════════════════════════════════════════════

@export_group("Aéreo (visual)")
@export var es_aereo: bool = false
@export var aereo_altura: float = 22.0

@export_group("Aura de daño")
@export var aura_danio: bool = false
@export var aura_radio: float = 95.0
@export var aura_dps: float = 10.0
@export var aura_periodo: float = 0.5
@export var aura_color: Color = Color(0.85, 0.25, 0.35, 0.16)

@export_group("Aura de ralentización")
@export var aura_ralentiza: bool = false
@export var ralentiza_radio: float = 120.0
@export var ralentiza_pct: float = 0.35
@export var ralentiza_duracion: float = 0.4
@export var ralentiza_color: Color = Color(0.35, 0.65, 1.0, 0.16)

@export_group("Explosión al morir")
@export var explota_al_morir: bool = false
@export var explota_radio: float = 95.0
@export var explota_danio: float = 30.0
@export var explota_color: Color = Color(1.0, 0.55, 0.1, 0.6)

@export_group("División al morir")
@export var divide_al_morir: bool = false
@export var divide_cantidad: int = 2
@export var divide_vida_pct: float = 0.4

@export_group("Zona / rastro de daño")
@export var deja_zona: bool = false
@export var rastro_danio: bool = false
@export var hazard_radio: float = 60.0
@export var hazard_danio: float = 7.0
@export var hazard_duracion: float = 4.0
@export var hazard_intervalo: float = 0.5
@export var rastro_intervalo: float = 0.7
@export var hazard_color: Color = Color(0.55, 0.95, 0.25, 0.35)

@export_group("Regeneración")
@export var regeneracion_hps: float = 0.0
@export var regen_retraso: float = 3.0

var _e: Node2D = null
var _t_aura: float = 0.0
var _t_rastro: float = 0.0
var _t_regen: float = 0.0
var _muriente: bool = false


func _ready() -> void:
	_e = get_parent() as Node2D
	z_index = 39
	if es_aereo and _e != null:
		_levantar_figura()
	if _e != null and _e.has_signal("murio"):
		_e.connect("murio", _on_muerte)


func _levantar_figura() -> void:
	var fig := _e.get_node_or_null("FiguraConstructor")
	if fig != null:
		fig.position.y -= aereo_altura
	# Una sombra más grande y difusa ayuda a leer el vuelo.
	_e.z_index = maxi(_e.z_index, 5)
	var sombra := _e.find_child("Sombra", true, false)
	if sombra is Node2D:
		(sombra as Node2D).scale *= 1.3
		(sombra as Node2D).modulate.a *= 0.7


func _process(delta: float) -> void:
	if _e == null or not is_instance_valid(_e):
		return
	if aura_danio:
		_actualizar_aura(delta)
	if aura_ralentiza:
		_actualizar_ralentiza()
	if regeneracion_hps > 0.0:
		_actualizar_regen(delta)
	if rastro_danio:
		_actualizar_rastro(delta)
	queue_redraw()


# ───────────── AURA DE DAÑO ─────────────

func _actualizar_aura(delta: float) -> void:
	_t_aura -= delta
	if _t_aura > 0.0:
		return
	_t_aura = maxf(aura_periodo, 0.1)
	var d := aura_dps * maxf(aura_periodo, 0.1)
	for n in get_tree().get_nodes_in_group("jugador"):
		if n is Node2D and n.global_position.distance_to(_e.global_position) <= aura_radio + 8.0:
			if n.has_method("recibir_danio"):
				n.call("recibir_danio", d)
	for n in get_tree().get_nodes_in_group("arbol"):
		if n is Node2D and n.global_position.distance_to(_e.global_position) <= aura_radio + 8.0:
			if n.has_method("recibir_danio"):
				n.call("recibir_danio", d, _e)


# ───────────── AURA DE RALENTIZACIÓN ─────────────

func _actualizar_ralentiza() -> void:
	for n in get_tree().get_nodes_in_group("jugador"):
		if n is Node2D and n.global_position.distance_to(_e.global_position) <= ralentiza_radio + 8.0:
			if n.has_method("aplicar_ralentizado"):
				n.call("aplicar_ralentizado", ralentiza_pct, ralentiza_duracion)


# ───────────── REGENERACIÓN ─────────────

func _actualizar_regen(delta: float) -> void:
	if _e.get("vida_actual") == null:
		return
	var vida := float(_e.get("vida_actual"))
	var vida_max := float(_e.get("life"))
	if vida <= 0.0 or vida >= vida_max:
		return
	# El retraso se reinicia cuando el enemigo recibe daño.
	if _e.has_signal("recibo_danio") and not _e.is_connected("recibo_danio", _reset_regen):
		_e.connect("recibo_danio", _reset_regen)
	_t_regen += delta
	if _t_regen >= regen_retraso:
		_e.set("vida_actual", minf(vida + regeneracion_hps * delta, vida_max))


func _reset_regen(_c: float = 0.0) -> void:
	_t_regen = 0.0


# ───────────── RASTRO ─────────────

func _actualizar_rastro(delta: float) -> void:
	if _muriente:
		return
	_t_rastro -= delta
	if _t_rastro > 0.0:
		return
	_t_rastro = maxf(rastro_intervalo, 0.15)
	_spawn_hazard(_e.global_position)


# ───────────── MUERTE ─────────────

func _on_muerte(_enemigo: Node = null) -> void:
	if _muriente:
		return
	_muriente = true
	if explota_al_morir:
		_explotar()
	if deja_zona:
		_spawn_hazard(_e.global_position)
	if divide_al_morir:
		_dividir()


func _explotar() -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return
	_danio_radio(explota_radio, explota_danio, explota_color, 0.35, explota_radio)


func _spawn_hazard(pos: Vector2) -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return
	var h := HazardEnemigo.new()
	h.configurar(hazard_radio, hazard_danio, hazard_intervalo, hazard_duracion, hazard_color, _e)
	h.global_position = pos
	escena.call_deferred("add_child", h)


func _dividir() -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return
	var escena_hijo: PackedScene = null
	var ruta := _e.scene_file_path
	if ruta != "":
		escena_hijo = load(ruta) as PackedScene
	if escena_hijo == null:
		return
	var cantidad := maxi(divide_cantidad, 1)
	for i in cantidad:
		var hijx := escena_hijo.instantiate() as Node2D
		if hijx == null:
			continue
		var vida := float(_e.get("life")) * divide_vida_pct
		hijx.set("life", vida)
		hijx.set("damage", float(_e.get("damage")) * 0.6)
		# Que lxs hijxs no vuelvan a dividirse (evita crecimiento infinito).
		var mec := hijx.get_node_or_null("Mecanicas")
		if mec != null:
			mec.set("divide_al_morir", false)
			mec.set("rastro_danio", false)
			mec.set("explota_al_morir", false)
			mec.set("deja_zona", false)
		hijx.scale *= 0.75
		hijx.global_position = _e.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		escena.call_deferred("add_child", hijx)


func _danio_radio(radio: float, danio: float, color: Color, dur: float, radio_visual: float) -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return
	for n in get_tree().get_nodes_in_group("jugador"):
		if n is Node2D and n.global_position.distance_to(_e.global_position) <= radio + 8.0:
			if n.has_method("recibir_danio"):
				n.call("recibir_danio", danio)
	for n in get_tree().get_nodes_in_group("arbol"):
		if n is Node2D and n.global_position.distance_to(_e.global_position) <= radio + 8.0:
			if n.has_method("recibir_danio"):
				n.call("recibir_danio", danio, _e)
	# Visual de explosión (círculo que se expande y desvanece).
	var vis := Node2D.new()
	vis.z_index = 60
	var r := radio_visual
	vis.draw.connect(func():
		vis.draw_circle(Vector2.ZERO, r, color)
		vis.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(1, 1, 1, 0.8), 3.0)
	)
	vis.global_position = _e.global_position
	vis.scale = Vector2(0.2, 0.2)
	escena.add_child(vis)
	var tw := vis.create_tween()
	tw.set_parallel(true)
	tw.tween_property(vis, "scale", Vector2.ONE, dur)
	tw.tween_property(vis, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(vis.queue_free)


# ───────────── VISUAL DE AURA ─────────────

func _draw() -> void:
	if _e == null or not is_instance_valid(_e):
		return
	var off := _e.global_position - global_position
	if aura_danio:
		var a := aura_radio
		draw_circle(off, a, aura_color)
		draw_arc(off, a, 0.0, TAU, 48, Color(aura_color.r, aura_color.g, aura_color.b, minf(aura_color.a + 0.25, 1.0)), 1.5)
	if aura_ralentiza:
		draw_arc(off, ralentiza_radio, 0.0, TAU, 48, Color(ralentiza_color.r, ralentiza_color.g, ralentiza_color.b, minf(ralentiza_color.a + 0.25, 1.0)), 1.5)
