extends "res://test/rpg/test_base.gd"

const HELPER_PATH := "res://test/rpg/map_test_helper.gd"


func test_map_007_floor1_has_one_or_two_normal_combats() -> void:
	var floor = _make_floor1()
	if floor == null:
		return
	var helper = _helper()
	var combat_count = helper.count_nodes_with_tier(floor.nodes, "combat", "normal")
	assert_true(combat_count >= 1 and combat_count <= 2, "map-007 floor 1 should have 1-2 normal combats")


func test_map_008_floor1_has_exactly_one_event() -> void:
	var floor = _make_floor1()
	if floor == null:
		return
	var helper = _helper()
	assert_eq(helper.count_nodes_of_type(floor.nodes, "event"), 1, "map-008 floor 1 should have exactly one event")


func test_map_009_floor1_has_zero_or_one_campfire() -> void:
	var floor = _make_floor1()
	if floor == null:
		return
	var helper = _helper()
	var campfire_count = helper.count_nodes_of_type(floor.nodes, "campfire")
	assert_true(campfire_count >= 0 and campfire_count <= 1, "map-009 floor 1 should have 0-1 campfires")


func test_map_010_floor1_has_no_boss() -> void:
	var floor = _make_floor1()
	if floor == null:
		return
	var helper = _helper()
	assert_eq(helper.count_nodes_of_type(floor.nodes, "boss"), 0, "map-010 floor 1 should not have a boss")


func _make_floor1():
	var helper = _helper()
	var script = helper.load_script(helper.FLOOR_PATH)
	assert_not_null(script, "expected floor.gd to exist")
	if script == null:
		return null
	return helper.make_floor(1)


func _helper():
	return load(HELPER_PATH).new()
