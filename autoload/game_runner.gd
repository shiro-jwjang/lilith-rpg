extends Node

const GAME_RUNNER_IMPL := preload("res://scripts/rpg/game_runner.gd")

var current_run = null


func create_runner(config: Dictionary = {}) -> RefCounted:
	current_run = GAME_RUNNER_IMPL.new(config)
	return current_run


func get_runner() -> RefCounted:
	return current_run
