extends "res://scripts/rpg/status/status_effect.gd"

const BASE_DURATION := 2


func _init(initial_remaining_turns := BASE_DURATION) -> void:
	super._init("slow", 1, initial_remaining_turns)


func apply(_new_effect) -> void:
	stacks = 1
	remaining_turns = BASE_DURATION
