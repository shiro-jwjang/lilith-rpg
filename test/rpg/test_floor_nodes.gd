extends "res://test/rpg/test_base.gd"

const HELPER_PATH := "res://test/rpg/map_test_helper.gd"


func test_map_001_floor1_node_count_minimum() -> void:
	var floor = _make_floor(1)
	if floor == null:
		return
	assert_ge(floor.nodes.size(), 3, "map-001 floor 1 should have at least 3 nodes")


func test_map_002_floor1_node_count_maximum() -> void:
	var floor = _make_floor(1)
	if floor == null:
		return
	assert_true(floor.nodes.size() <= 4, "map-002 floor 1 should have at most 4 nodes")


func test_map_003_floor2_node_count_minimum() -> void:
	var floor = _make_floor(2)
	if floor == null:
		return
	assert_ge(floor.nodes.size(), 3, "map-003 floor 2 should have at least 3 nodes")


func test_map_004_floor2_node_count_maximum() -> void:
	var floor = _make_floor(2)
	if floor == null:
		return
	assert_true(floor.nodes.size() <= 4, "map-004 floor 2 should have at most 4 nodes")


func test_map_005_floor3_node_count_minimum() -> void:
	var floor = _make_floor(3)
	if floor == null:
		return
	assert_ge(floor.nodes.size(), 2, "map-005 floor 3 should have at least 2 nodes")


func test_map_006_floor3_node_count_maximum() -> void:
	var floor = _make_floor(3)
	if floor == null:
		return
	assert_true(floor.nodes.size() <= 3, "map-006 floor 3 should have at most 3 nodes")


func _make_floor(floor_number: int):
	var helper = _helper()
	var script = helper.load_script(helper.FLOOR_PATH)
	assert_not_null(script, "expected floor.gd to exist")
	if script == null:
		return null
	return helper.make_floor(floor_number)


func _helper():
	return load(HELPER_PATH).new()
