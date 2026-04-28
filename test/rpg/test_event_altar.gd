extends "res://test/rpg/test_base.gd"

const EVENT_MANAGER_PATH := "res://scripts/rpg/events/event_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_event_005_ruined_altar_pray_costs_hp_mp_and_offers_relic() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var result: Dictionary = manager.resolve_choice("ruined_altar", "기도", _base_context())
	var player_after: Dictionary = result.get("player", {})
	assert_true(abs(float(player_after.get("hp", 0.0)) - 85.0) < 0.001, "event-005 expected hp to become 85")
	assert_true(abs(float(player_after.get("mp", 0.0)) - 47.5) < 0.001, "event-005 expected mp to become 47.5")
	assert_true(bool(result.get("relic_offered", false)), "event-005 expected relic selection to be offered")
	assert_eq(String(result.get("reward", {}).get("type", "")), "relic_candidate", "event-005 expected relic candidate reward")


func test_event_006_ruined_altar_offering_costs_mp_and_grants_reward() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var result: Dictionary = manager.resolve_choice("ruined_altar", "봉헌", _base_context())
	var player_after: Dictionary = result.get("player", {})
	assert_true(abs(float(player_after.get("mp", 0.0)) - 45.0) < 0.001, "event-006 expected mp to become 45")
	assert_not_null(result.get("reward", null), "event-006 expected reward payload")


func test_event_007_ruined_altar_destroy_is_fifty_fifty_without_cost() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var relic_count := 0
	var combat_count := 0
	var iterations := 10000
	for _index in range(iterations):
		var context := _base_context()
		var result: Dictionary = manager.resolve_choice("ruined_altar", "파괴", context)
		var player_after: Dictionary = result.get("player", {})
		assert_true(abs(float(player_after.get("hp", 0.0)) - 100.0) < 0.001, "event-007 expected hp unchanged")
		assert_true(abs(float(player_after.get("mp", 0.0)) - 50.0) < 0.001, "event-007 expected mp unchanged")
		assert_eq(int(player_after.get("wallet", null).get_gold()), 80, "event-007 expected gold unchanged")
		if bool(result.get("combat_triggered", false)):
			combat_count += 1
		elif String(result.get("reward", {}).get("type", "")) == "relic_candidate":
			relic_count += 1

	var relic_rate := float(relic_count) / float(iterations)
	var combat_rate := float(combat_count) / float(iterations)
	assert_true(abs(relic_rate - 0.5) <= 0.03, "event-007 expected relic branch within ±3%%")
	assert_true(abs(combat_rate - 0.5) <= 0.03, "event-007 expected combat branch within ±3%%")


func test_event_008_ruined_altar_hidden_wish_stays_hidden_below_visit_threshold() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["visit_count"] = 2
	var choices: Array = manager.get_visible_choices("ruined_altar", context)
	assert_false(_has_choice(choices, "기원"), "event-008 expected hidden choice to stay hidden")


func test_event_009_ruined_altar_hidden_wish_unlocks_at_visit_threshold() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["visit_count"] = 3
	var choices: Array = manager.get_visible_choices("ruined_altar", context)
	assert_true(_has_choice(choices, "기원"), "event-009 expected hidden choice to become visible")


func test_event_010_ruined_altar_wish_guarantees_one_relic() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["visit_count"] = 3
	var result: Dictionary = manager.resolve_choice("ruined_altar", "기원", context)
	var player_after: Dictionary = result.get("player", {})
	assert_true(abs(float(player_after.get("hp", 0.0)) - 70.0) < 0.001, "event-010 expected hp to become 70")
	assert_true(abs(float(player_after.get("mp", 0.0)) - 42.5) < 0.001, "event-010 expected mp to become 42.5")
	assert_true(bool(result.get("relic_granted", false)), "event-010 expected relic to be guaranteed")
	assert_eq(int(result.get("reward_count", 0)), 1, "event-010 expected exactly one relic")


func _make_manager(config: Dictionary = {}):
	var script = load(EVENT_MANAGER_PATH)
	assert_not_null(script, "expected event_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _base_context() -> Dictionary:
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


func _has_choice(choices: Array, choice_id: String) -> bool:
	for choice in choices:
		if String(choice.get("id", "")) == choice_id:
			return true
	return false


func _make_wallet(gold: int):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})
