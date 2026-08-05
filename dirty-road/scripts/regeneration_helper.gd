class_name RegenerationHelper
extends Node

static func update_regeneration(delta: float, current_life: float, max_life: float, regen_per_sec: float, time_since_damage: float, time_without_damage: float, enabled: bool) -> Dictionary:
	if not enabled or max_life <= 0:
		return {"life": current_life, "time_since_damage": time_since_damage}
	
	var new_time_since_damage = time_since_damage + delta
	var new_life = current_life
	if new_time_since_damage >= time_without_damage:
		var regen_amount = regen_per_sec * delta
		new_life = min(current_life + regen_amount, max_life)
	return {"life": new_life, "time_since_damage": new_time_since_damage}
