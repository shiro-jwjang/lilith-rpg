extends Control

const GAME_RUNNER_SCRIPT = preload("res://scripts/rpg/game_runner.gd")
const TERMINAL_UI_SCRIPT = preload("res://scenes/terminal/terminal_ui.gd")

var runner = null
var terminal_ui = null


func _ready() -> void:
	runner = GAME_RUNNER_SCRIPT.new()
	terminal_ui = TERMINAL_UI_SCRIPT.new()
	terminal_ui.setup(runner)
	add_child(terminal_ui)
	runner.start_run()
