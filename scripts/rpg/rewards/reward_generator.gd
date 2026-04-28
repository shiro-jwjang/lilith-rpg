extends RefCounted

const REWARD_TABLES_PATH := "res://scripts/rpg/rewards/reward_tables.gd"

var _rng = null
var _tables = null
var _unlock_tracker = null
var _event_rewarded_choices: Dictionary = {}
var _event_reward_count := 0


func _init(config: Dictionary = {}) -> void:
	_tables = load(REWARD_TABLES_PATH)
	_rng = config.get("rng", null)
	if _rng == null:
		var default_rng := RandomNumberGenerator.new()
		default_rng.randomize()
		_rng = default_rng
	_unlock_tracker = config.get("unlock_tracker", null)


func generate_rewards(battle_type: String) -> Dictionary:
	var normalized_type := battle_type.to_lower()
	var rewards := {
		"gold": _roll_gold(normalized_type),
		"items": [],
		"relics": [],
	}

	match normalized_type:
		"normal", "elite", "unique":
			rewards["items"] = [_roll_item(normalized_type)]
		"boss":
			rewards["relics"] = [_tables.BOSS_RELIC.duplicate(true)]
			_call_unlock_check_once()

	return rewards


func generate_treasure_rewards() -> Dictionary:
	return {
		"gold": 0,
		"items": [],
		"relics": [_tables.TREASURE_RELIC.duplicate(true)],
	}


func generate_event_reward(choice: String) -> Dictionary:
	if _event_rewarded_choices.has(choice):
		return {
			"gold": 0,
			"items": [],
			"relics": [],
			"duplicate": true,
		}

	_event_rewarded_choices[choice] = true
	_event_reward_count += 1
	var reward_template: Dictionary = _tables.EVENT_REWARDS.get(choice, _tables.EVENT_REWARDS["A"])
	return {
		"gold": int(reward_template.get("gold", 0)),
		"items": (reward_template.get("items", []) as Array).duplicate(true),
		"relics": (reward_template.get("relics", []) as Array).duplicate(true),
	}


func get_event_reward_count() -> int:
	return _event_reward_count


func _roll_gold(battle_type: String) -> int:
	var gold_range: Dictionary = _tables.GOLD_RANGES.get(battle_type, {"min": 0, "max": 0})
	return _randi_range(int(gold_range.get("min", 0)), int(gold_range.get("max", 0)))


func _roll_item(battle_type: String) -> Dictionary:
	var pool: Array = _tables.ITEM_POOLS.get(battle_type, [])
	if pool.is_empty():
		return {}

	var roll := _randf()
	var cumulative := 0.0
	for entry in pool:
		cumulative += float(entry.get("weight", 0.0))
		if roll <= cumulative:
			return entry.duplicate(true)

	return pool[pool.size() - 1].duplicate(true)


func _call_unlock_check_once() -> void:
	if _unlock_tracker != null and _unlock_tracker.has_method("perform_unlock_check"):
		_unlock_tracker.perform_unlock_check()


func _randi_range(from_value: int, to_value: int) -> int:
	if _rng != null and _rng.has_method("randi_range"):
		return int(_rng.randi_range(from_value, to_value))
	return from_value


func _randf() -> float:
	if _rng != null and _rng.has_method("randf"):
		return float(_rng.randf())
	return randf()
