extends RefCounted

var type: String = ""
var stacks: int = 1
var remaining_turns: int = 0


func _init(effect_type := "", initial_stacks := 1, initial_remaining_turns := 0) -> void:
	type = String(effect_type)
	stacks = int(initial_stacks)
	remaining_turns = int(initial_remaining_turns)


func apply(_new_effect) -> void:
	pass


func on_tick(_unit = null) -> int:
	return 0


func on_expire() -> void:
	pass
