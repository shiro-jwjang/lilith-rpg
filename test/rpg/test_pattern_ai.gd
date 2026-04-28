extends "res://test/rpg/test_base.gd"

const PATTERN_AI_PATH := "res://scripts/rpg/ai/pattern_ai.gd"


func test_combat_033_pattern_ai_selects_current_skill_and_advances_index() -> void:
	var ai = _make_pattern_ai()
	if ai == null:
		return
	var result = ai.select_skill(["skill_a", "skill_b", "skill_c"], 0)
	assert_eq(result.get("selected_skill", ""), "skill_a", "combat-033 expected skill_a at loop index 0")
	assert_eq(result.get("next_loop_index", -1), 1, "combat-033 expected next loop index 1")


func test_combat_034_pattern_ai_wraps_to_start_after_last_index() -> void:
	var ai = _make_pattern_ai()
	if ai == null:
		return
	var result = ai.select_skill(["skill_a", "skill_b"], 1)
	assert_eq(result.get("selected_skill", ""), "skill_b", "combat-034 expected skill_b at loop index 1")
	assert_eq(result.get("next_loop_index", -1), 0, "combat-034 expected wrapped loop index 0")


func _make_pattern_ai():
	var script = load(PATTERN_AI_PATH)
	assert_not_null(script, "expected pattern_ai.gd to exist")
	if script == null:
		return null
	return script.new()
