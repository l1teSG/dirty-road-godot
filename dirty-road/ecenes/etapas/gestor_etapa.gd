extends Node
class_name GestorEtapa

## ══════════════════════════════════════════════════════════
##  GESTOR DE ETAPA — da identidad propia a cada etapa:
##   · Tinte de ambiente (CanvasModulate)
##   · Partículas ambientales (color/dirección/cantidad)
##   · Banner "ETAPA N · TEMA"
##   · Peligro característico (zonas de daño temáticas)
##
##  Los temas son `TemaEtapa` (editables en el Inspector). Si dejas el
##  array vacío, usa los temas por defecto (las 10 etapas del juego).
## ══════════════════════════════════════════════════════════

@export var activar: bool = true
@export var temas: Array[TemaEtapa] = []

var _cm: CanvasModulate = null
var _part: CPUParticles2D = null
var _escenario: EscenarioEtapa = null
var _banner_raiz: Control = null
var _banner: Label = null
var _banner_sub: Label = null
var _banner_tween: Tween = null
var _wm: Node = null
var _tema: TemaEtapa = null
var _t_peligro: float = 0.0
var _activado: bool = false


func _ready() -> void:
	if not activar:
		return
	call_deferred("_iniciar")


func _iniciar() -> void:
	await get_tree().process_frame
	_cm = _buscar_canvas_modulate()
	_wm = get_tree().get_first_node_in_group("wave_manager")
	_crear_particulas()
	_crear_banner()
	# Escenario procedural (terreno nuevo por etapa).
	_escenario = EscenarioEtapa.new()
	_escenario.name = "Escenario"
	add_child(_escenario)
	if temas.is_empty():
		temas = _temas_por_defecto()
	if _wm != null and _wm.has_signal("etapa_iniciada"):
		_wm.etapa_iniciada.connect(_on_etapa)
		_on_etapa(int(_wm.get("etapa_actual_idx")), "")
	_activado = true


func _process(delta: float) -> void:
	if not _activado:
		return
	# Las partículas siguen a la cámara para cubrir la vista.
	if _part != null:
		var cam := get_viewport().get_camera_2d()
		if cam != null:
			_part.global_position = cam.get_screen_center_position()
	# Peligro característico.
	if _tema != null and _tema.peligro_activo:
		_t_peligro -= delta
		if _t_peligro <= 0.0:
			_t_peligro = maxf(_tema.peligro_intervalo, 0.5)
			_spawn_peligro()


# ───────────── APLICAR TEMA ─────────────

func _on_etapa(idx: int, _nombre: String) -> void:
	if idx < 0 or idx >= temas.size():
		return
	_tema = temas[idx]
	_aplicar(_tema)
	if _escenario != null:
		_escenario.generar(idx, _tema)
	_mostrar_banner(idx, _tema)


func _aplicar(t: TemaEtapa) -> void:
	if _cm != null:
		_cm.color = t.color_ambiente
	if _part != null:
		_part.emitting = t.particulas_activas
		_part.amount = maxi(t.particulas_cantidad, 0)
		_part.direction = t.particulas_direccion
		_part.initial_velocity_min = t.particulas_velocidad * 0.6
		_part.initial_velocity_max = t.particulas_velocidad * 1.4
		_part.color = t.color_particulas
		_part.scale_amount_min = t.particulas_tamano
		_part.scale_amount_max = t.particulas_tamano * 2.0
	_t_peligro = 0.4


func _spawn_peligro() -> void:
	var escena := get_tree().current_scene
	if escena == null or _tema == null:
		return
	var centro := _centro_vista()
	var pos := centro + Vector2(randf_range(-260.0, 260.0), randf_range(-160.0, 160.0))
	var h := HazardEnemigo.new()
	h.configurar(_tema.peligro_radio, _tema.peligro_danio, 0.5, _tema.peligro_duracion, _tema.peligro_color, self)
	h.global_position = pos
	escena.call_deferred("add_child", h)


# ───────────── VDS ─────────────

func _crear_particulas() -> void:
	_part = CPUParticles2D.new()
	_part.z_index = 5
	_part.amount = 50
	_part.lifetime = 4.0
	_part.preprocess = 2.0
	_part.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_part.emission_rect_extents = Vector2(1100.0, 700.0)
	_part.direction = Vector2(0, 1)
	_part.spread = 25.0
	_part.gravity = Vector2.ZERO
	_part.initial_velocity_min = 40.0
	_part.initial_velocity_max = 90.0
	_part.scale_amount_min = 2.0
	_part.scale_amount_max = 4.0
	_part.color = Color(0.6, 0.9, 0.4, 0.8)
	_part.emitting = true
	get_parent().call_deferred("add_child", _part)


func _crear_banner() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 30
	add_child(capa)
	_banner_raiz = CenterContainer.new()
	_banner_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner_raiz.offset_top = -140.0
	_banner_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_banner_raiz)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.modulate.a = 1.0
	_banner_raiz.add_child(vb)
	_banner = Label.new()
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	EstiloUI.titulo(_banner, 96, EstiloUI.NEON)
	vb.add_child(_banner)
	_banner_sub = Label.new()
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_sub.add_theme_font_override("font", EstiloUI.F_SEMI)
	_banner_sub.add_theme_font_size_override("font_size", 36)
	_banner_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_banner_sub.add_theme_constant_override("outline_size", 5)
	vb.add_child(_banner_sub)
	_banner_raiz.modulate.a = 0.0


func _mostrar_banner(idx: int, t: TemaEtapa) -> void:
	if _banner == null:
		return
	_banner.text = "ETAPA %d" % (idx + 1)
	_banner_sub.text = t.nombre if t.nombre != "" else (t.peligro_nombre if t.peligro_nombre != "" else "")
	_banner.add_theme_color_override("font_color", t.banner_color)
	_banner_sub.add_theme_color_override("font_color", t.banner_color)
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_raiz.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner_raiz, "modulate:a", 1.0, 0.35)
	_banner_tween.tween_interval(1.9)
	_banner_tween.tween_property(_banner_raiz, "modulate:a", 0.0, 0.6)


# ───────────── HELPERS ─────────────

func _buscar_canvas_modulate() -> CanvasModulate:
	var raiz := get_tree().current_scene
	if raiz != null:
		var cm := raiz.get_node_or_null("CanvasModulate")
		if cm is CanvasModulate:
			return cm
	for n in get_tree().get_nodes_in_group("canvas_modulate"):
		if n is CanvasModulate:
			return n
	return null


func _centro_vista() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		return cam.get_screen_center_position()
	return Vector2.ZERO


func _temas_por_defecto() -> Array[TemaEtapa]:
	var out: Array[TemaEtapa] = []
	# 1 · Contaminación del suelo y el aire
	out.append(_crear_tema("Contaminación del suelo y aire",
		Color(0.85, 0.82, 0.72), Color(0.65, 0.58, 0.45, 0.7), 55, Vector2(0, 1), 60,
		Color(0.63, 0.49, 0.31)))
	# 2 · Basura y vertederos
	out.append(_crear_tema("Basura y vertederos",
		Color(0.76, 0.79, 0.70), Color(0.55, 0.6, 0.42, 0.8), 60, Vector2(0, 1), 75,
		Color(0.55, 0.62, 0.35), true, "Basura cayendo", Color(0.6, 0.55, 0.35, 0.4), 70.0, 6.0, 3.0, 3.0))
	# 3 · Océanos y plástico
	out.append(_crear_tema("Océanos y plástico",
		Color(0.62, 0.78, 0.96), Color(0.55, 0.85, 1.0, 0.7), 55, Vector2(0, -1), 55,
		Color(0.3, 0.75, 1.0)))
	# 4 · Contaminación industrial
	out.append(_crear_tema("Contaminación industrial",
		Color(0.80, 0.79, 0.80), Color(0.5, 0.5, 0.56, 0.7), 65, Vector2(0, 1), 65,
		Color(0.7, 0.7, 0.75), true, "Humo tóxico", Color(0.4, 0.4, 0.46, 0.35), 80.0, 7.0, 3.0, 3.5))
	# 5 · Lluvia ácida
	out.append(_crear_tema("Lluvia ácida",
		Color(0.80, 0.86, 0.60), Color(0.75, 0.95, 0.30, 0.85), 80, Vector2(0, 1), 120,
		Color(0.75, 0.95, 0.2), true, "Lluvia ácida", Color(0.7, 0.95, 0.2, 0.35), 70.0, 8.0, 2.0, 3.0))
	# 6 · Residuos electrónicos
	out.append(_crear_tema("Residuos electrónicos",
		Color(0.72, 0.80, 0.86), Color(0.6, 0.9, 1.0, 0.85), 60, Vector2(0, 1), 70,
		Color(0.4, 0.85, 1.0), true, "Descarga eléctrica", Color(0.5, 0.8, 1.0, 0.4), 75.0, 9.0, 2.6, 2.5))
	# 7 · Energía nuclear y radiación
	out.append(_crear_tema("Energía nuclear y radiación",
		Color(0.75, 0.88, 0.72), Color(0.6, 1.0, 0.3, 0.8), 60, Vector2(0, 1), 65,
		Color(0.6, 1.0, 0.3), true, "Aura radiactiva", Color(0.6, 1.0, 0.3, 0.35), 95.0, 10.0, 2.6, 3.5))
	# 8 · Pesticidas y agricultura
	out.append(_crear_tema("Pesticidas y agricultura",
		Color(0.81, 0.83, 0.62), Color(0.7, 0.9, 0.4, 0.6), 70, Vector2(0, 1), 60,
		Color(0.75, 0.9, 0.35), true, "Nube de fumigación", Color(0.7, 0.9, 0.4, 0.3), 85.0, 8.0, 3.0, 3.5))
	# 9 · Deforestación
	out.append(_crear_tema("Deforestación",
		Color(0.86, 0.73, 0.58), Color(0.9, 0.55, 0.25, 0.85), 65, Vector2(0, 1), 80,
		Color(0.95, 0.6, 0.2), true, "Focos de incendio", Color(1.0, 0.5, 0.15, 0.35), 85.0, 11.0, 2.6, 3.0))
	# 10 · Cambio climático
	out.append(_crear_tema("Cambio climático",
		Color(0.92, 0.74, 0.62), Color(1.0, 0.6, 0.2, 0.8), 70, Vector2(0, -1), 90,
		Color(1.0, 0.45, 0.2), true, "Ola de calor", Color(1.0, 0.4, 0.15, 0.35), 105.0, 13.0, 2.2, 3.0))
	return out


func _crear_tema(nombre: String, amb: Color, pcol: Color, pcant: int, pdir: Vector2, pvel: float,
		bcol: Color, peligro: bool = false, pnombre: String = "", pcolro: Color = Color(0.9, 0.4, 0.2, 0.35),
		pradio: float = 75.0, pdanio: float = 6.0, pint: float = 2.5, pdur: float = 3.0) -> TemaEtapa:
	var t := TemaEtapa.new()
	t.nombre = nombre
	t.color_ambiente = amb
	t.color_particulas = pcol
	t.particulas_cantidad = pcant
	t.particulas_direccion = pdir
	t.particulas_velocidad = pvel
	t.banner_color = bcol
	t.peligro_activo = peligro
	t.peligro_nombre = pnombre
	t.peligro_color = pcolro
	t.peligro_radio = pradio
	t.peligro_danio = pdanio
	t.peligro_intervalo = pint
	t.peligro_duracion = pdur
	# Paleta de terreno derivada del ambiente de la etapa.
	t.color_suelo = Color(amb.r * 0.66, amb.g * 0.72, amb.b * 0.55)
	t.color_suelo_detalle = Color(amb.r * 0.5, amb.g * 0.56, amb.b * 0.4)
	t.color_borde = Color(amb.r * 0.2, amb.g * 0.24, amb.b * 0.2)
	t.color_props = Color(amb.r * 0.75, amb.g * 0.68, amb.b * 0.55)
	return t
