class_name FlechaArbol
extends Polygon2D
## Flecha que orbita al jugador y apunta al nodo del grupo 'arbol'
## cuando éste queda fuera de cámara. Se añade como hijo del jugador.

const GRUPO_ARBOL := "arbol"
const INTERVALO_BUSQUEDA: float = 1.0

var distancia_orbita: float = 45.0
var offset_altura: float = -15.0
var distancia_minima: float = 80.0
var margen_camara: float = 20.0
var duracion_animacion: float = 0.25

## Si es false la flecha se oculta (jugador muerto, cinemática...).
var habilitada: bool = true:
	set(valor):
		habilitada = valor
		if not valor and is_inside_tree():
			_set_mostrar(false)

var _jugador: Node2D = null
var _arbol: Node2D = null
var _mostrar: bool = false
var _tween: Tween = null
var _t_busqueda: float = 0.0
var _aviso_emitido: bool = false


func _init() -> void:
	top_level = true
	z_index = 100
	visible = false
	scale = Vector2.ZERO
	modulate.a = 0.0


func configurar(p_distancia: float, p_offset: float, p_minima: float, p_margen: float,
		p_color: Color, p_tamano: Vector2, p_duracion: float) -> void:
	distancia_orbita = p_distancia
	offset_altura = p_offset
	distancia_minima = p_minima
	margen_camara = p_margen
	duracion_animacion = p_duracion
	color = p_color
	var mw: float = p_tamano.x / 2.0
	var mh: float = p_tamano.y / 2.0
	polygon = PackedVector2Array([Vector2(mw, 0.0), Vector2(-mw, -mh), Vector2(-mw, mh)])


func _ready() -> void:
	_jugador = get_parent() as Node2D


func _physics_process(delta: float) -> void:
	if not habilitada or _jugador == null:
		return

	if not is_instance_valid(_arbol):
		_set_mostrar(false)
		_t_busqueda -= delta
		if _t_busqueda <= 0.0:
			_t_busqueda = INTERVALO_BUSQUEDA
			_buscar_arbol()
		return

	var centro: Vector2 = _jugador.global_position + Vector2(0.0, offset_altura)
	var hacia_arbol: Vector2 = _arbol.global_position - centro

	if hacia_arbol.length() < distancia_minima or _arbol_en_camara():
		_set_mostrar(false)
		return

	_set_mostrar(true)
	rotation = hacia_arbol.angle()
	global_position = centro + hacia_arbol.normalized() * distancia_orbita


func _buscar_arbol() -> void:
	_arbol = get_tree().get_first_node_in_group(GRUPO_ARBOL)
	if _arbol == null and not _aviso_emitido:
		_aviso_emitido = true  # una sola vez, no una por frame
		push_warning("FlechaArbol: no hay ningún nodo en el grupo '%s'" % GRUPO_ARBOL)


func _arbol_en_camara() -> bool:
	var vp := get_viewport()
	if vp == null:
		return true
	var pos: Vector2 = vp.get_canvas_transform() * _arbol.global_position
	var rect := Rect2(
		Vector2(-margen_camara, -margen_camara),
		vp.get_visible_rect().size + Vector2(margen_camara, margen_camara) * 2.0)
	return rect.has_point(pos)


func _set_mostrar(valor: bool) -> void:
	if _mostrar == valor:
		return
	_mostrar = valor

	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)

	if valor:
		visible = true
		_tween.tween_property(self, "scale", Vector2.ONE, duracion_animacion)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "modulate:a", 1.0, duracion_animacion)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_tween.tween_property(self, "scale", Vector2.ZERO, duracion_animacion)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_tween.tween_property(self, "modulate:a", 0.0, duracion_animacion)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_tween.chain().tween_callback(func():
			if not _mostrar:
				visible = false
		)
