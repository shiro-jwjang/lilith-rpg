extends "res://test/rpg/test_base.gd"

const RELIC_MANAGER_PATH := "res://scripts/rpg/relics/relic_manager.gd"


func test_relic_021_run_end_clears_all_relics() -> void:
	var manager = _make_manager(["사냥개의 이빨", "균열의 실"])
	if manager == null:
		return
	manager.on_run_end()
	assert_eq(manager.get_relic_count(), 0, "relic-021 expected relic inventory to clear on run end")
	assert_false(manager.has_relic("사냥개의 이빨"), "relic-021 expected relics to not persist to next run")


func test_relic_022_multiple_relic_effects_apply_simultaneously() -> void:
	var manager = _make_manager(["사냥개의 이빨", "균열의 실"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"bleed_damage": 10.0,
		"max_hp": 100.0,
		"shatter_chance": 0.15,
	})
	assert_true(is_equal_approx(result["bleed_damage"], 12.0), "relic-022 expected bleed damage 12.0")
	assert_true(is_equal_approx(result["shatter_chance"], 0.25), "relic-022 expected shatter chance 0.25")


func test_relic_023_silent_bell_applies_healing_and_penalty_reduction_together() -> void:
	var manager = _make_manager(["고요한 종"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"healing_amount": 50.0,
		"event_penalty": 50.0,
	})
	assert_true(is_equal_approx(result["healing_amount"], 55.0), "relic-023 expected healing amount 55.0")
	assert_true(is_equal_approx(result["event_penalty"], 40.0), "relic-023 expected event penalty 40.0")


func test_relic_024_fragment_bonus_scales_after_defense_reduction() -> void:
	var manager = _make_manager(["붉은 달의 파편"])
	if manager == null:
		return
	var result = manager.apply_effects({
		"damage": 56,
		"critical_hit": true,
		"current_mp": 0,
	})
	assert_eq(result["damage"], 70, "relic-024 expected 56 post-defense damage to scale to 70")


func _make_manager(relic_ids: Array = []):
	var script = load(RELIC_MANAGER_PATH)
	assert_not_null(script, "expected relic_manager.gd to exist")
	if script == null:
		return null
	return script.new({"relics": relic_ids})
