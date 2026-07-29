extends Node

const PLAYER_SCENE = preload("res://ecenes/players/quark/quark.tscn")

var player: Node2D
var player_spawn_position: Vector2

func _ready():
	player = get_tree().get_first_node_in_group('jugador')
	if player:
		player_spawn_position = player.global_position
		player.tree_exited.connect(_on_player_died)

func _on_player_died():
	reset_episode.call_deferred()

func reset_episode():
	var new_player = PLAYER_SCENE.instantiate()
	get_tree().root.add_child(new_player)
	new_player.global_position = player_spawn_position
	player = new_player
	player.tree_exited.connect(_on_player_died)

	for controller in get_tree().get_nodes_in_group("AGENT"):
		var enemy_body = controller.get_parent()

		if enemy_body.has_method("revive") and enemy_body.is_dead:
			enemy_body.revive()
		elif enemy_body.has_method("reset_episode"):
			enemy_body.reset_episode()

		controller.done = true
		controller.needs_reset = true
