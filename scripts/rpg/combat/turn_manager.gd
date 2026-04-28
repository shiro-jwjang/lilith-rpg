extends RefCounted

const BURN_RATE := 0.06
const BLEED_RATE := 0.04


func on_turn_start(unit) -> bool:
	_tick_duration_effects(unit)

	if unit.status_effects.has("stun"):
		var stun: Dictionary = unit.status_effects["stun"]
		var remaining_turns := int(stun.get("remaining_turns", 0)) - 1
		if remaining_turns <= 0:
			unit.status_effects.erase("stun")
		else:
			stun["remaining_turns"] = remaining_turns
			unit.status_effects["stun"] = stun
		return false

	return true


func on_turn_end(unit) -> int:
	var total_damage := 0

	if unit.status_effects.has("burn"):
		var burn: Dictionary = unit.status_effects["burn"]
		var burn_stacks := int(burn.get("stacks", 1))
		total_damage += int(floor(float(unit.max_hp) * BURN_RATE)) * burn_stacks

	if unit.status_effects.has("bleed"):
		var bleed: Dictionary = unit.status_effects["bleed"]
		var bleed_stacks := int(bleed.get("stacks", 1))
		total_damage += int(floor(float(unit.max_hp) * BLEED_RATE)) * bleed_stacks

	if total_damage > 0:
		unit.take_damage(total_damage)

	return total_damage


func _tick_duration_effects(unit) -> void:
	var expired_keys: Array = []
	for effect_key in unit.status_effects:
		if effect_key == "stun":
			continue

		var effect_value = unit.status_effects[effect_key]
		if not (effect_value is Dictionary):
			continue
		if not effect_value.has("remaining_turns"):
			continue

		var remaining_turns := int(effect_value["remaining_turns"]) - 1
		if remaining_turns <= 0:
			expired_keys.append(effect_key)
		else:
			effect_value["remaining_turns"] = remaining_turns
			unit.status_effects[effect_key] = effect_value

	for effect_key in expired_keys:
		unit.status_effects.erase(effect_key)
