extends Player

@onready var rangeArea = $Area2D/range
@onready var labelVida = $controls/Label
var proyectil = preload("res://ecenes/players/projectile/quark/proyectilQuark.tscn")
var power = 'basic' #basic super mega
var onFire: bool = false
var enemi: Node

func move():
	var vectorDireccion = Input.get_vector('ui_left','ui_right','ui_up','ui_down')
	velocity = vectorDireccion * speed
	move_and_slide()

func shot(enemi, power):
	if onFire:
		var direction = (enemi.global_position - $aim.global_position).normalized()
		var bullet = proyectil.instantiate()
		bullet.add_to_group('bullet')
		bullet.global_position = $aim.global_position
		bullet.positionEnemi = direction
		get_tree().current_scene.add_child(bullet)
		

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemi'):
		onFire = true
		enemi = body



func _on_timer_timeout() -> void:
	if onFire == true:
		shot(enemi, power)

func _on_super_pressed() -> void:
	power = 'super'


func _on_mega_pressed() -> void:
	power = 'mega'

func take_damage(damage):
	life -= damage
	if life == 0:
		get_tree().change_scene_to_file('res://demo/muerte.tscn')


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group('enemi'):
		onFire = false
	
func _physics_process(delta: float) -> void:
	labelVida.text = 'vida: ' + str(life)
	move()
	if life <= 0:
		self.queue_free()
