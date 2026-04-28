extends "res://test/rpg/test_base.gd"

const HELPER_PATH := "res://test/rpg/map_test_helper.gd"


func test_map_033_player_can_select_exactly_one_node_per_floor() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var floor = manager.get_current_floor()
	var node = floor.nodes[0]
	var result: Dictionary = manager.select_node(node.id)
	assert_true(result.get("ok", false), "map-033 selecting one node should succeed")
	assert_eq(manager.get_selected_nodes_for_floor(1).size(), 1, "map-033 floor 1 should keep exactly one selected node")


func test_map_034_selecting_two_nodes_on_same_floor_is_rejected() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var floor = manager.get_current_floor()
	var first_result: Dictionary = manager.select_node(floor.nodes[0].id)
	var second_result: Dictionary = manager.select_node(floor.nodes[1].id)
	assert_true(first_result.get("ok", false), "map-034 first selection should succeed")
	assert_false(second_result.get("ok", true), "map-034 second selection on same floor should fail")
	assert_has(second_result, "error", "map-034 second selection should provide an error")


func _make_manager():
	var helper = _helper()
	var script = helper.load_script(helper.MANAGER_PATH)
	assert_not_null(script, "expected map_manager.gd to exist")
	if script == null:
		return null
	var act = helper.generate_act()
	return helper.make_manager(act)


func _helper():
	return load(HELPER_PATH).new()
