extends "res://test/rpg/test_base.gd"

const CONTENT_DATA_PATH := "res://scripts/rpg/data/content_data.gd"


func test_content_012_boss_stats_and_transition_threshold() -> void:
	var content = _make_content_data()
	if content == null:
		return
	var boss: Dictionary = content.get_boss()
	assert_eq(boss["name"], "붉은 달의 파수꾼", "content-012 expected boss name")
	assert_eq(boss["max_hp"], 450, "content-012 expected HP 450")
	assert_eq(boss["attack"], 22, "content-012 expected ATK 22")
	assert_eq(boss["defense"], 8, "content-012 expected DEF 8")
	assert_eq(boss["speed"], 10, "content-012 expected SPD 10")
	assert_eq(boss["phases"], 2, "content-012 expected 2 phases")
	assert_eq(boss["phase_transition_hp"], 225, "content-012 expected 50 percent transition at 225 HP")


func test_content_013_boss_transitions_at_half_hp_or_lower() -> void:
	var content = _make_content_data()
	if content == null:
		return
	assert_true(content.should_boss_transition_phase(225), "content-013 expected phase transition at 225 HP")
	assert_true(content.should_boss_transition_phase(200), "content-013 expected phase transition below 225 HP")
	assert_false(content.should_boss_transition_phase(226), "content-013 expected no transition above 225 HP")


func test_content_034_boss_phase_patterns_differ() -> void:
	var content = _make_content_data()
	if content == null:
		return
	var boss: Dictionary = content.get_boss()
	assert_ne(boss["phase_1_pattern"], boss["phase_2_pattern"], "content-034 expected different phase patterns")


func _make_content_data():
	var script: Script = load(CONTENT_DATA_PATH)
	assert_not_null(script, "expected content_data.gd to exist")
	if script == null:
		return null
	return script.new()
