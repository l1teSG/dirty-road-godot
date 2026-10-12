extends Control
class_name JoystickApuntado

## ══════════════════════════════════════════════════════════
##  JOYSTICK DE APUNTADO/DISPARO (twin-stick).
##  Ocupa la mitad derecha de la pantalla. Al mantener (toque o ratón)
##  fija un origen y devuelve una dirección; el jugador dispara mientras
##  esté activo. Dibuja base + perilla.
## ══════════════════════════════════════════════════════════

var activo: bool = false
var direccion: Vector2 = Vector2.ZERO

@export var radio: float = 120.0
@export var color: Color = Color("99ff33")

var _origen: Vector2 = Vector2.ZERO
var _pos: Vector2 = Vector2.ZERO
var _touch: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	anchor_left = 0.5
	anchor_right = 1.0
	anchor_top = 0.15
	anchor_bottom = 1.0
	set_process(true)


func _process(_delta: float) -> void:
	# Repinta para mostrar la base tenue cuando NO está activo (visible siempre).
	if not activo:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and not activo:
			activo = true
			_touch = st.index
			_origen = st.position
			_pos = st.position
			accept_event()
		elif not st.pressed and st.index == _touch:
			_terminar()
			accept_event()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _touch:
			_actualizar(sd.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				activo = true
				_origen = mb.position
				_pos = mb.position
			else:
				_terminar()
	elif event is InputEventMouseMotion and activo:
		_actualizar((event as InputEventMouseMotion).position)


func _actualizar(p: Vector2) -> void:
	_pos = p
	var d := _pos - _origen
	if d.length() > radio:
		_origen = _pos - d.normalized() * radio
		d = _pos - _origen
	direccion = d
	queue_redraw()


func _terminar() -> void:
	activo = false
	direccion = Vector2.ZERO
	_touch = -1
	queue_redraw()


## Corta el disparo (lo usa Quark al desactivar el modo manual).
func desactivar() -> void:
	if activo:
		_terminar()


func _draw() -> void:
	var c := color
	var base := _origen
	if not activo:
		# Base + perilla visibles en reposo: el jugador debe saber que existe
		# el joystick de disparo (arriba de los botones super/mega).
		base = Vector2(size.x * 0.5, size.y - 540.0)
		draw_arc(base, radio, 0.0, TAU, 48, Color(c.r, c.g, c.b, 0.7), 4.0)
		draw_circle(base, radio, Color(c.r, c.g, c.b, 0.12))
		draw_circle(base, radio * 0.3, Color(c.r, c.g, c.b, 0.5))
		draw_arc(base, radio * 0.3, 0.0, TAU, 24, Color(c.r, c.g, c.b, 0.9), 3.0)
		return

	draw_arc(base, radio, 0.0, TAU, 48, Color(c.r, c.g, c.b, 0.5), 3.0)
	draw_circle(base, radio, Color(c.r, c.g, c.b, 0.08))
	var k := direccion.limit_length(radio) + _origen
	draw_circle(k, radio * 0.28, Color(c.r, c.g, c.b, 0.5))
	draw_arc(k, radio * 0.28, 0.0, TAU, 24, Color(c.r, c.g, c.b, 0.95), 3.0)
