extends AIController2D

var move_direction : Vector2 = Vector2.ZERO

func get_obs() -> Dictionary:
	if _player == null or not is_instance_valid(_player) or _player.player == null or not is_instance_valid(_player.player):
		return {"obs": [0.0, 0.0, 1.0, 0.0, 0.0]}

	var player_pos = _player.player.global_position
	var enemy_pos = _player.global_position

	var to_player = (player_pos - enemy_pos)
	var distance = to_player.length()
	var direction_norm = to_player.normalized() if distance > 0 else Vector2.ZERO

	var obs = [
		direction_norm.x,
		direction_norm.y,
		distance / 500.0,
		_player.player.velocity.x / 200.0,
		_player.player.velocity.y / 200.0,
	]

	return {"obs": obs}

func get_reward() -> float:
	return reward

func get_action_space() -> Dictionary:
	return {
		"move" : {
			"size": 2,
			"action_type": "continuous"
		},
	}

func set_action(action) -> void:
	move_direction = Vector2(action["move"][0], action["move"][1])
