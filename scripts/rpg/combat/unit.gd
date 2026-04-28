extends RefCounted

var name: String = ""
var current_hp: int = 0
var max_hp: int = 0
var current_mp: int = 0
var max_mp: int = 0
var atk: int = 0
var def: int = 0
var speed: int = 0
var internal_id: int = 0
var is_ally: bool = false
var alive: bool = true
var status_effects: Dictionary = {}


func _init(config: Dictionary = {}) -> void:
	name = String(config.get("name", ""))
	max_hp = int(config.get("max_hp", 0))
	current_hp = int(config.get("current_hp", max_hp))
	max_mp = int(config.get("max_mp", 0))
	current_mp = int(config.get("current_mp", max_mp))
	atk = int(config.get("atk", 0))
	def = int(config.get("def", 0))
	speed = int(config.get("speed", 0))
	internal_id = int(config.get("internal_id", 0))
	is_ally = bool(config.get("is_ally", false))
	status_effects = config.get("status_effects", {}).duplicate(true)
	current_hp = clamp(current_hp, 0, max_hp)
	current_mp = clamp(current_mp, 0, max_mp)
	alive = current_hp > 0


func take_damage(amount) -> void:
	current_hp = max(0, current_hp - int(amount))
	alive = current_hp > 0


func heal(amount) -> void:
	current_hp = min(max_hp, current_hp + int(amount))
	alive = current_hp > 0


func use_mp(cost) -> bool:
	var mp_cost := int(cost)
	if current_mp < mp_cost:
		return false
	current_mp -= mp_cost
	return true


func is_alive() -> bool:
	return alive
