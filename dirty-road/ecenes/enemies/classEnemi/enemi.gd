class_name EnemigoMelee
extends CharacterBody2D

@export var speed = 120.0
@export var damage = 10
@export var damage_cooldown = 0.5
@export var max_health = 30

var player : Node2D
var spawn_position : Vector2
var damage_timer = 0.0
var health : int
var is_dead = false

func _ready():
	player = get_tree().get_first_node_in_group('jugador')
	spawn_position = global_position
	health = max_health

func _physics_process(delta):
	
	if is_dead:
		return

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group('jugador')
		if player == null:
			return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	damage_timer -= delta
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == player and damage_timer <= 0.0:
			if player.has_method("take_damage"):
				player.take_damage(damage)
			damage_timer = damage_cooldown

func take_hit(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	visible = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

func revive():
	is_dead = false
	visible = true
	health = max_health
	global_position = spawn_position
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
