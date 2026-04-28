extends "res://test/rpg/test_base.gd"

const HELPER_PATH := "res://test/rpg/map_test_helper.gd"


func test_map_011_floor2_has_exactly_one_normal_combat() -> void:
	var floor = _make_floor2()
	if floor == null:
		return
	var helper = _helper()
	assert_eq(helper.count_nodes_with_tier(floor.nodes, "combat", "normal"), 1, "map-011 floor 2 should have exactly one normal combat")


func test_map_012_floor2_has_exactly_one_elite_combat() -> void:
	var floor = _make_floor2()
	if floor == null:
		return
	var helper = _helper()
	assert_eq(helper.count_nodes_with_tier(floor.nodes, "combat", "elite"), 1, "map-012 floor 2 should have exactly one elite combat")


func test_map_013_floor2_has_exactly_one_event() -> void:
	var floor = _make_floor2()
	if floor == null:
		return
	var helper = _helper()
	assert_eq(helper.count_nodes_of_type(floor.nodes, "event"), 1, "map-013 floor 2 should have exactly one event")


func test_map_014_floor2_has_zero_or_one_treasure() -> void:
	var floor = _make_floor2()
	if floor == null:
		return
	var helper = _helper()
	var treasure_count = helper.count_nodes_of_type(floor.nodes, "treasure")
	assert_true(treasure_count >= 0 and treasure_count <= 1, "map-014 floor 2 should have 0-1 treasure nodes")


func test_map_015_floor2_has_zero_or_one_shop() -> void:
	var floor = _make_floor2()
	if floor == null:
		return
	var helper = _helper()
	var shop_count = helper.count_nodes_of_type(floor.nodes, "shop")
	assert_true(shop_count >= 0 and shop_count <= 1, "map-015 floor 2 should have 0-1 shop nodes")


func test_map_016_floor2_has_no_boss() -> void:
	var floor = _make_floor2()
	if floor == null:
		return
	var helper = _helper()
	assert_eq(helper.count_nodes_of_type(floor.nodes, "boss"), 0, "map-016 floor 2 should not have a boss")


func _make_floor2():
	var helper = _helper()
	var script = helper.load_script(helper.FLOOR_PATH)
	assert_not_null(script, "expected floor.gd to exist")
	if script == null:
		return null
	return helper.make_floor(2)


func _helper():
	return load(HELPER_PATH).new()
