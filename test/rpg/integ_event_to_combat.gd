extends "res://test/rpg/test_base.gd"

const BATTLE_MANAGER_PATH := "res://scripts/rpg/combat/battle_manager.gd"
const EVENT_MANAGER_PATH := "res://scripts/rpg/events/event_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_integ_007_ruined_altar_destroy_can_trigger_combat() -> void:
	var manager = _event_manager([0.9, 0.0])
	if manager == null:
		return

	var result: Dictionary = manager.resolve_choice("ruined_altar", "파괴", _altar_context())
	assert_true(bool(result.get("combat_triggered", false)), "integ-007 expected ruined altar destroy to trigger combat")
	assert_eq(String(result.get("next_state", "")), "combat", "integ-007 expected next state combat")
	assert_true(String(result.get("combat", {}).get("enemy", "")) != "", "integ-007 expected enemy id in combat payload")


func test_integ_008_ruin_merchant_rob_can_trigger_combat() -> void:
	var manager = _event_manager([0.9])
	if manager == null:
		return

	var result: Dictionary = manager.resolve_choice("ruin_merchant", "강탈", _merchant_context())
	assert_true(bool(result.get("combat_triggered", false)), "integ-008 expected ruin merchant rob to trigger combat")
	assert_eq(String(result.get("next_state", "")), "combat", "integ-008 expected next state combat")
	assert_true((result.get("combat", {}).get("event_enemy_pool", []) as Array).size() >= 1, "integ-008 expected enemy pool metadata")


func test_integ_009_combat_event_payload_can_initialize_battle_manager() -> void:
	var event_manager = _event_manager([0.9, 0.0])
	var battle_manager = _battle_manager()
	if event_manager == null or battle_manager == null:
		return

	var result: Dictionary = event_manager.resolve_choice("ruined_altar", "파괴", _altar_context())
	var combat: Dictionary = result.get("combat", {})
	assert_true(bool(result.get("combat_triggered", false)), "integ-009 expected combat branch setup")

	battle_manager.init_battle([
		{
			"internal_id": 1,
			"current_hp": 100,
			"max_hp": 100,
			"atk": 15,
			"def": 8,
			"speed": 12,
		},
	], [
		{
			"internal_id": 101,
			"current_hp": 70,
			"max_hp": 70,
			"atk": 12,
			"def": 4,
			"speed": 10,
			"tier": String(combat.get("battle_type", "normal")),
			"status_effects": {
				"enemy_id": String(combat.get("enemy", "")),
			},
		},
	])

	assert_eq(battle_manager.enemies.size(), 1, "integ-009 expected one battle enemy")
	assert_eq(String(battle_manager.enemies[0].status_effects.get("enemy_id", "")), String(combat.get("enemy", "")), "integ-009 expected event enemy metadata preserved")
	assert_eq(battle_manager.target_turn_range["min"], 2, "integ-009 expected normal combat target range from event battle type")


func _event_manager(values: Array):
	var script = load(EVENT_MANAGER_PATH)
	assert_not_null(script, "expected event_manager.gd to exist")
	if script == null:
		return null
	return script.new({
		"rng": _FloatSequenceRng.new(values),
	})


func _battle_manager():
	var script = load(BATTLE_MANAGER_PATH)
	assert_not_null(script, "expected battle_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _altar_context() -> Dictionary:
	return {
		"current_node": {"id": "event_node_altar", "type": "event", "event_id": "ruined_altar"},
		"player": {
			"hp_max": 100.0,
			"hp": 100.0,
			"mp_max": 50.0,
			"mp": 50.0,
			"wallet": _make_wallet(80),
			"status_effects": [],
		},
		"visit_count": 0,
		"battle_wins": 0,
	}


func _merchant_context() -> Dictionary:
	return {
		"current_node": {"id": "event_node_merchant", "type": "event", "event_id": "ruin_merchant"},
		"player": {
			"hp_max": 100.0,
			"hp": 100.0,
			"mp_max": 50.0,
			"mp": 50.0,
			"wallet": _make_wallet(30),
			"status_effects": [],
		},
		"visit_count": 0,
		"battle_wins": 0,
	}


class _FloatSequenceRng extends RefCounted:
	var _values: Array = []
	var _index := 0

	func _init(values: Array) -> void:
		_values = values.duplicate(true)

	func randf() -> float:
		if _values.is_empty():
			return 0.0
		var clamped_index := mini(_index, _values.size() - 1)
		var value := float(_values[clamped_index])
		_index += 1
		return value

	func randi_range(start: int, end: int) -> int:
		if start >= end:
			return start
		var span := end - start + 1
		var offset := int(floor(randf() * float(span)))
		offset = clampi(offset, 0, span - 1)
		return start + offset


func _make_wallet(gold: int):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})
