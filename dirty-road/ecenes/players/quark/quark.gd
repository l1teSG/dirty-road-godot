extends Player

@onready var rangeArea = $Area2D/range
@onready var aim: Node2D = $aim
@onready var nucleo: Polygon2D = $Nucleo
@onready var luz_punta: PointLight2D = $LuzPunta
@onready var sombra: Polygon2D = $sombra
@onready var joystick: VirtualJoystick = $controls/Joystick  # Joystick virtual

var proyectil: PackedScene = preload("res://ecenes/players/projectile/quark/playerProyectil.tscn")
var power: String = 'basic'
var onFire: bool = false
var enemi: Node2D = null
var enemigos_en_rango: Array[Node2D] = []

var tiempo_caminata: float = 0.0
var tiempo_pulso: float = 0.0

# --- Variable para almacenar dirección del joystick (event‑driven) ---
var joystick_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	if joystick != null:
		# Conectar la señal 'moved' que emite un Vector2
		joystick.moved.connect(_on_joystick_moved)

func _on_joystick_moved(direction: Vector2) -> void:
	# Almacenar la dirección para usarla en move()
	joystick_direction = direction

func _physics_process(delta: float) -> void:
	aplicar_pulso_energia(delta)
	animar_sombra(delta)
	move()

	if life <= 0:
		queue_free()

func move() -> void:
	var vector_direccion: Vector2 = Vector2.ZERO

	# Usar la dirección recibida por señal, si existe
	if joystick != null:
		vector_direccion = joystick_direction

	# Si el joystick no se está usando, caer al teclado
	if vector_direccion.length() < 0.1:
		vector_direccion = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')

	velocity = vector_direccion * speed
	move_and_slide()

# ... el resto del script original sin cambios desde aquí ...
# (shot, detect, etc.)
