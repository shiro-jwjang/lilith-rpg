extends "res://test/rpg/test_base.gd"

const EFFECT_CHANCE_CALCULATOR_PATH := "res://scripts/rpg/status/effect_chance_calculator.gd"


func test_status_017_effect_chance_uses_base_chance_when_no_modifiers() -> void:
	assert_eq(_calculate(0.8, 0.0, 0.0), 0.8, "status-017 expected final chance 0.8")


func test_status_018_effect_hit_bonus_clamps_result_to_one() -> void:
	assert_eq(_calculate(0.8, 0.25, 0.0), 1.0, "status-018 expected final chance to clamp at 1.0")


func test_status_019_effect_resist_can_reduce_final_chance_to_zero() -> void:
	assert_eq(_calculate(0.8, 0.0, 0.8), 0.0, "status-019 expected final chance 0.0")


func test_status_020_full_resist_grants_complete_immunity() -> void:
	assert_eq(_calculate(1.0, 0.0, 1.0), 0.0, "status-020 expected full resist to nullify chance")


func test_status_021_negative_result_clamps_to_zero() -> void:
	assert_eq(_calculate(0.3, 0.0, 0.8), 0.0, "status-021 expected negative chance to clamp at 0.0")


func test_status_022_overflow_result_clamps_to_one() -> void:
	assert_eq(_calculate(0.8, 0.5, 0.0), 1.0, "status-022 expected overflow chance to clamp at 1.0")


func test_status_023_effect_hit_and_resist_both_contribute_to_mixed_case() -> void:
	assert_eq(_calculate(0.75, 0.2, 0.1), 0.85, "status-023 expected mixed modifiers to yield 0.85")


func _calculate(base_chance: float, effect_hit: float, effect_resist: float) -> float:
	var script = load(EFFECT_CHANCE_CALCULATOR_PATH)
	assert_not_null(script, "expected effect_chance_calculator.gd to exist")
	if script == null:
		return -1.0
	return script.calculate_final_chance(base_chance, effect_hit, effect_resist)
