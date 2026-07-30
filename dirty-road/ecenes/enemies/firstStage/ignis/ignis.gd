
extends CharacterBody2D

@export var speed = 100.0
@export var max_health = 20
@export var shoot_cooldown = 1.0

@onready var hurtbox = $hurt
@onready var aim_point = $AimPoint
@onready var proyectil = preload("res://ecenes/enemies/firstStage/ignis/bullets/enemi_bullet.tscn")

var player : Node2D
var spawn_position : Vector2
var health : int
var is_dead = false
var shoot_timer = 1

func _ready():
	player = get_tree().get_first_node_in_group('jugador')
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

	var direction_to_player = (player.global_position - global_position).normalized()

	velocity = direction_to_player * speed
	move_and_slide()

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_at_player()
		shoot_timer = shoot_cooldown

func shoot_at_player():
	var bullet = proyectil.instantiate()
	var direction = (player.global_position - global_position).normalized()
	bullet.positionEnemi = direction
	get_tree().root.add_child(bullet)
	bullet.global_position = aim_point.global_position

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group('bullet'):
		take_hit(1)
		area.queue_free()

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
