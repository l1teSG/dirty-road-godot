class_name EnemigoBase
extends CharacterBody2D


@export var speed = 120.0
@export var damage = 10
@export var damage_cooldown = 0.5  # evita hacer daño cada frame de contacto

@onready var player = get_tree().get_first_node_in_group('jugador')
@onready var ai_controller = $AIController2D

var spawn_position : Vector2
var last_distance_to_player = 0.0
var damage_timer = 0.0

func _ready():
	ai_controller.init(self)
	spawn_position = global_position

func _physics_process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group('jugador')
		return

	if ai_controller.needs_reset:
		ai_controller.reset()
		reset_episode()
		return

	var movement : Vector2

	if ai_controller.heuristic == "human":
		movement = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	else:
		movement = ai_controller.move_direction.normalized()

	velocity = movement * speed
	move_and_slide()

	# --- Daño por contacto directo ---
	damage_timer -= delta
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == player and damage_timer <= 0.0:
			player.take_damage(damage)
			ai_controller.reward += 1.0
			damage_timer = damage_cooldown

	# --- Recompensa por acercarse ---
	var distance = global_position.distance_to(player.global_position)
	ai_controller.reward += (last_distance_to_player - distance) * 0.1
	last_distance_to_player = distance
	ai_controller.reward -= 0.001

func game_over():
	ai_controller.done = true
	ai_controller.needs_reset = true

func reset_episode():
	global_position = spawn_position
	last_distance_to_player = global_position.distance_to(player.global_position)
	damage_timer = 0.0
