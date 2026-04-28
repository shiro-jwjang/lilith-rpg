extends "res://scripts/rpg/data/base_record.gd"


func _get_id_field() -> String:
	return "relic_id"


func _get_required_fields() -> Array:
	return [
		"relic_id",
		"name",
		"rarity",
		"trigger_condition",
		"effect_text",
		"stack_rule",
		"penalty_text",
	]

