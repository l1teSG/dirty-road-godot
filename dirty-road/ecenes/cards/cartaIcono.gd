class_name CartaIcono
extends Control

## ─────────────────────────────────────────────────────────────
##  CARTA ICONO — dibuja la figura vectorial de una carta.
##
##  Puente entre el sistema classShape (Node2D / Polygon2D) y la UI
##  (Control). Usa un SubViewportContainer → SubViewport con
##  own_world_2d = true, de modo que la figura se renderiza AISLADA
##  (no se cuela en el nivel ni su luz afecta al juego).
##  Incluye: fondo radial, luz de rareza y un bob idle.
## ─────────────────────────────────────────────────────────────

const FIGURA_ESCENA := preload("res://assets/stage/enemis/classShape/figura_constructor.tscn")

## Fracción del viewport que ocupa la figura (0-1). 0.9 = 90%.
@export_range(0.2, 1.0, 0.05) var margen: float = 0.9
## Amplitud (px) del bob idle de la figura.
@export var bob_amplitud: float = 2.5

var _svc: SubViewportContainer
var _sv: SubViewport
var _fig: FiguraConstructor
var _bg: TextureRect
var _texto_pendiente: String = ""
var _color_pendiente: Color = Color(0, 0, 0, 0)
var _base_pos: Vector2 = Vector2.ZERO
var _t: float = 0.0

static var _tex_glow: GradientTexture2D


func _ready() -> void:
	# Fondo radial suave (detrás de la figura).
	_bg = TextureRect.new()
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.texture = _textura_glow()
	_bg.modulate = Color(1, 1, 1, 0)
	add_child(_bg)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_svc = SubViewportContainer.new()
	_svc.stretch = true
	_svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_svc)
	_svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_sv = SubViewport.new()
	_sv.transparent_bg = true
	_sv.world_2d = World2D.new()  # aísla la figura (no se cuela en el nivel)
	_sv.disable_3d = true
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_svc.add_child(_sv)

	_fig = FIGURA_ESCENA.instantiate() as FiguraConstructor
	_sv.add_child(_fig)

	resized.connect(_encuadrar)
	_sv.size_changed.connect(_encuadrar)

	if not _texto_pendiente.is_empty():
		var pendiente := _texto_pendiente
		var color_pendiente := _color_pendiente
		_texto_pendiente = ""
		_color_pendiente = Color(0, 0, 0, 0)
		mostrar_figura(pendiente, color_pendiente)


func _process(delta: float) -> void:
	if _fig == null:
		return
	_t += delta
	_fig.position = _base_pos + Vector2(0.0, sin(_t * 2.0) * bob_amplitud)


## Dibuja la figura a partir del bloque de texto del classShape.
## color_luz: si tiene alfa > 0, la figura brilla con ese color (rareza).
func mostrar_figura(texto: String, color_luz: Color = Color(0, 0, 0, 0)) -> void:
	if texto.strip_edges().is_empty():
		return
	if _fig == null:
		_texto_pendiente = texto
		_color_pendiente = color_luz
		return
	_fig.cargar_texto(texto, 1.0, color_luz)
	_encuadrar()

	# Fondo radial tenue con el color de rareza.
	if _bg != null:
		if color_luz.a > 0.0:
			_bg.modulate = Color(color_luz.r, color_luz.g, color_luz.b, 0.16)
		else:
			_bg.modulate = Color(1, 1, 1, 0.06)


func limpiar() -> void:
	if _fig != null:
		_fig._limpiar()


func _encuadrar() -> void:
	if _fig == null or _sv == null:
		return
	var vp := Vector2(_sv.size)
	# Aún sin layout: 'resized' volverá a llamar cuando haya tamaño.
	if vp.x <= 1.0 or vp.y <= 1.0:
		return

	var bounds: Rect2 = _fig.obtener_bounds()
	var escala_fig: float = float(_fig.get("escala_global"))

	var ancho := bounds.size.x * escala_fig
	var alto := bounds.size.y * escala_fig
	if ancho <= 0.0 or alto <= 0.0:
		return

	var factor: float = minf(vp.x * margen / ancho, vp.y * margen / alto)

	_fig.scale = Vector2.ONE * factor
	var centro := bounds.get_center() * escala_fig * factor
	_base_pos = vp * 0.5 - centro
	_fig.position = _base_pos


static func _textura_glow() -> GradientTexture2D:
	if _tex_glow == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		_tex_glow = GradientTexture2D.new()
		_tex_glow.gradient = g
		_tex_glow.fill = GradientTexture2D.FILL_RADIAL
		_tex_glow.fill_from = Vector2(0.5, 0.5)
		_tex_glow.fill_to = Vector2(1.0, 0.5)
		_tex_glow.width = 128
		_tex_glow.height = 128
	return _tex_glow
