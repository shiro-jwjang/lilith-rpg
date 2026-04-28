extends "res://scripts/rpg/status/status_effect.gd"

const DAMAGE_RATE := 0.05
const MAX_STACKS := 3
const BASE_DURATION := 3


func _init(initial_stacks := 1, initial_remaining_turns := BASE_DURATION) -> void:
	super._init("bleed", initial_stacks, initial_remaining_turns)


func apply(_new_effect) -> void:
	stacks = min(MAX_STACKS, stacks + 1)
	remaining_turns = BASE_DURATION


func on_tick(unit = null) -> int:
	if unit == null:
		return 0
	var damage := int(floor(float(unit.max_hp) * DAMAGE_RATE * float(stacks)))
	unit.take_damage(damage)
	return damage
