extends "res://scripts/rpg/data/base_record.gd"


func _get_id_field() -> String:
	return "reward_group_id"


func _get_required_fields() -> Array:
	return [
		"reward_group_id",
		"guaranteed_rewards",
		"optional_rewards",
		"selection_count",
		"rarity_floor",
		"pity_rule",
	]


func _get_range_fields() -> Dictionary:
	return {
		"selection_count": {"min": 0},
	}


func _validate_custom(errors: Array) -> void:
	if _has_field("guaranteed_rewards") and not (_get_field("guaranteed_rewards") is Array):
		errors.append("guaranteed_rewards must be an array")

	if not _has_field("pity_rule"):
		return
	var pity_rule = _get_field("pity_rule")
	if not (pity_rule is Dictionary):
		errors.append("pity_rule must be a dictionary")
		return
	if not pity_rule.has("threshold"):
		errors.append("pity_rule missing threshold")
	elif pity_rule["threshold"] <= 0:
		errors.append("pity_rule threshold must be > 0")
	if not pity_rule.has("guaranteed_rarity"):
		errors.append("pity_rule missing guaranteed_rarity")

