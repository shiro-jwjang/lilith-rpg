extends "res://test/rpg/test_base.gd"

const EVENT_MANAGER_PATH := "res://scripts/rpg/events/event_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_event_011_ruin_merchant_purchase_spends_gold_for_item_reward() -> void:
	var manager = _make_manager({
		"rng": _FloatSequenceRng.new([0.10]),
	})
	if manager == null:
		return

	var context := _base_context()
	context["player"]["wallet"] = _make_wallet(50)
	var result: Dictionary = manager.resolve_choice("ruin_merchant", "구매", context)
	var player_after: Dictionary = result.get("player", {})
	assert_true(int(player_after.get("wallet", null).get_gold()) < 50, "event-011 expected gold to decrease")
	var reward_type := String(result.get("reward", {}).get("type", ""))
	assert_true(
		["equipment", "potion", "upgrade_material"].has(reward_type),
		"event-011 expected purchase reward to be equipment, potion, or upgrade material"
	)


func test_event_012_ruin_merchant_rob_is_sixty_forty() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var gold_bonus_count := 0
	var combat_count := 0
	var iterations := 10000
	for _index in range(iterations):
		var context := _base_context()
		var result: Dictionary = manager.resolve_choice("ruin_merchant", "강탈", context)
		if bool(result.get("combat_triggered", false)):
			combat_count += 1
		elif int(result.get("player", {}).get("wallet", null).get_gold()) > 30:
			gold_bonus_count += 1

	var gold_bonus_rate := float(gold_bonus_count) / float(iterations)
	var combat_rate := float(combat_count) / float(iterations)
	assert_true(abs(gold_bonus_rate - 0.6) <= 0.03, "event-012 expected gold bonus branch within ±3%%")
	assert_true(abs(combat_rate - 0.4) <= 0.03, "event-012 expected combat branch within ±3%%")


func test_event_013_ruin_merchant_special_trade_stays_hidden_below_gold_threshold() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["player"]["wallet"] = _make_wallet(99)
	var choices: Array = manager.get_visible_choices("ruin_merchant", context)
	assert_false(_has_choice(choices, "특별 거래"), "event-013 expected special trade to stay hidden")


func test_event_014_ruin_merchant_special_trade_unlocks_at_gold_threshold() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["player"]["wallet"] = _make_wallet(100)
	var choices: Array = manager.get_visible_choices("ruin_merchant", context)
	assert_true(_has_choice(choices, "특별 거래"), "event-014 expected special trade to unlock")


func test_event_015_ruin_merchant_special_trade_buys_one_high_equipment() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["player"]["wallet"] = _make_wallet(150)
	var result: Dictionary = manager.resolve_choice("ruin_merchant", "특별 거래", context)
	var player_after: Dictionary = result.get("player", {})
	assert_true(int(player_after.get("wallet", null).get_gold()) < 150, "event-015 expected gold to decrease")
	assert_eq(String(result.get("reward", {}).get("type", "")), "high_equipment", "event-015 expected high equipment reward")
	assert_eq(int(result.get("reward_count", 0)), 1, "event-015 expected exactly one reward")


func _make_manager(config: Dictionary = {}):
	var script = load(EVENT_MANAGER_PATH)
	assert_not_null(script, "expected event_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _base_context() -> Dictionary:
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


func _has_choice(choices: Array, choice_id: String) -> bool:
	for choice in choices:
		if String(choice.get("id", "")) == choice_id:
			return true
	return false


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
