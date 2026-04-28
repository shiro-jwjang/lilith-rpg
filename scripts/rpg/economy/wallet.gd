extends RefCounted

var gold: int = 0


func _init(config: Dictionary = {}) -> void:
	gold = int(config.get("gold", 0))


func add_gold(amount: int) -> void:
	if amount > 0:
		gold += amount


func spend(amount: int) -> bool:
	if amount < 0:
		return false
	if gold < amount:
		return false
	gold -= amount
	return true


func can_afford(amount: int) -> bool:
	return gold >= amount


func get_gold() -> int:
	return gold
