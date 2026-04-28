extends "res://test/rpg/e2e_support.gd"


func test_e2e_006_event_chain_persists_gold_hp_mp_and_rewards_across_three_events() -> void:
	var event_manager = _event_manager({"rng": _SequenceRng.new([0.50])})
	var relic_manager = _relic_manager()
	if event_manager == null or relic_manager == null:
		return

	var player := _make_player({"hp": 100.0, "mp": 50.0, "gold": 80, "visit_count": 0})
	var run_inventory = _RunInventory.new(0, {"wallet": player["wallet"]})

	var altar_result: Dictionary = event_manager.resolve_choice("ruined_altar", "기도", _event_context("ruined_altar", player))
	_apply_event_result_to_player(player, altar_result)
	_apply_event_reward_to_run(altar_result, run_inventory, relic_manager)
	player["visit_count"] = int(player.get("visit_count", 0)) + 1

	var merchant_result: Dictionary = event_manager.resolve_choice("ruin_merchant", "구매", _event_context("ruin_merchant", player))
	_apply_event_result_to_player(player, merchant_result)
	_apply_event_reward_to_run(merchant_result, run_inventory, relic_manager)
	player["visit_count"] = int(player.get("visit_count", 0)) + 1

	var ward_result: Dictionary = event_manager.resolve_choice("sealed_ward", "치료", _event_context("sealed_ward", player))
	_apply_event_result_to_player(player, ward_result)
	_apply_event_reward_to_run(ward_result, run_inventory, relic_manager)
	player["visit_count"] = int(player.get("visit_count", 0)) + 1

	assert_true(abs(float(player.get("hp", 0.0)) - 100.0) < 0.001, "e2e-006 expected final HP 100 after heal chain")
	assert_true(abs(float(player.get("mp", 0.0)) - 47.5) < 0.001, "e2e-006 expected final MP 47.5 after pray")
	assert_eq(int(player["wallet"].get_gold()), 55, "e2e-006 expected final gold 55 after merchant purchase")
	assert_eq(int(player.get("visit_count", 0)), 3, "e2e-006 expected visit count to increment through chain")
	assert_eq(relic_manager.get_relic_count(), 1, "e2e-006 expected relic from ruined altar pray")
	assert_eq(run_inventory.potion_count("소형 치료 물약"), 1, "e2e-006 expected merchant purchase to yield one potion")


func test_e2e_007_event_chain_uses_visible_choices_for_real_resolution_paths() -> void:
	var event_manager = _event_manager({"rng": _SequenceRng.new([0.50])})
	if event_manager == null:
		return

	var player := _make_player({"hp": 100.0, "mp": 50.0, "gold": 80})
	var altar_choices: Array = event_manager.get_visible_choices("ruined_altar", _event_context("ruined_altar", player))
	var merchant_choices: Array = event_manager.get_visible_choices("ruin_merchant", _event_context("ruin_merchant", player))
	var ward_choices: Array = event_manager.get_visible_choices("sealed_ward", _event_context("sealed_ward", player))

	assert_true(_has_choice(altar_choices, "기도"), "e2e-007 expected pray choice")
	assert_true(_has_choice(merchant_choices, "구매"), "e2e-007 expected buy choice")
	assert_true(_has_choice(ward_choices, "치료"), "e2e-007 expected heal choice")


func test_e2e_008_event_chain_cumulative_state_matches_each_step_transition() -> void:
	var event_manager = _event_manager({"rng": _SequenceRng.new([0.50])})
	if event_manager == null:
		return

	var player := _make_player({"hp": 100.0, "mp": 50.0, "gold": 80})
	var altar_result: Dictionary = event_manager.resolve_choice("ruined_altar", "기도", _event_context("ruined_altar", player))
	_apply_event_result_to_player(player, altar_result)
	assert_true(abs(float(player.get("hp", 0.0)) - 85.0) < 0.001, "e2e-008 expected HP 85 after altar")
	assert_true(abs(float(player.get("mp", 0.0)) - 47.5) < 0.001, "e2e-008 expected MP 47.5 after altar")

	var merchant_result: Dictionary = event_manager.resolve_choice("ruin_merchant", "구매", _event_context("ruin_merchant", player))
	_apply_event_result_to_player(player, merchant_result)
	assert_eq(int(player["wallet"].get_gold()), 55, "e2e-008 expected gold 55 after merchant")

	var ward_result: Dictionary = event_manager.resolve_choice("sealed_ward", "치료", _event_context("sealed_ward", player))
	_apply_event_result_to_player(player, ward_result)
	assert_true(abs(float(player.get("hp", 0.0)) - 100.0) < 0.001, "e2e-008 expected HP capped at 100 after ward")


func _has_choice(choices: Array, choice_id: String) -> bool:
	for choice in choices:
		if String(choice.get("id", "")) == choice_id:
			return true
	return false
