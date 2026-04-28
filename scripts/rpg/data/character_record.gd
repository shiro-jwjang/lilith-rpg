extends "res://scripts/rpg/data/base_record.gd"


func _get_id_field() -> String:
	return "character_id"


func _get_required_fields() -> Array:
	return [
		"character_id",
		"name",
		"role",
		"max_hp",
		"max_mp",
		"attack",
		"defense",
		"speed",
		"crit_rate",
		"effect_accuracy",
		"effect_resistance",
		"skill_ids",
	]


func _get_enum_fields() -> Dictionary:
	return {
		"role": ["front", "guardian", "support"],
	}


func _get_range_fields() -> Dictionary:
	return {
		"max_hp": {"min": 0, "min_inclusive": false},
		"crit_rate": {"min": 0.0, "max": 1.0},
	}


func _validate_custom(errors: Array) -> void:
	if _has_field("skill_ids") and not (_get_field("skill_ids") is Array):
		errors.append("skill_ids must be an array")

