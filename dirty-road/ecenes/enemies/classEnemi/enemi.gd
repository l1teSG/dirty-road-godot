
extends CharacterBody2D

@export var speed = 120.0
@export var damage = 1
@export var damage_cooldown = 0.5
@export var max_health = 1

@onready var player = get_tree().get_first_node_in_group('jugador')
@onready var ai_controller = $AIController2D

var spawn_position : Vector2
var last_distance_to_player = 0.0
var damage_timer = 0.0
var health : int
var is_dead = false

func _ready():
	ai_controller.init(self)
	spawn_position = global_position
	health = max_health

func _physics_process(delta):
	if is_dead:
		return

	if player == null:
		player = get_tree().get_first_node_in_group('jugador')
		return
		

	if ai_controller.needs_reset:
		ai_controller.reset()
		if ai_controller.control_mode == ai_controller.ControlModes.TRAINING:
			reset_episode()
		return

	var movement : Vector2

	if ai_controller.heuristic == "human":
		movement = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	else:
		movement = ai_controller.move_direction.normalized()

	velocity = movement * speed
	move_and_slide()

	damage_timer -= delta
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == player and damage_timer <= 0.0:
			player.take_damage(damage)
			ai_controller.reward += 1.0
			damage_timer = damage_cooldown

	var distance = global_position.distance_to(player.global_position)
	ai_controller.reward += (last_distance_to_player - distance) * 0.1
	last_distance_to_player = distance
	ai_controller.reward -= 0.001

func take_hit(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	if is_dead:
		return
	is_dead = true

	self.remove_from_group('enemi')
	visible = false
	set_collision_layer_value(1, false)  # ajusta al layer que uses
	set_collision_mask_value(1, false)

	if ai_controller.control_mode == ai_controller.ControlModes.TRAINING:
		ai_controller.done = true
		ai_controller.needs_reset = true
		reset_episode()
		revive()  # en entrenamiento, revive inmediato para seguir aprendiendo
	# en modo jugable normal, se queda "muerto" hasta que algo externo lo reviva o lo remueva

func revive():
	is_dead = false
	visible = true
	health = max_health
	global_position = spawn_position
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

func reset_episode():
	global_position = spawn_position
	last_distance_to_player = global_position.distance_to(player.global_position)
	damage_timer = 0.0


func _on_hurt_area_entered(area: Area2D) -> void:
	if area.is_in_group('fire_player'):
		die()
