extends RefCounted

const RELIC_MAX := 4
const RELIC_INSTANCE_PATH := "res://scripts/rpg/relics/relic_instance.gd"
const RELIC_EFFECTS_PATH := "res://scripts/rpg/relics/relic_effects.gd"

var relics: Array = []

var _relic_instance_script = null
var _relic_effects_script = null


func _init(config: Dictionary = {}) -> void:
	_relic_instance_script = load(RELIC_INSTANCE_PATH)
	_relic_effects_script = load(RELIC_EFFECTS_PATH)

	for relic_id in config.get("relics", []):
		_append_relic(relic_id)


func add_relic(relic_id: String) -> Dictionary:
	if has_relic(relic_id):
		return {
			"success": false,
			"discarded": true,
			"reason": "already_owned",
			"count": relics.size(),
		}

	if relics.size() >= RELIC_MAX:
		return {
			"success": false,
			"discarded": true,
			"count": relics.size(),
		}

	_append_relic(relic_id)
	return {
		"success": true,
		"discarded": false,
		"count": relics.size(),
	}


func has_relic(relic_id: String) -> bool:
	for relic in relics:
		if relic.relic_id == relic_id:
			return true
	return false


func get_relic_count() -> int:
	return relics.size()


func get_relic_uses_remaining(relic_id: String) -> int:
	for relic in relics:
		if relic.relic_id == relic_id:
			return relic.uses_remaining
	return -1


func apply_effects(context: Dictionary) -> Dictionary:
	var result: Dictionary = context.duplicate(true)
	if _relic_effects_script == null:
		return result

	for relic in relics:
		result = _relic_effects_script.apply_effect(relic, result)

	return result


func on_run_end() -> void:
	relics.clear()


func _append_relic(relic_id: String) -> void:
	if _relic_instance_script == null:
		return
	relics.append(_relic_instance_script.new({
		"relic_id": relic_id,
	}))
