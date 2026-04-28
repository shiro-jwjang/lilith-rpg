extends "res://test/rpg/test_base.gd"

const HELPER_PATH := "res://test/rpg/map_test_helper.gd"


func test_map_042_act_contains_exactly_three_floors() -> void:
	var helper = _helper()
	var script = helper.load_script(helper.GENERATOR_PATH)
	assert_not_null(script, "expected map_generator.gd to exist")
	if script == null:
		return
	var act = helper.generate_act()
	assert_eq(act.get("floors", []).size(), 3, "map-042 act should contain exactly three floors")


func _helper():
	return load(HELPER_PATH).new()
