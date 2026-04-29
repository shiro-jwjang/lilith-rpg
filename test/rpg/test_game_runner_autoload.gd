extends "res://test/rpg/test_base.gd"


func test_game_runner_autoload_exists() -> void:
	var autoload = Engine.get_meta("_game_runner_autoload_instance", null)
	assert_not_null(autoload, "GameRunner autoload should be installed for SceneTree tests")
	if autoload == null:
		return
	assert_eq(String(autoload.name), "GameRunner", "autoload instance should be mounted as GameRunner")


func test_create_runner_returns_working_runner() -> void:
	var autoload = Engine.get_meta("_game_runner_autoload_instance", null)
	assert_not_null(autoload, "GameRunner autoload should exist for create_runner coverage")
	if autoload == null:
		return

	var runner = autoload.create_runner()
	assert_not_null(runner, "create_runner should return a GameRunner instance")
	if runner == null:
		return

	runner.start_run()
	assert_eq(int(runner.run_state.get("current_floor", 0)), 1, "created GameRunner should support start_run")


func test_get_runner_returns_same_instance() -> void:
	var autoload = Engine.get_meta("_game_runner_autoload_instance", null)
	assert_not_null(autoload, "GameRunner autoload should exist for get_runner coverage")
	if autoload == null:
		return

	var runner = autoload.create_runner()
	assert_eq(autoload.get_runner(), runner, "get_runner should return the last created runner")
