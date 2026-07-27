extends Player

@onready var rangeArea = $Area2D/range
var proyectil = preload("res://ecenes/players/projectile/quark/proyectilQuark.tscn")
var power = 'basic' #basic super mega
var onFire: bool = false
var direction: Vector2 = Vector2.ZERO

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemi'):
		direction = (body.global_position - self.global_position).normalized()
		shot(direction, power)

func shot(direction, power):
	if power == "basic":
		var bullet = proyectil.instantiate()
		bullet.global_position = $aim.global_position
		bullet.positionEnemi = direction
		get_tree().root.add_child(bullet)



func _on_timer_timeout() -> void:
	pass


func _on_super_pressed() -> void:
	power = 'super'


func _on_mega_pressed() -> void:
	power = 'mega'
