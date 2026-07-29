class_name EnemigoRango
extends CharacterBody2D

@export var speed = 100.0
@export var max_health = 20
@export var ideal_min_distance = 150.0
@export var ideal_max_distance = 300.0
@export var shoot_cooldown = 1.0
@export var melee_penalty_distance = 60.0

@onready var ai_controller = $AIController2D
@onready var hurtbox = $hurt
@onready var aim_point = $AimPoint
@onready var proyectil = preload("res://ecenes/enemies/firstStage/ignis/bullets/enemi_bullet.tscn")

var player: Node2D
var spawn_position : Vector2
var health : int
var is_dead = false
var shoot_timer = 0.0

func _ready():
	player = get_tree().get_first_node_in_group('jugador')
	ai_controller.init(self)
	spawn_position = global_position
	health = max_health

	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(delta):
	if is_dead:
		return

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group('jugador')
		if player == null:
			return

	if ai_controller.needs_reset:
		ai_controller.reset()
		if ai_controller.control_mode == ai_controller.ControlModes.TRAINING:
			reset_episode()
		return

	var movement : Vector2
	var wants_shoot : bool

	if ai_controller.heuristic == "human":
		movement = Vector2.ZERO
		wants_shoot = false
	else:
		movement = ai_controller.move_direction.normalized()
		wants_shoot = ai_controller.shoot_action == 1

	velocity = movement * speed
	move_and_slide()

	shoot_timer -= delta
	if wants_shoot and shoot_timer <= 0.0:
		shoot_at_player()
		shoot_timer = shoot_cooldown

	_apply_rewards()

func _apply_rewards():
	var distance = global_position.distance_to(player.global_position)

	if distance < ideal_min_distance:
		ai_controller.reward -= 0.05
	elif distance > ideal_max_distance:
		ai_controller.reward -= 0.02
	else:
		ai_controller.reward += 0.05

	if distance < melee_penalty_distance:
		ai_controller.reward -= 0.5

	ai_controller.reward -= 0.001

func shoot_at_player():
	var bullet = proyectil.instantiate()
	var direction = (player.global_position - global_position).normalized()
	bullet.positionEnemi = direction
	get_tree().root.add_child(bullet)
	bullet.global_position = aim_point.global_position

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group('bullet'):
		take_hit_from_bullet(1)
		area.queue_free()

func take_hit_from_bullet(amount: int):
	health -= amount
	ai_controller.reward -= 0.3
	if health <= 0:
		die()

func take_melee_hit(amount: int):
	health -= amount
	ai_controller.reward -= 0.5
	if health <= 0:
		die()

func on_hit_player():
	ai_controller.reward += 1.0

func die():
	if is_dead:
		return
	is_dead = true
	visible = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	if ai_controller.control_mode == ai_controller.ControlModes.TRAINING:
		ai_controller.done = true
		ai_controller.needs_reset = true
		reset_episode()
		revive()

func revive():
	is_dead = false
	visible = true
	health = max_health
	global_position = spawn_position
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

func reset_episode():
	global_position = spawn_position
	health = max_health
