extends "res://test/rpg/test_base.gd"

const EVENT_MANAGER_PATH := "res://scripts/rpg/events/event_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_event_016_sealed_ward_treatment_restores_hp() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["player"]["hp"] = 40.0
	var result: Dictionary = manager.resolve_choice("sealed_ward", "치료", context)
	var hp_after := float(result.get("player", {}).get("hp", 0.0))
	assert_gt(hp_after, 40.0, "event-016 expected hp to increase")
	assert_true(hp_after <= 100.0, "event-016 expected hp not to exceed max")


func test_event_017_sealed_ward_release_clears_debuffs_and_grants_gold() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["player"]["wallet"] = _make_wallet(50)
	context["player"]["status_effects"] = ["poison", "weakness"]
	var result: Dictionary = manager.resolve_choice("sealed_ward", "해방", context)
	var player_after: Dictionary = result.get("player", {})
	assert_true((player_after.get("status_effects", []) as Array).size() < 2, "event-017 expected debuffs to be removed")
	assert_true(int(player_after.get("wallet", null).get_gold()) > 50, "event-017 expected gold to increase")


func test_event_018_sealed_ward_plunder_is_fifty_fifty() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var equipment_count := 0
	var combat_count := 0
	var iterations := 10000
	for _index in range(iterations):
		var result: Dictionary = manager.resolve_choice("sealed_ward", "약탈", _base_context())
		if bool(result.get("combat_triggered", false)):
			combat_count += 1
		elif String(result.get("reward", {}).get("type", "")) == "equipment":
			equipment_count += 1

	var equipment_rate := float(equipment_count) / float(iterations)
	var combat_rate := float(combat_count) / float(iterations)
	assert_true(abs(equipment_rate - 0.5) <= 0.03, "event-018 expected equipment branch within ±3%%")
	assert_true(abs(combat_rate - 0.5) <= 0.03, "event-018 expected combat branch within ±3%%")


func test_event_019_sealed_ward_unseal_stays_hidden_below_win_threshold() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["battle_wins"] = 2
	var choices: Array = manager.get_visible_choices("sealed_ward", context)
	assert_false(_has_choice(choices, "봉인 해제"), "event-019 expected hidden choice to stay hidden")


func test_event_020_sealed_ward_unseal_unlocks_at_win_threshold() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["battle_wins"] = 3
	var choices: Array = manager.get_visible_choices("sealed_ward", context)
	assert_true(_has_choice(choices, "봉인 해제"), "event-020 expected hidden choice to unlock")


func test_event_021_sealed_ward_unseal_grants_relic_candidate() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["battle_wins"] = 3
	var result: Dictionary = manager.resolve_choice("sealed_ward", "봉인 해제", context)
	assert_eq(String(result.get("reward", {}).get("type", "")), "relic_candidate", "event-021 expected relic candidate reward")


func _make_manager(config: Dictionary = {}):
	var script = load(EVENT_MANAGER_PATH)
	assert_not_null(script, "expected event_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _base_context() -> Dictionary:
	return {
		"current_node": {"id": "event_node_ward", "type": "event", "event_id": "sealed_ward"},
		"player": {
			"hp_max": 100.0,
			"hp": 80.0,
			"mp_max": 50.0,
			"mp": 30.0,
			"wallet": _make_wallet(60),
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
