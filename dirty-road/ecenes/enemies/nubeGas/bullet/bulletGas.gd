extends Area2D

## ------------------------------------------------------------
## Proyectil de la Nube de Gas
## Se mueve en línea recta y daña al primer objetivo que toca.
## ------------------------------------------------------------

@export var velocidad: float = 300.0
@export var danio: int = 12

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Conectar la señal de colisión si no se hizo desde el editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO:
		global_position += direction * velocidad * delta

## Método llamado desde el enemigo NubeGas para configurar la dirección
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	# Ignorar a otros enemigos (sin daño colateral)
	if body.is_in_group("enemi"):
		return

	# Infligir daño al objetivo (jugador, árbol, etc.)
	if body.has_method("take_damage"):
		body.take_damage(danio)
	elif body.has_method("recibir_danio"):
		body.recibir_danio(danio)

	# Destruir el proyectil tras el impacto
	queue_free()
