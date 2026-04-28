extends "res://scripts/rpg/data/base_record.gd"


func _get_id_field() -> String:
	return "enemy_id"


func _get_required_fields() -> Array:
	return [
		"enemy_id",
		"name",
		"tier",
		"max_hp",
		"attack",
		"defense",
		"speed",
		"reward_group_id",
		"ai_pattern_id",
		"loot_table_id",
		"status_immunities",
	]


func _get_enum_fields() -> Dictionary:
	return {
		"tier": ["normal", "elite", "unique", "boss"],
	}


func _get_range_fields() -> Dictionary:
	return {
		"max_hp": {"min": 0, "min_inclusive": false},
	}


func _validate_custom(errors: Array) -> void:
	if _has_field("status_immunities") and not (_get_field("status_immunities") is Array):
		errors.append("status_immunities must be an array")

