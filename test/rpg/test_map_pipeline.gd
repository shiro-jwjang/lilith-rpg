extends "res://test/rpg/test_base.gd"

const HELPER_PATH := "res://test/rpg/map_test_helper.gd"


func test_map_039_selecting_a_node_transitions_pipeline_to_node_entered() -> void:
	var setup = _make_pipeline_setup()
	if setup.is_empty():
		return
	var pipeline = setup["pipeline"]
	var floor = setup["manager"].get_current_floor()
	pipeline.select_node(floor.nodes[0].id)
	assert_eq(pipeline.state, "node_entered", "map-039 selecting a node should enter node state")
	assert_eq(pipeline.current_node_id, floor.nodes[0].id, "map-039 pipeline should track current node")


func test_map_040_completing_a_node_reflects_result_and_applies_rewards() -> void:
	var setup = _make_pipeline_setup()
	if setup.is_empty():
		return
	var pipeline = setup["pipeline"]
	var floor = setup["manager"].get_current_floor()
	pipeline.select_node(floor.nodes[0].id)
	pipeline.complete_node({"result": "victory", "rewards": [{"type": "gold", "amount": 10}]})
	assert_eq(pipeline.state, "result_reflected", "map-040 completing a node should reflect the result")
	assert_true(pipeline.rewards.size() > 0, "map-040 rewards should be applied to pipeline state")


func test_map_041_advancing_after_completion_prepares_the_next_floor() -> void:
	var setup = _make_pipeline_setup()
	if setup.is_empty():
		return
	var pipeline = setup["pipeline"]
	var floor = setup["manager"].get_current_floor()
	pipeline.select_node(floor.nodes[0].id)
	pipeline.complete_node({"result": "victory", "rewards": [{"type": "gold", "amount": 10}]})
	pipeline.advance()
	assert_eq(pipeline.state, "next_floor_ready", "map-041 advance should prepare the next floor")
	assert_eq(pipeline.displayed_floor, 2, "map-041 advance should show floor 2")


func _make_pipeline_setup() -> Dictionary:
	var helper = _helper()
	var manager_script = helper.load_script(helper.MANAGER_PATH)
	var pipeline_script = helper.load_script(helper.PIPELINE_PATH)
	assert_not_null(manager_script, "expected map_manager.gd to exist")
	assert_not_null(pipeline_script, "expected map_pipeline.gd to exist")
	if manager_script == null or pipeline_script == null:
		return {}
	var act = helper.generate_act()
	var manager = helper.make_manager(act)
	return {
		"manager": manager,
		"pipeline": helper.make_pipeline(manager),
	}


func _helper():
	return load(HELPER_PATH).new()
