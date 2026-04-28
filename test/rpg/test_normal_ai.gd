extends "res://test/rpg/test_base.gd"

const NORMAL_AI_PATH := "res://scripts/rpg/ai/normal_ai.gd"


func test_combat_030_normal_ai_uses_expected_weight_distribution() -> void:
	var ai = _make_normal_ai()
	if ai == null:
		return
	var weights = ai.get_skill_weights()
	assert_eq(weights.get("basic_attack", -1), 50, "combat-030 expected basic_attack weight 50")
	assert_eq(weights.get("status_effect", -1), 30, "combat-030 expected status_effect weight 30")
	assert_eq(weights.get("high_coefficient", -1), 20, "combat-030 expected high_coefficient weight 20")
	assert_eq(_sum_weights(weights), 100, "combat-030 expected total weight 100")


func test_combat_031_normal_ai_uses_next_candidate_when_first_condition_fails() -> void:
	var ai = _make_normal_ai()
	if ai == null:
		return
	var skills := [
		{"type": "high_coefficient", "condition_met": false},
		{"type": "status_effect", "condition_met": true},
		{"type": "basic_attack", "condition_met": true},
	]
	var selected = ai.select_skill(skills)
	assert_eq(selected.get("type", ""), "status_effect", "combat-031 expected status_effect after high_coefficient condition failed")


func test_combat_032_normal_ai_falls_back_to_basic_attack_when_all_conditions_fail() -> void:
	var ai = _make_normal_ai()
	if ai == null:
		return
	var skills := [
		{"type": "status_effect", "condition_met": false},
		{"type": "high_coefficient", "condition_met": false},
		{"type": "basic_attack", "condition_met": true},
	]
	var selected = ai.select_skill(skills)
	assert_eq(selected.get("type", ""), "basic_attack", "combat-032 expected basic_attack fallback when status_effect and high_coefficient fail")


func _make_normal_ai():
	var script = load(NORMAL_AI_PATH)
	assert_not_null(script, "expected normal_ai.gd to exist")
	if script == null:
		return null
	return script.new()


func _sum_weights(weights: Dictionary) -> int:
	var total := 0
	for key in weights:
		total += int(weights[key])
	return total
