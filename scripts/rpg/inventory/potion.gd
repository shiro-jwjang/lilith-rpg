extends RefCounted

var name: String = ""
var cost: int = 0
var effect_type: String = ""
var value = 0


func _init(potion_name: String = "", potion_cost: int = 0, potion_effect_type: String = "", potion_value = 0) -> void:
	name = potion_name
	cost = int(potion_cost)
	effect_type = potion_effect_type
	value = potion_value
