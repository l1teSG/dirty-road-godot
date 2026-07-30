class_name proyectil_player
extends Area2D

@export var sped: float
var positionEnemi: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	
	shoot(positionEnemi, delta)

func shoot(positionEnemi, delta):
	self.global_position += delta * sped * positionEnemi
	

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemi'):
		body.take_hit(10)
		self.queue_free()
