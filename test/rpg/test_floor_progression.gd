extends "res://test/rpg/test_base.gd"

const HELPER_PATH := "res://test/rpg/map_test_helper.gd"


func test_map_035_progression_from_floor1_to_floor2_is_allowed() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	assert_true(manager.can_advance_to_floor(2), "map-035 floor 1 should be able to advance to floor 2")


func test_map_036_going_back_from_floor2_to_floor1_is_rejected() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	manager.set_current_floor(2)
	assert_false(manager.can_go_to_floor(1), "map-036 should not allow returning from floor 2 to floor 1")


func test_map_037_going_back_from_floor3_to_floor2_is_rejected() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	manager.set_current_floor(3)
	assert_false(manager.can_go_to_floor(2), "map-037 should not allow returning from floor 3 to floor 2")


func test_map_038_going_back_from_floor3_to_floor1_is_rejected() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	manager.set_current_floor(3)
	assert_false(manager.can_go_to_floor(1), "map-038 should not allow returning from floor 3 to floor 1")


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
