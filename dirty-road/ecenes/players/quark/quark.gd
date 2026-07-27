extends Player

@onready var rangeArea = $Area2D/range
var proyectil = preload("res://ecenes/players/projectile/quark/proyectilQuark.tscn")
var power = 'basic' #basic super mega
var onFire: bool = false
var OnEnemiRange: bool = false
var direction: Vector2 = Vector2.ZERO

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemi'):
		OnEnemiRange = true
		direction = (body.global_position - self.global_position).normalized()
	else:
		OnEnemiRange = false

func shot(direction, power):
	if power == "basic":
		var bullet = proyectil.instantiate()
		bullet.global_position = $aim.global_position
		bullet.positionEnemi = direction
		bullet.add_to_group('fire_player')
		get_tree().root.add_child(bullet)



func _on_timer_timeout() -> void:
	if power == 'basic' and OnEnemiRange:
		shot(direction, power)


func _on_super_pressed() -> void:
	power = 'super'


func _on_mega_pressed() -> void:
	power = 'mega'

func take_damage(damage):
	pass
