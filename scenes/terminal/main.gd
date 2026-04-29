extends Control

const TERMINAL_UI_SCRIPT = preload("res://scenes/terminal/terminal_ui.gd")

var runner = null
var terminal_ui = null


func _ready() -> void:
	var game_runner_autoload = get_node_or_null("/root/GameRunner")
	if game_runner_autoload != null:
		runner = game_runner_autoload.create_runner()
	else:
		const GAME_RUNNER_SCRIPT = preload("res://scripts/rpg/game_runner.gd")
		runner = GAME_RUNNER_SCRIPT.new()

	terminal_ui = TERMINAL_UI_SCRIPT.new()
	terminal_ui.setup(runner)
	add_child(terminal_ui)
	runner.start_run()
