extends "res://scripts/rpg/data/base_record.gd"


func _get_id_field() -> String:
	return "node_id"


func _get_required_fields() -> Array:
	return [
		"node_id",
		"node_type",
		"unlock_condition",
		"outgoing_edges",
		"encounter_pool_id",
		"reward_group_id",
	]


func _get_enum_fields() -> Dictionary:
	return {
		"node_type": ["combat", "event", "treasure", "shop", "campfire", "unique", "boss"],
	}


func _validate_custom(errors: Array) -> void:
	if _has_field("outgoing_edges") and not (_get_field("outgoing_edges") is Array):
		errors.append("outgoing_edges must be an array")

