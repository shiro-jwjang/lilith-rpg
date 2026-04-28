extends "res://test/rpg/test_base.gd"

const STATUS_MANAGER_PATH := "res://scripts/rpg/status/status_manager.gd"
const EFFECT_CHANCE_CALCULATOR_PATH := "res://scripts/rpg/status/effect_chance_calculator.gd"


func test_status_024_boss_immune_tags_reject_matching_status_effect() -> void:
	var manager = _make_status_manager()
	if manager == null:
		return
	assert_true(manager.check_boss_immunity("bleed", ["bleed", "burn", "stun"]), "status-024 expected bleed tag immunity to reject effect")


func test_status_025_full_effect_resist_prevents_status_application() -> void:
	var chance = _calculate(1.0, 0.0, 1.0)
	assert_eq(chance, 0.0, "status-025 expected final chance 0.0")
	assert_false(chance > 0.0, "status-025 expected status application to be impossible")


func test_status_026_boss_without_matching_immune_tag_allows_normal_application_check() -> void:
	var manager = _make_status_manager()
	if manager == null:
		return
	var immune = manager.check_boss_immunity("bleed", ["stun"])
	var chance = _calculate(0.8, 0.0, 0.0)
	assert_false(immune, "status-026 expected bleed not to be blocked by unrelated immune tag")
	assert_eq(chance, 0.8, "status-026 expected normal application chance of 0.8")
	assert_true(chance > 0.0, "status-026 expected effect to remain applicable")


func _make_status_manager():
	var script = load(STATUS_MANAGER_PATH)
	assert_not_null(script, "expected status_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _calculate(base_chance: float, effect_hit: float, effect_resist: float) -> float:
	var script = load(EFFECT_CHANCE_CALCULATOR_PATH)
	assert_not_null(script, "expected effect_chance_calculator.gd to exist")
	if script == null:
		return -1.0
	return script.calculate_final_chance(base_chance, effect_hit, effect_resist)
