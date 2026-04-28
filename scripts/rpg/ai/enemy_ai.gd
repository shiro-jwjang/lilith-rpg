extends RefCounted

const TARGET_SELECTOR_SCRIPT := preload("res://scripts/rpg/ai/target_selector.gd")

var _target_selector = null


func _init() -> void:
	_target_selector = TARGET_SELECTOR_SCRIPT.new()


func select_skill(primary_input, secondary_input = null):
	return null


func select_target(target_type: String, allies: Array, effect_type: String = ""):
	return _target_selector.select_target(target_type, allies, effect_type)
