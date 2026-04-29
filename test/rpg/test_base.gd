extends RefCounted

var _failures: Array[String] = []


func clear_failures() -> void:
	_failures.clear()


func get_failures() -> Array[String]:
	return _failures.duplicate()


func assert_true(value, message := "") -> void:
	if not value:
		_record_failure(_message_or_default(message, "Expected condition to be true"))


func assert_false(value, message := "") -> void:
	if value:
		_record_failure(_message_or_default(message, "Expected condition to be false"))


func assert_eq(actual, expected, message := "") -> void:
	if actual != expected:
		_record_failure(_message_or_default(message, "Expected %s == %s" % [actual, expected]))


func assert_ne(actual, expected, message := "") -> void:
	if actual == expected:
		_record_failure(_message_or_default(message, "Expected %s != %s" % [actual, expected]))


func assert_gt(actual, expected, message := "") -> void:
	if not (actual > expected):
		_record_failure(_message_or_default(message, "Expected %s > %s" % [actual, expected]))


func assert_ge(actual, expected, message := "") -> void:
	if not (actual >= expected):
		_record_failure(_message_or_default(message, "Expected %s >= %s" % [actual, expected]))


func assert_has(container, key, message := "") -> void:
	var has_value := false
	if container is Dictionary:
		has_value = container.has(key)
	elif container is Array:
		has_value = container.has(key)
	if not has_value:
		_record_failure(_message_or_default(message, "Expected container to have %s" % [key]))


func assert_null(value, message := "") -> void:
	if value != null:
		_record_failure(_message_or_default(message, "Expected value to be null"))


func assert_not_null(value, message := "") -> void:
	if value == null:
		_record_failure(_message_or_default(message, "Expected value to be non-null"))


func _record_failure(message: String) -> void:
	_failures.append(message)


func _message_or_default(message: String, default_message: String) -> String:
	return default_message if message.is_empty() else message


func _normalize_enemy_config(enemy: Dictionary) -> Dictionary:
	var max_hp := int(enemy.get("max_hp", enemy.get("hp", 0)))
	return {
		"name": String(enemy.get("name", "")),
		"max_hp": max_hp,
		"current_hp": max_hp,
		"max_mp": int(enemy.get("max_mp", enemy.get("mp", 0))),
		"current_mp": int(enemy.get("max_mp", enemy.get("mp", 0))),
		"atk": int(enemy.get("atk", enemy.get("attack", 0))),
		"def": int(enemy.get("def", enemy.get("defense", 0))),
		"speed": int(enemy.get("speed", 0)),
		"tier": String(enemy.get("tier", "normal")),
		"phases": int(enemy.get("phases", 1)),
		"phase_transition_hp": int(enemy.get("phase_transition_hp", 0)),
		"skills": (enemy.get("skills", []) as Array).duplicate(true),
		"status_effects": {"enemy_status_names": (enemy.get("status_effects", []) as Array).duplicate(true)},
	}

