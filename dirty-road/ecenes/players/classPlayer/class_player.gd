extends CharacterBody2D
class_name Player

@onready var shape = $shape

var ID: String = ""
var life: int = 10
var speed: float = 300.0

func move () :
	var directionVector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = directionVector * speed
	move_and_slide()
func damage(value):
	life -= value

func _physics_process(delta: float) -> void:
	move()
