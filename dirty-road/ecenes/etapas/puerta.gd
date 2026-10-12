extends Node2D
class_name Puerta

## ══════════════════════════════════════════════════════════
##  PUERTA — portal que aparece al terminar una etapa. Cuando el jugador
##  la cruza (entra en su Area2D) emite `cruzada` para iniciar la
##  transición al siguiente escenario. Construida 100% por código.
## ══════════════════════════════════════════════════════════

signal cruzada

@export var color: Color = Color("99ff33")
@export var ancho: float = 90.0
@export var alto: float = 150.0

var _abierta: bool = false
var _area: Area2D = null


func _ready() -> void:
	_construir()
	visible = false


func _construir() -> void:
	var w := ancho
	var h := alto
	var marco := Color(0.14, 0.17, 0.15)

	for sx in [-1.0, 1.0]:
		var post := Polygon2D.new()
		post.polygon = PackedVector2Array([
			Vector2(sx * (w * 0.5 + 12.0), -h), Vector2(sx * (w * 0.5), -h),
			Vector2(sx * (w * 0.5), 6.0), Vector2(sx * (w * 0.5 + 12.0), 6.0)])
		post.color = marco
		add_child(post)

	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(-w * 0.5 - 12.0, -h - 16.0), Vector2(w * 0.5 + 12.0, -h - 16.0),
		Vector2(w * 0.5 + 12.0, -h + 6.0), Vector2(-w * 0.5 - 12.0, -h + 6.0)])
	top.color = marco
	add_child(top)

	var portal := Polygon2D.new()
	portal.name = "Portal"
	portal.polygon = PackedVector2Array([
		Vector2(-w * 0.5, -h), Vector2(w * 0.5, -h),
		Vector2(w * 0.5, 0.0), Vector2(-w * 0.5, 0.0)])
	portal.color = Color(color.r, color.g, color.b, 0.55)
	add_child(portal)

	var luz := PointLight2D.new()
	luz.color = color
	luz.energy = 1.4
	luz.texture_scale = 3.0
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	luz.texture = tex
	luz.position = Vector2(0, -h * 0.5)
	add_child(luz)

	_area = Area2D.new()
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w + 20.0, h)
	cs.shape = sh
	_area.add_child(cs)
	_area.monitoring = false
	_area.collision_layer = 0
	_area.monitoring = true
	_area.monitorable = true
	add_child(_area)
	_area.body_entered.connect(_on_body)


func abrir() -> void:
	_abierta = true
	visible = true
	scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var portal := get_node_or_null("Portal")
	if portal != null:
		var ptw := portal.create_tween().set_loops()
		ptw.tween_property(portal, "modulate:a", 0.4, 0.6)
		ptw.tween_property(portal, "modulate:a", 1.0, 0.6)


func _on_body(body: Node2D) -> void:
	if _abierta and body != null and body.is_in_group("jugador"):
		_abierta = false
		cruzada.emit()
