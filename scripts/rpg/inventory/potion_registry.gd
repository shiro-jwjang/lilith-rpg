extends RefCounted

const POTION_PATH := "res://scripts/rpg/inventory/potion.gd"

var _potions: Dictionary = {}


func _init() -> void:
	var potion_script = load(POTION_PATH)
	if potion_script == null:
		return

	_potions = {
		"소형 치료 물약": potion_script.new("소형 치료 물약", 15, "heal_hp", 35),
		"소형 마나 물약": potion_script.new("소형 마나 물약", 20, "restore_mp", 20),
		"정화 물약": potion_script.new("정화 물약", 20, "purify", 10),
		"전투 집중 물약": potion_script.new("전투 집중 물약", 25, "battle_focus", 0.10),
	}


func get_potion(potion_name: String):
	return _potions.get(potion_name, null)


func get_all_potions() -> Dictionary:
	return _potions.duplicate()
