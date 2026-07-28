extends AIController2D



var move_direction : Vector2 = Vector2.ZERO
var shoot_action : int = 0

const MAX_BULLETS_OBSERVED = 2
const OBS_RANGE = 500.0

func get_obs() -> Dictionary:
	if _player.player == null:
		return {"obs": _empty_obs()}

	var player_pos = _player.player.global_position
	var enemy_pos = _player.global_position

	var to_player = (player_pos - enemy_pos)
	var distance = to_player.length()
	var direction_norm = to_player.normalized() if distance > 0 else Vector2.ZERO

	var obs = [
		direction_norm.x,
		direction_norm.y,
		distance / OBS_RANGE,
		_player.velocity.x / 200.0,
		_player.velocity.y / 200.0,
	]

	var bullets = get_tree().get_nodes_in_group("bullet")
	var bullets_with_dist = []
	for b in bullets:
		if not is_instance_valid(b):
			continue
		var d = enemy_pos.distance_to(b.global_position)
		bullets_with_dist.append({"node": b, "dist": d})

	bullets_with_dist.sort_custom(func(a, b): return a["dist"] < b["dist"])

	for i in range(MAX_BULLETS_OBSERVED):
		if i < bullets_with_dist.size():
			var b = bullets_with_dist[i]["node"]
			var rel_pos = (b.global_position - enemy_pos) / OBS_RANGE
			var vel = Vector2.ZERO
			if "positionEnemi" in b and "sped" in b:
				vel = b.positionEnemi * b.sped / 400.0
			obs.append(rel_pos.x)
			obs.append(rel_pos.y)
			obs.append(vel.x)
			obs.append(vel.y)
		else:
			obs.append(0.0)
			obs.append(0.0)
			obs.append(0.0)
			obs.append(0.0)

	return {"obs": obs}

func _empty_obs() -> Array:
	var base = [0.0, 0.0, 1.0, 0.0, 0.0]
	for i in range(MAX_BULLETS_OBSERVED):
		base.append_array([0.0, 0.0, 0.0, 0.0])
	return base

func get_reward() -> float:
	return reward

func get_action_space() -> Dictionary:
	return {
		"move" : {
			"size": 2,
			"action_type": "continuous"
		},
		"shoot" : {
			"size": 2,
			"action_type": "discrete"
		},
	}

func set_action(action) -> void:
	move_direction = Vector2(action["move"][0], action["move"][1])
	shoot_action = action["shoot"]
