class_name AIController2D
extends Node2D

@export var reset_after: int = 1000
var reward: float = 0.0
var step_count: int = 0
var needs_reset: bool = false
@onready var entity: Node2D = get_parent()

func _ready() -> void:
	add_to_group("AGENT")

func get_obs() -> Dictionary:
	return {"obs": []}

func set_action(action: Dictionary) -> void:
	pass

func zero_reward() -> void:
	reward = 0.0

func add_reward(value: float) -> void:
	reward += value

func reset() -> void:
	step_count = 0
	reward = 0.0
	needs_reset = false
