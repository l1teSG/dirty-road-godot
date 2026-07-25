extends Player

@onready var rangeArea = $Area2D/range
var proyectil = preload("res://ecenes/players/projectile/quark/proyectilQuark.tscn")
var power = 'basic' #basic super mega

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("🔵 body_entered disparado. Cuerpo: ", body.name)
	if body.is_in_group('enemi'):
		var direction = (body.global_position - self.global_position).normalized()
		shot(direction, power)

func shot(direction, power):
	
	var bullet = proyectil.instantiate()
	bullet.positionEnemi = direction
	self.add_child(bullet) 
	

func _ready() -> void:
	pass
