extends "res://test/rpg/test_base.gd"

const EVENT_MANAGER_PATH := "res://scripts/rpg/events/event_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_event_022_moonlight_rift_explore_is_sixty_five_thirty_five() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var relic_count := 0
	var combat_count := 0
	var iterations := 10000
	for _index in range(iterations):
		var result: Dictionary = manager.resolve_choice("moonlight_rift", "탐사", _base_context())
		if bool(result.get("combat_triggered", false)):
			combat_count += 1
		elif String(result.get("reward", {}).get("type", "")) == "relic_candidate":
			relic_count += 1

	var relic_rate := float(relic_count) / float(iterations)
	var combat_rate := float(combat_count) / float(iterations)
	assert_true(abs(relic_rate - 0.65) <= 0.03, "event-022 expected relic branch within ±3%%")
	assert_true(abs(combat_rate - 0.35) <= 0.03, "event-022 expected combat branch within ±3%%")


func test_event_023_moonlight_rift_seal_applies_next_combat_speed_debuff() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var result: Dictionary = manager.resolve_choice("moonlight_rift", "봉인", _base_context())
	assert_eq(int(result.get("next_combat_modifier", {}).get("enemy_speed", 0)), -2, "event-023 expected next combat enemy speed debuff")


func test_event_024_moonlight_rift_acceptance_costs_hp_and_grants_equipment() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["player"]["hp"] = 100.0
	context["player"]["hp_max"] = 100.0
	var result: Dictionary = manager.resolve_choice("moonlight_rift", "수용", context)
	var player_after: Dictionary = result.get("player", {})
	assert_true(abs(float(player_after.get("hp", 0.0)) - 90.0) < 0.001, "event-024 expected hp to become 90")
	assert_eq(String(result.get("reward", {}).get("type", "")), "equipment", "event-024 expected equipment reward")
	assert_eq(int(result.get("reward_count", 0)), 1, "event-024 expected exactly one equipment reward")


func test_event_025_moonlight_rift_empower_stays_hidden_below_status_threshold() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["player"]["status_effects"] = ["poison"]
	var choices: Array = manager.get_visible_choices("moonlight_rift", context)
	assert_false(_has_choice(choices, "균열 강화"), "event-025 expected hidden choice to stay hidden")


func test_event_026_moonlight_rift_empower_unlocks_at_status_threshold() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["player"]["status_effects"] = ["poison", "weakness"]
	var choices: Array = manager.get_visible_choices("moonlight_rift", context)
	assert_true(_has_choice(choices, "균열 강화"), "event-026 expected hidden choice to unlock")


func test_event_027_moonlight_rift_empower_clears_statuses_and_grants_relic_candidate() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var context := _base_context()
	context["player"]["status_effects"] = ["poison", "weakness", "bleed"]
	var result: Dictionary = manager.resolve_choice("moonlight_rift", "균열 강화", context)
	assert_eq((result.get("player", {}).get("status_effects", []) as Array).size(), 0, "event-027 expected all statuses to be removed")
	assert_eq(String(result.get("reward", {}).get("type", "")), "relic_candidate", "event-027 expected relic candidate reward")


func _make_manager(config: Dictionary = {}):
	var script = load(EVENT_MANAGER_PATH)
	assert_not_null(script, "expected event_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _base_context() -> Dictionary:
	return {
		"current_node": {"id": "event_node_rift", "type": "event", "event_id": "moonlight_rift"},
		"player": {
			"hp_max": 100.0,
			"hp": 80.0,
			"mp_max": 50.0,
			"mp": 40.0,
			"wallet": _make_wallet(50),
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
