extends "res://test/rpg/test_base.gd"

const GAME_RUNNER_SCRIPT := preload("res://scripts/rpg/game_runner.gd")


func test_run_state_autoload_exists() -> void:
	var run_state = Engine.get_meta("_run_state_instance", null)
	assert_not_null(run_state, "RunState autoload should be installed for SceneTree tests")
	if run_state == null:
		return
	assert_eq(String(run_state.name), "RunState", "autoload instance should be mounted as RunState")


func test_run_state_start_new_run_initializes_defaults() -> void:
	var run_state = Engine.get_meta("_run_state_instance", null)
	assert_not_null(run_state, "RunState autoload should exist for reset coverage")
	if run_state == null:
		return

	run_state.victory = true
	run_state.defeat = true
	run_state.ended = true
	run_state.current_floor = 9
	run_state.floors_cleared = 2
	run_state.nodes_visited = ["node_a"]
	run_state.combats_won = 4
	run_state.gold_earned = 77
	run_state.current_node_id = "node_b"

	run_state.start_new_run()

	assert_eq(run_state.to_dict(), {
		"victory": false,
		"defeat": false,
		"ended": false,
		"current_floor": 1,
		"floors_cleared": 0,
		"nodes_visited": [],
		"combats_won": 0,
		"gold_earned": 0,
		"current_node_id": "",
	}, "start_new_run should restore the default run state shape")


func test_run_state_to_dict_matches_current_shape() -> void:
	var run_state = Engine.get_meta("_run_state_instance", null)
	assert_not_null(run_state, "RunState autoload should exist for serialization coverage")
	if run_state == null:
		return

	run_state.victory = true
	run_state.defeat = false
	run_state.ended = true
	run_state.current_floor = 2
	run_state.floors_cleared = 1
	run_state.nodes_visited = ["floor1_node1", "floor2_node3"]
	run_state.combats_won = 3
	run_state.gold_earned = 45
	run_state.current_node_id = "floor2_node3"

	var state_dict: Dictionary = run_state.to_dict()

	assert_eq(state_dict, {
		"victory": true,
		"defeat": false,
		"ended": true,
		"current_floor": 2,
		"floors_cleared": 1,
		"nodes_visited": ["floor1_node1", "floor2_node3"],
		"combats_won": 3,
		"gold_earned": 45,
		"current_node_id": "floor2_node3",
	}, "to_dict should match the GameRunner run_state schema")

	run_state.nodes_visited.append("mutated")
	assert_eq((state_dict.get("nodes_visited", []) as Array).size(), 2, "to_dict should duplicate nodes_visited")


func test_game_runner_start_run_syncs_current_floor_to_run_state() -> void:
	var run_state = Engine.get_meta("_run_state_instance", null)
	assert_not_null(run_state, "RunState autoload should exist for GameRunner sync coverage")
	if run_state == null:
		return

	run_state.reset()
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run()

	assert_eq(run_state.current_floor, int(runner.run_state.get("current_floor", -1)), "RunState should mirror GameRunner current_floor after start_run")
