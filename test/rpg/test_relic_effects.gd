extends "res://test/rpg/test_base.gd"

const RELIC_MANAGER_PATH := "res://scripts/rpg/relics/relic_manager.gd"


func test_relic_005_fragment_triggers_bonus_on_first_critical() -> void:
	var manager = _make_manager(["붉은 달의 파편"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"damage": 100,
		"critical_hit": true,
		"current_mp": 10,
	})
	assert_eq(result["damage"], 125, "relic-005 expected first critical damage to become 125")
	assert_eq(result["current_mp"], 15, "relic-005 expected MP bonus +5 on trigger")
	assert_eq(manager.get_relic_uses_remaining("붉은 달의 파편"), 0, "relic-005 expected one-time use to be consumed")


func test_relic_006_fragment_does_not_trigger_after_being_used() -> void:
	var manager = _make_manager(["붉은 달의 파편"])
	if manager == null:
		return
	manager.apply_effects({
		"damage": 100,
		"critical_hit": true,
		"current_mp": 10,
	})
	var result = manager.apply_effects({
		"damage": 100,
		"critical_hit": true,
		"current_mp": 10,
	})
	assert_eq(result["damage"], 100, "relic-006 expected second critical damage to stay 100")
	assert_eq(result["current_mp"], 10, "relic-006 expected no second MP bonus")


func test_relic_007_fragment_does_not_trigger_on_normal_hit() -> void:
	var manager = _make_manager(["붉은 달의 파편"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"damage": 100,
		"critical_hit": false,
		"current_mp": 5,
	})
	assert_eq(result["damage"], 100, "relic-007 expected normal hit damage to stay 100")
	assert_eq(result["current_mp"], 5, "relic-007 expected MP to remain unchanged")
	assert_eq(manager.get_relic_uses_remaining("붉은 달의 파편"), 1, "relic-007 expected first crit use to remain available")


func test_relic_008_fragment_applies_multiplier_after_defense() -> void:
	var manager = _make_manager(["붉은 달의 파편"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"damage": 50,
		"critical_hit": true,
		"current_mp": 0,
	})
	assert_eq(result["damage"], 62, "relic-008 expected post-defense final damage 50 to scale to 62")


func test_relic_009_rusty_shield_shard_grants_temporary_defense_after_defend() -> void:
	var manager = _make_manager(["녹슨 방패편"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"event": "defend",
		"defense": 10,
	})
	assert_eq(result["defense"], 13, "relic-009 expected defend action to grant DEF +3")
	assert_eq(result["temporary_defense_turns"], 2, "relic-009 expected temporary defense duration 2 turns")


func test_relic_010_rusty_shield_shard_has_no_penalty() -> void:
	var manager = _make_manager(["녹슨 방패편"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"event": "idle",
		"defense": 10,
	})
	assert_false(result.has("penalty"), "relic-010 expected no defined penalty")


func test_relic_011_hounds_fang_enhances_bleed_damage() -> void:
	var manager = _make_manager(["사냥개의 이빨"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"bleed_damage": 10.0,
		"max_hp": 100.0,
	})
	assert_true(is_equal_approx(result["bleed_damage"], 12.0), "relic-011 expected bleed damage 12.0")


func test_relic_012_hounds_fang_adds_one_bleed_stack() -> void:
	var manager = _make_manager(["사냥개의 이빨"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"bleed_stacks": 1,
	})
	assert_eq(result["bleed_stacks"], 2, "relic-012 expected bleed stacks +1")


func test_relic_013_ashen_echo_increases_burn_application_chance() -> void:
	var manager = _make_manager(["재의 잔향"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"burn_chance": 0.20,
	})
	assert_true(is_equal_approx(result["burn_chance"], 0.30), "relic-013 expected burn chance 0.30")


func test_relic_014_ashen_echo_has_no_penalty() -> void:
	var manager = _make_manager(["재의 잔향"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"burn_chance": 0.20,
	})
	assert_false(result.has("penalty"), "relic-014 expected no defined penalty")


func test_relic_015_rift_thread_increases_slow_and_shatter_chance() -> void:
	var manager = _make_manager(["균열의 실"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"slow_chance": 0.25,
		"shatter_chance": 0.15,
	})
	assert_true(is_equal_approx(result["slow_chance"], 0.35), "relic-015 expected slow chance 0.35")
	assert_true(is_equal_approx(result["shatter_chance"], 0.25), "relic-015 expected shatter chance 0.25")


func test_relic_016_rift_thread_adds_effect_hit_bonus() -> void:
	var manager = _make_manager(["균열의 실"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"effect_hit": 0.10,
	})
	assert_true(is_equal_approx(result["effect_hit"], 0.25), "relic-016 expected effect hit 0.25")


func test_relic_017_silent_bell_reduces_event_penalty() -> void:
	var manager = _make_manager(["고요한 종"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"event_penalty": 30.0,
	})
	assert_true(is_equal_approx(result["event_penalty"], 24.0), "relic-017 expected event penalty 24.0")


func test_relic_018_silent_bell_increases_healing_multiplicatively() -> void:
	var manager = _make_manager(["고요한 종"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"healing_amount": 40.0,
	})
	assert_true(is_equal_approx(result["healing_amount"], 44.0), "relic-018 expected healing amount 44.0")


func test_relic_019_silent_bell_has_no_gold_penalty() -> void:
	var manager = _make_manager(["고요한 종"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"gold_earned": 100,
	})
	assert_eq(result["gold_earned"], 100, "relic-019 expected earned gold to remain unchanged")


func test_relic_020_silent_bell_stacks_multiplicatively_with_other_healing_buffs() -> void:
	var manager = _make_manager(["고요한 종"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"healing_amount": 50.0,
		"healing_multiplier": 1.2,
	})
	assert_true(is_equal_approx(result["healing_amount"], 66.0), "relic-020 expected healing amount 66.0")


func _make_manager(relic_ids: Array = []):
	var script = load(RELIC_MANAGER_PATH)
	assert_not_null(script, "expected relic_manager.gd to exist")
	if script == null:
		return null
	return script.new({"relics": relic_ids})
