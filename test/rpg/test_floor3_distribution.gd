extends "res://test/rpg/test_base.gd"

const HELPER_PATH := "res://test/rpg/map_test_helper.gd"


func test_map_017_floor3_has_exactly_one_boss() -> void:
	var floor = _make_floor3()
	if floor == null:
		return
	var helper = _helper()
	assert_eq(helper.count_nodes_of_type(floor.nodes, "boss"), 1, "map-017 floor 3 should have exactly one boss")


func test_map_018_floor3_has_zero_or_one_unique() -> void:
	var floor = _make_floor3()
	if floor == null:
		return
	var helper = _helper()
	var unique_count = helper.count_nodes_of_type(floor.nodes, "unique")
	assert_true(unique_count >= 0 and unique_count <= 1, "map-018 floor 3 should have 0-1 unique nodes")


func test_map_019_floor3_has_zero_or_one_normal_combat() -> void:
	var floor = _make_floor3()
	if floor == null:
		return
	var helper = _helper()
	var combat_count = helper.count_nodes_with_tier(floor.nodes, "combat", "normal")
	assert_true(combat_count >= 0 and combat_count <= 1, "map-019 floor 3 should have 0-1 normal combats")


func test_map_020_floor3_has_zero_or_one_event() -> void:
	var floor = _make_floor3()
	if floor == null:
		return
	var helper = _helper()
	var event_count = helper.count_nodes_of_type(floor.nodes, "event")
	assert_true(event_count >= 0 and event_count <= 1, "map-020 floor 3 should have 0-1 events")


func _make_floor3():
	var helper = _helper()
	var script = helper.load_script(helper.FLOOR_PATH)
	assert_not_null(script, "expected floor.gd to exist")
	if script == null:
		return null
	return helper.make_floor(3)


func _helper():
	return load(HELPER_PATH).new()
