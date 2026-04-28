extends "res://test/rpg/test_base.gd"

const EVENT_MANAGER_PATH := "res://scripts/rpg/events/event_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_event_001_all_events_have_at_least_two_choices() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	for event_id in ["ruined_altar", "ruin_merchant", "sealed_ward", "moonlight_rift"]:
		var event = manager.get_event(event_id)
		assert_not_null(event, "event-001 expected event %s to exist" % event_id)
		if event == null:
			continue
		var choices: Array = event.get_all_choices()
		assert_ge(choices.size(), 2, "event-001 expected %s to have at least two choices" % event_id)


func test_event_002_event_completion_assigns_next_node() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var result: Dictionary = manager.resolve_choice("ruined_altar", "기도", _base_context())
	assert_not_null(result.get("current_node", null), "event-002 expected current node to exist")
	assert_true(bool(result.get("event_resolved", false)), "event-002 expected event to resolve")
	assert_not_null(result.get("next_node", null), "event-002 expected next node to be assigned")


func test_event_003_failure_outcome_applies_penalty() -> void:
	var manager = _make_manager({
		"rng": _FloatSequenceRng.new([0.90]),
	})
	if manager == null:
		return

	var context := _base_context()
	var result: Dictionary = manager.resolve_choice("ruined_altar", "파괴", context)
	var player_after: Dictionary = result.get("player", {})
	var hp_decreased := float(player_after.get("hp", context["player"]["hp"])) < float(context["player"]["hp"])
	var mp_decreased := float(player_after.get("mp", context["player"]["mp"])) < float(context["player"]["mp"])
	var gold_decreased := int(player_after.get("wallet", null).get_gold()) < int(context["player"]["wallet"].get_gold())
	var status_added := (player_after.get("status_effects", []) as Array).size() > (context["player"]["status_effects"] as Array).size()
	var combat_triggered := bool(result.get("combat_triggered", false))
	assert_true(
		hp_decreased or mp_decreased or gold_decreased or status_added or combat_triggered,
		"event-003 expected failure outcome to apply some penalty"
	)


func test_event_004_event_combat_uses_normal_rules_and_event_enemy_pool() -> void:
	var manager = _make_manager({
		"rng": _FloatSequenceRng.new([0.90]),
	})
	if manager == null:
		return

	var result: Dictionary = manager.resolve_choice("ruined_altar", "파괴", _base_context())
	var combat: Dictionary = result.get("combat", {})
	assert_true(bool(result.get("combat_triggered", false)), "event-004 expected combat branch to trigger")
	assert_eq(String(combat.get("battle_type", "")), "normal", "event-004 expected normal battle rules")
	var gold_reward := int(combat.get("gold", -1))
	assert_ge(gold_reward, 20, "event-004 expected event combat gold >= 20")
	assert_true(gold_reward <= 35, "event-004 expected event combat gold <= 35")
	var enemy_id := String(combat.get("enemy", ""))
	var event_enemy_pool: Array = combat.get("event_enemy_pool", [])
	assert_true(event_enemy_pool.has(enemy_id), "event-004 expected enemy to come from event-specific pool")


func _make_manager(config: Dictionary = {}):
	var script = load(EVENT_MANAGER_PATH)
	assert_not_null(script, "expected event_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _base_context() -> Dictionary:
	return {
		"current_node": {"id": "event_node_1", "type": "event", "event_id": "ruined_altar"},
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


class _FloatSequenceRng extends RefCounted:
	var _values: Array
	var _index := 0

	func _init(values: Array) -> void:
		_values = values.duplicate(true)

	func randf() -> float:
		if _values.is_empty():
			return 0.0
		var value = float(_values[min(_index, _values.size() - 1)])
		_index += 1
		return value


func _make_wallet(gold: int):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})
