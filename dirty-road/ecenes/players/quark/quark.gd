extends Player

@onready var rangeArea = $Area2D/range
var proyectil = preload("res://ecenes/players/projectile/quark/proyectilQuark.tscn")
var power = 'basic' #basic super mega
var onFire: bool = false
var enemi: Node


func shot(enemi, power):
	if onFire:
		var direction = (enemi.global_position - $aim.global_position).normalized()
		var bullet = proyectil.instantiate()
		bullet.add_to_group('bullet')
		bullet.global_position = $aim.global_position
		bullet.positionEnemi = direction
		get_tree().current_scene.add_child(bullet)
		print('enemigo en rango ')

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemi'):
		onFire = true
		enemi = body



func _on_timer_timeout() -> void:
	shot(enemi, power)

func _on_super_pressed() -> void:
	power = 'super'


func _on_mega_pressed() -> void:
	power = 'mega'

func take_damage(damage):
	pass


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group('enemi'):
		onFire = false
	
