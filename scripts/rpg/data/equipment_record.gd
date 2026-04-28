extends "res://scripts/rpg/data/base_record.gd"


func _get_id_field() -> String:
	return "equipment_id"


func _get_required_fields() -> Array:
	return [
		"equipment_id",
		"name",
		"slot",
		"rarity",
		"primary_bonus",
		"secondary_bonus",
		"upgrade_level_max",
		"special_effect_text",
	]


func _get_enum_fields() -> Dictionary:
	return {
		"slot": ["weapon", "armor", "accessory", "trinket"],
	}


func _get_range_fields() -> Dictionary:
	return {
		"upgrade_level_max": {"min": 1},
	}

