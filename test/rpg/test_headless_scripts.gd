extends "res://test/rpg/test_base.gd"


func test_balance_test_script_loads() -> void:
	var script = load("res://headless/balance_test.gd")
	assert_not_null(script, "balance_test.gd should be loadable")


func test_regression_test_script_loads() -> void:
	var script = load("res://headless/regression_test.gd")
	assert_not_null(script, "regression_test.gd should be loadable")


func test_simulation_script_loads() -> void:
	var script = load("res://headless/simulation.gd")
	assert_not_null(script, "simulation.gd should be loadable")
