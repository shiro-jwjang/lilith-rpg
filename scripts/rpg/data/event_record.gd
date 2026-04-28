extends "res://scripts/rpg/data/base_record.gd"


func _get_id_field() -> String:
	return "event_id"


func _get_required_fields() -> Array:
	return [
		"event_id",
		"title",
		"options",
		"required_conditions",
		"success_outcomes",
		"failure_outcomes",
		"followup_node_type",
	]


func _validate_custom(errors: Array) -> void:
	if not _has_field("options"):
		return
	var options = _get_field("options")
	if not (options is Array):
		errors.append("options must be an array")
		return
	if options.size() < 2:
		errors.append("options must have at least 2 entries")

