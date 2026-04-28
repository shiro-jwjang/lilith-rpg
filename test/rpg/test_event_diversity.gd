extends "res://test/rpg/test_base.gd"

const HELPER_PATH := "res://test/rpg/map_test_helper.gd"


func test_map_029_act_exposes_four_distinct_event_ids() -> void:
	var act = _generate_act()
	if act.is_empty():
		return
	var event_catalog: Array = act.get("event_catalog", [])
	assert_eq(event_catalog.size(), 4, "map-029 act should expose four distinct event ids")
	var seen := {}
	for event_id in event_catalog:
		seen[event_id] = true
	assert_eq(seen.size(), 4, "map-029 event catalog should not contain duplicates")


func test_map_030_event_nodes_do_not_repeat_same_event_on_consecutive_floors() -> void:
	var act = _generate_act()
	if act.is_empty():
		return
	var helper = _helper()
	var previous_ids := {}
	for floor in act.get("floors", []):
		var current_ids := {}
		for event_id in helper.event_ids_from_floor(floor):
			current_ids[event_id] = true
			assert_false(previous_ids.has(event_id), "map-030 consecutive floors should not repeat event id %s" % event_id)
		previous_ids = current_ids


func _generate_act() -> Dictionary:
	var helper = _helper()
	var script = helper.load_script(helper.GENERATOR_PATH)
	assert_not_null(script, "expected map_generator.gd to exist")
	if script == null:
		return {}
	return helper.generate_act()


func _helper():
	return load(HELPER_PATH).new()
