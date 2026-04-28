extends RefCounted

var effects: Dictionary = {}


func apply_effect(effect) -> void:
	if effect == null:
		return
	if effects.has(effect.type):
		effects[effect.type].apply(effect)
	else:
		effects[effect.type] = effect


func has_effect(effect_type: String) -> bool:
	return effects.has(effect_type)


func tick_all(unit = null) -> int:
	var total_damage := 0
	var expired_types: Array[String] = []

	for effect_type in effects:
		var effect = effects[effect_type]
		total_damage += int(effect.on_tick(unit))
		effect.remaining_turns -= 1
		if effect.remaining_turns <= 0:
			expired_types.append(effect_type)

	for effect_type in expired_types:
		var effect = effects[effect_type]
		effect.on_expire()
		effects.erase(effect_type)

	return total_damage


func get_effective_stat(stat_name: String, base_value: int) -> int:
	var effective_value := int(base_value)

	if stat_name == "speed" and has_effect("slow"):
		effective_value = int(floor(float(base_value) * 0.8))
	elif stat_name == "atk" and has_effect("weaken"):
		effective_value = int(floor(float(base_value) * 0.8))
	elif stat_name == "def" and has_effect("shatter"):
		effective_value = int(floor(float(base_value) * 0.75))

	return effective_value


func is_action_blocked() -> bool:
	return has_effect("stun")


func check_boss_immunity(effect_type: String, immune_tags: Array) -> bool:
	return immune_tags.has(effect_type)
