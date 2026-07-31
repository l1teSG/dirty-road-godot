class_name ProyectilEnemy
extends Area2D

@export var speed: float = 250.0
@export var damage: int = 5
@export var max_lifetime: float = 3.0

var positionEnemi: Vector2 = Vector2.ZERO
var _lifetime: float = 0.0

func _ready() -> void:
	add_to_group('enemy_bullet')
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += positionEnemi * speed * delta

	_lifetime += delta
	if _lifetime > max_lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('jugador'):
		if body.has_method('take_damage'):
			body.take_damage(damage)
		queue_free()
