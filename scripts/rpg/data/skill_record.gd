extends "res://scripts/rpg/data/base_record.gd"


func _get_id_field() -> String:
	return "skill_id"


func _get_required_fields() -> Array:
	return [
		"skill_id",
		"name",
		"mp_cost",
		"target_type",
		"damage_ratio",
		"base_status_chance",
		"status_effect_ids",
		"status_duration",
		"tags",
	]


func _get_enum_fields() -> Dictionary:
	return {
		"target_type": ["single_enemy", "all_enemies", "single_ally", "all_allies", "self"],
	}


func _get_range_fields() -> Dictionary:
	return {
		"mp_cost": {"min": 0},
		"damage_ratio": {"min": 0.0},
		"base_status_chance": {"min": 0.0, "max": 1.0},
	}


func _validate_custom(errors: Array) -> void:
	if _has_field("status_effect_ids") and not (_get_field("status_effect_ids") is Array):
		errors.append("status_effect_ids must be an array")

