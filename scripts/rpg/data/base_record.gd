extends RefCounted

var _data: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	_data = data.duplicate(true)


func get_id():
	return _data.get(_get_id_field(), null)


func get_data() -> Dictionary:
	return _data.duplicate(true)


func validate() -> Array:
	var errors: Array = []
	_validate_required_fields(errors)
	_validate_enum_fields(errors)
	_validate_range_fields(errors)
	_validate_custom(errors)
	return errors


func _get_id_field() -> String:
	return ""


func _get_required_fields() -> Array:
	return []


func _get_enum_fields() -> Dictionary:
	return {}


func _get_range_fields() -> Dictionary:
	return {}


func _validate_custom(_errors: Array) -> void:
	pass


func _validate_required_fields(errors: Array) -> void:
	for field_name in _get_required_fields():
		if not _data.has(field_name):
			errors.append("Missing required field: %s" % field_name)


func _validate_enum_fields(errors: Array) -> void:
	var enum_fields := _get_enum_fields()
	for key in enum_fields:
		if not _data.has(key):
			continue
		var allowed_values: Array = enum_fields[key]
		if not allowed_values.has(_data[key]):
			errors.append("Invalid %s: %s" % [key, str(_data[key])])


func _validate_range_fields(errors: Array) -> void:
	var range_fields := _get_range_fields()
	for key in range_fields:
		if not _data.has(key):
			continue
		var rule: Dictionary = range_fields[key]
		var value = _data[key]
		if not (value is int or value is float):
			errors.append("%s must be numeric" % key)
			continue

		if rule.has("min"):
			var min_value = rule["min"]
			var min_inclusive: bool = bool(rule.get("min_inclusive", true))
			if min_inclusive:
				if value < min_value:
					errors.append("%s must be >= %s" % [key, str(min_value)])
			elif value <= min_value:
				errors.append("%s must be > %s" % [key, str(min_value)])

		if rule.has("max"):
			var max_value = rule["max"]
			var max_inclusive: bool = bool(rule.get("max_inclusive", true))
			if max_inclusive:
				if value > max_value:
					errors.append("%s must be <= %s" % [key, str(max_value)])
			elif value >= max_value:
				errors.append("%s must be < %s" % [key, str(max_value)])


func _has_field(field_name: String) -> bool:
	return _data.has(field_name)


func _get_field(field_name: String, default_value = null):
	return _data.get(field_name, default_value)
