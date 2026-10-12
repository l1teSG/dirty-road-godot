extends CanvasLayer

## ══════════════════════════════════════════════════════════
##  BARRA DE VIDA ÉPICA DEL JEFE
##  · Nombre del jefe + HP con DRENADO RETARDADO (barra clara del daño reciente).
##  · Marcos con segmentos, glow y cambio a MAGENTA en furia (<40%).
##  · ROBUSTA: sondea `jefe_actual` del WaveManager cada frame (no depende de
##    ninguna señal), así aparece siempre que haya jefe en escena.
## ══════════════════════════════════════════════════════════

@export_category("Aspecto")
@export var ancho: float = 760.0
@export var alto: float = 34.0
@export var margen_superior: float = 46.0
@export var segmentos: int = 10

@export_category("Colores")
@export var color_vida: Color = Color("ff4d6d")
@export var color_furia: Color = Color("d81b60")
@export var color_sangrado: Color = Color("ffe0e6")

var _raiz: Control
var _nombre: Label
var _contenedor: Control
var _fondo: ColorRect
var _sangrado: ColorRect
var _relleno: ColorRect
var _marcos: Control

var _wm: Node = null
var _jefe: Node = null
var _pct: float = 1.0
var _pct_sangrado: float = 1.0
var _t: float = 0.0
var _tween: Tween = null


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir()
	_raiz.visible = false
	_raiz.modulate.a = 0.0
	set_process(true)


func _construir() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)

	_nombre = Label.new()
	_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nombre.add_theme_font_override("font", EstiloUI.F_BOLD)
	_nombre.add_theme_font_size_override("font_size", 34)
	_nombre.add_theme_color_override("font_color", color_vida)
	_nombre.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_nombre.add_theme_constant_override("outline_size", 7)
	_raiz.add_child(_nombre)

	_contenedor = Control.new()
	_contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_contenedor)

	_fondo = ColorRect.new()
	_fondo.color = Color(0.04, 0.06, 0.05, 0.85)
	_contenedor.add_child(_fondo)

	_sangrado = ColorRect.new()
	_sangrado.color = color_sangrado
	_contenedor.add_child(_sangrado)

	_relleno = ColorRect.new()
	_relleno.color = color_vida
	_contenedor.add_child(_relleno)

	_marcos = Control.new()
	_marcos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marcos.draw.connect(_dibujar_marcos)
	_contenedor.add_child(_marcos)


func _process(delta: float) -> void:
	_t += delta

	# Buscar el WaveManager si aún no lo tenemos (robusto ante orden de _ready).
	if _wm == null or not is_instance_valid(_wm):
		_wm = get_tree().get_first_node_in_group("wave_manager")

	# Sondear el jefe actual. No depende de señales → siempre aparece.
	var jefe: Variant = null
	if _wm != null and is_instance_valid(_wm):
		jefe = _wm.get("jefe_actual")
	var hay := jefe != null and is_instance_valid(jefe)

	if hay and _jefe != jefe:
		_jefe = jefe
		if _wm.has_method("get") and _wm.get("_nombre_jefe") != null:
			_nombre.text = str(_wm.get("_nombre_jefe"))
		else:
			_nombre.text = "JEFE"
		_pct = _jefe.porcentaje_vida() if _jefe.has_method("porcentaje_vida") else 1.0
		_pct_sangrado = _pct
		_mostrar()
	elif not hay and _jefe != null:
		_ocultar()

	if not _raiz.visible:
		return

	_colocar()
	if hay and is_instance_valid(_jefe):
		_pct = _jefe.porcentaje_vida() if _jefe.has_method("porcentaje_vida") else _pct
	_pct_sangrado = lerpf(_pct_sangrado, _pct, delta * 2.2)
	_aplicar()
	_marcos.queue_redraw()


func _colocar() -> void:
	var vp := get_viewport().get_visible_rect().size
	var x := (vp.x - ancho) * 0.5
	var y := margen_superior
	_nombre.position = Vector2(0.0, y - 44.0)
	_nombre.size = Vector2(vp.x, 40.0)
	_contenedor.position = Vector2(x, y)
	_contenedor.size = Vector2(ancho, alto)
	_fondo.position = Vector2.ZERO
	_fondo.size = Vector2(ancho, alto)
	_sangrado.position = Vector2.ZERO
	_relleno.position = Vector2.ZERO
	_marcos.position = Vector2.ZERO
	_marcos.size = Vector2(ancho, alto)


func _aplicar() -> void:
	var w := ancho
	_relleno.size = Vector2(w * clampf(_pct, 0.0, 1.0), alto)
	_sangrado.size = Vector2(w * clampf(maxf(_pct_sangrado, _pct), 0.0, 1.0), alto)

	# Furia: por debajo del 40% se vuelve magenta y late.
	if _pct <= 0.4:
		var pulso := 0.5 + 0.5 * sin(_t * 6.0)
		_relleno.color = color_furia.lerp(Color.WHITE, pulso * 0.25)
		_nombre.add_theme_color_override("font_color", color_furia.lerp(Color.WHITE, pulso * 0.4))
	else:
		_relleno.color = color_vida
		_nombre.add_theme_color_override("font_color", color_vida)


func _dibujar_marcos() -> void:
	var w := ancho
	var h := alto
	_marcos.draw_rect(Rect2(Vector2(-2, -2), Vector2(w + 4, h + 4)), Color(0, 0, 0, 0.55), false, 2.0)
	_marcos.draw_rect(Rect2(Vector2(-1, -1), Vector2(w + 2, h + 2)),
		Color(color_vida.r, color_vida.g, color_vida.b, 0.55), false, 2.0)
	if segmentos > 1:
		for i in range(1, segmentos):
			var x := w * float(i) / float(segmentos)
			_marcos.draw_line(Vector2(x, 0), Vector2(x, h), Color(0, 0, 0, 0.45), 2.0)
	_marcos.draw_rect(Rect2(Vector2(0, 0), Vector2(w, h * 0.35)), Color(1, 1, 1, 0.09))


func _mostrar() -> void:
	_raiz.visible = true
	_contenedor.scale = Vector2(0.9, 0.9)
	_contenedor.pivot_offset = Vector2(ancho * 0.5, alto * 0.5)
	_raiz.modulate.a = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_raiz, "modulate:a", 1.0, 0.35)
	_tween.tween_property(_contenedor, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _ocultar() -> void:
	if not _raiz.visible:
		_jefe = null
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_raiz, "modulate:a", 0.0, 0.4)
	_tween.tween_callback(func() -> void:
		_raiz.visible = false
		_jefe = null
	)
