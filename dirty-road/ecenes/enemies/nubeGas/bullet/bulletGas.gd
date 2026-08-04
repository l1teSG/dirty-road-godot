extends Area2D

@export var velocidad: float = 400.0
@export var danio: int = 12

var direction: Vector2 = Vector2.ZERO
var tiempo_vida: float = 0.0

func _ready() -> void:
	top_level = true # Desconecta la posición del transform del padre si fue instanciado como hijo
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	tiempo_vida += delta
	
	if direction != Vector2.ZERO:
		global_position += direction * velocidad * delta

	if tiempo_vida > 5.0:
		queue_free()

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	# Ignorar a los enemigos del grupo "enemi"
	if body.is_in_group("enemi"):
		return

	# Dañar al jugador o árbol
	if body.has_method("take_damage"):
		body.take_damage(danio)
	elif body.has_method("recibir_danio"):
		body.recibir_danio(danio)

	queue_free()
