extends "res://test/rpg/test_base.gd"

const MAP_GENERATOR_PATH := "res://scripts/rpg/map/map_generator.gd"
const MAP_MANAGER_PATH := "res://scripts/rpg/map/map_manager.gd"
const MAP_PIPELINE_PATH := "res://scripts/rpg/map/map_pipeline.gd"


func test_integ_004_generated_act_contains_three_floors_and_required_node_types() -> void:
	var act := _generate_act()
	if act.is_empty():
		return

	var combat_count := 0
	var campfire_count := 0
	for floor in act.get("floors", []):
		for node in floor.nodes:
			if node.type == "combat":
				combat_count += 1
			elif node.type == "campfire":
				campfire_count += 1

	assert_eq((act.get("floors", []) as Array).size(), 3, "integ-004 expected three floors in the act")
	assert_ge(combat_count, 1, "integ-004 expected at least one combat node")
	assert_ge(campfire_count, 1, "integ-004 expected at least one campfire node")


func test_integ_005_pipeline_select_complete_and_advance_updates_state_per_floor() -> void:
	var setup := _make_pipeline_setup()
	if setup.is_empty():
		return

	var manager = setup["manager"]
	var pipeline = setup["pipeline"]
	var floor_one = manager.get_current_floor()
	var selection: Dictionary = pipeline.select_node(floor_one.nodes[0].id)
	assert_true(bool(selection.get("ok", false)), "integ-005 expected floor 1 node selection to succeed")
	assert_eq(pipeline.state, "node_entered", "integ-005 expected node_entered after selection")

	pipeline.complete_node({"result": "victory", "rewards": [{"type": "gold", "amount": 10}]})
	assert_eq(pipeline.state, "result_reflected", "integ-005 expected result_reflected after completion")

	assert_true(pipeline.advance(), "integ-005 expected advance to floor 2")
	assert_eq(pipeline.state, "next_floor_ready", "integ-005 expected next_floor_ready after advance")
	assert_eq(manager.current_floor_number, 2, "integ-005 expected manager current floor 2")
	assert_eq(pipeline.displayed_floor, 2, "integ-005 expected pipeline displayed floor 2")


func test_integ_006_full_three_floor_playthrough_ends_on_floor_three() -> void:
	var setup := _make_pipeline_setup()
	if setup.is_empty():
		return

	var manager = setup["manager"]
	var pipeline = setup["pipeline"]
	for floor_number in [1, 2, 3]:
		var floor = manager.get_current_floor()
		assert_eq(floor.floor_number, floor_number, "integ-006 expected floor number to match progression")
		var selection: Dictionary = pipeline.select_node(floor.nodes[0].id)
		assert_true(bool(selection.get("ok", false)), "integ-006 expected node selection on floor %d" % floor_number)
		pipeline.complete_node({"result": "victory", "rewards": [{"type": "gold", "amount": floor_number * 10}]})
		if floor_number < 3:
			assert_true(pipeline.advance(), "integ-006 expected advance from floor %d" % floor_number)

	assert_eq(manager.current_floor_number, 3, "integ-006 expected final manager floor 3")
	assert_eq(pipeline.displayed_floor, 3, "integ-006 expected final displayed floor 3")
	assert_false(pipeline.advance(), "integ-006 expected no advance beyond floor 3")


func _generate_act() -> Dictionary:
	var script = load(MAP_GENERATOR_PATH)
	assert_not_null(script, "expected map_generator.gd to exist")
	if script == null:
		return {}
	return script.new().generate_act()


func _make_pipeline_setup() -> Dictionary:
	var generator_script = load(MAP_GENERATOR_PATH)
	var manager_script = load(MAP_MANAGER_PATH)
	var pipeline_script = load(MAP_PIPELINE_PATH)
	assert_not_null(generator_script, "expected map_generator.gd to exist")
	assert_not_null(manager_script, "expected map_manager.gd to exist")
	assert_not_null(pipeline_script, "expected map_pipeline.gd to exist")
	if generator_script == null or manager_script == null or pipeline_script == null:
		return {}

	var act: Dictionary = generator_script.new().generate_act()
	var manager = manager_script.new(act)
	var pipeline = pipeline_script.new(manager)
	return {
		"manager": manager,
		"pipeline": pipeline,
	}
