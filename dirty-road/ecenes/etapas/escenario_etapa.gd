extends Node
class_name EscenarioEtapa

## ══════════════════════════════════════════════════════════
##  ESCENARIO DE ETAPA — "mismo valle, distinta piel".
##  · La ETAPA 1 (índice 0) deja el `valle` ORIGINAL intacto.
##  · Las demás etapas RECOLOREAN la geometría del valle con la paleta
##    del `TemaEtapa` (mismos límites/colisiones) y añaden props temáticos.
##  No se genera terreno nuevo: se reutiliza el valle para no cambiar
##  la jugabilidad ni los bordes.
## ══════════════════════════════════════════════════════════

var _valle: Node = null
var _originales: Dictionary = {}   # Polygon2D -> Color original
var _props: Node2D = null
var _rng := RandomNumberGenerator.new()


func generar(idx: int, tema: TemaEtapa) -> void:
	_asegurar()
	if _valle == null or tema == null:
		return
	_capturar_originales()

	if idx <= 0:
		# Etapa 1: valle original, sin tocar.
		_restaurar()
		_limpiar_props()
		return

	_recolorear(tema)
	_repoblar_props(idx, tema)


func _asegurar() -> void:
	if _valle != null and is_instance_valid(_valle):
		return
	var raiz := get_tree().current_scene
	if raiz != null:
		_valle = raiz.get_node_or_null("valle")


func _capturar_originales() -> void:
	if not _originales.is_empty():
		return
	for p in _valle.find_children("*", "Polygon2D", true, false):
		_originales[p] = (p as Polygon2D).color


func _restaurar() -> void:
	for p in _originales.keys():
		if is_instance_valid(p):
			(p as Polygon2D).color = _originales[p]


func _recolorear(tema: TemaEtapa) -> void:
	for p in _valle.find_children("*", "Polygon2D", true, false):
		if not is_instance_valid(p):
			continue
		var poly := p as Polygon2D
		var orig: Color = _originales.get(poly, poly.color)
		var ruta := String(poly.get_path())
		var destino: Color
		if ruta.contains("pasto"):
			destino = tema.color_suelo
		elif ruta.contains("acantilado"):
			destino = tema.color_borde
		elif ruta.contains("tocones") or ruta.contains("tocon"):
			destino = tema.color_props
		else:
			destino = tema.color_suelo_detalle
		poly.color = orig.lerp(destino, 0.75)


func _limpiar_props() -> void:
	if _props != null and is_instance_valid(_props):
		_props.queue_free()
	_props = null


func _repoblar_props(idx: int, tema: TemaEtapa) -> void:
	_limpiar_props()
	_props = Node2D.new()
	_props.name = "PropsEtapa"
	_valle.add_child(_props)

	_rng.seed = 7919 + idx * 101
	var cantidad := maxi(tema.props_cantidad, 0)
	for i in cantidad:
		var centro := Vector2(_rng.randf_range(-1400.0, 1400.0), _rng.randf_range(-1400.0, 1400.0))
		var r := _rng.randf_range(8.0, 26.0)
		var poly := Polygon2D.new()
		poly.polygon = _blob(centro, Vector2(r, r * _rng.randf_range(0.7, 1.4)), 0.45, 7)
		poly.color = tema.color_props.lerp(Color.WHITE, _rng.randf_range(0.0, 0.15))
		poly.z_index = -2
		_props.add_child(poly)


func _blob(centro: Vector2, radios: Vector2, jitter: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		var f := 1.0 + _rng.randf_range(-jitter, jitter)
		pts.append(centro + Vector2(cos(a) * radios.x * f, sin(a) * radios.y * f))
	return pts
