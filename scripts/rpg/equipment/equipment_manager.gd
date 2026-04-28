extends RefCounted

const CALCULATOR_PATH := "res://scripts/rpg/equipment/enhancement_calculator.gd"

var wallet: RefCounted = null
var inventory: Array = []
var equipped: Dictionary = {}
var inventory_max: int = 6


func _init(config: Dictionary = {}) -> void:
	wallet = config["wallet"]
	inventory = config.get("inventory", []).duplicate()
	equipped = config.get("equipped", {}).duplicate()
	inventory_max = int(config.get("inventory_max", 6))


func get_inventory() -> Array:
	return inventory.duplicate()


func get_equipped() -> Dictionary:
	return equipped.duplicate()


func add_to_inventory(item) -> Dictionary:
	if inventory.size() >= inventory_max:
		return {
			"success": false,
			"inventory_size": inventory.size(),
		}

	inventory.append(item)
	return {
		"success": true,
		"inventory_size": inventory.size(),
	}


func equip_item(item) -> Dictionary:
	var slot_name = item.get_slot()
	var previous_item = equipped.get(slot_name, null)
	equipped[slot_name] = item

	if previous_item == null:
		return {
			"success": true,
			"old_in_inventory": false,
			"old_discarded": false,
		}

	if inventory.size() < inventory_max:
		inventory.append(previous_item)
		return {
			"success": true,
			"old_in_inventory": true,
			"old_discarded": false,
		}

	return {
		"success": true,
		"old_in_inventory": false,
		"old_discarded": true,
	}


func enhance_equipment(item) -> Dictionary:
	var current_level = item.get_upgrade_level()
	var target_level = current_level + 1
	if target_level > 3:
		return {
			"success": false,
			"error": "MAX_LEVEL",
			"gold_after": int(wallet.get_gold()),
			"cost": 0,
			"final_level": current_level,
		}

	var calculator = load(CALCULATOR_PATH)
	if calculator == null:
		return {
			"success": false,
			"error": "CALCULATOR_MISSING",
			"gold_after": int(wallet.get_gold()),
			"cost": 0,
			"final_level": current_level,
		}

	var cost = calculator.get_cost(item.get_grade(), target_level)
	if cost < 0:
		return {
			"success": false,
			"error": "INVALID_LEVEL",
			"gold_after": int(wallet.get_gold()),
			"cost": cost,
			"final_level": current_level,
		}

	if not bool(wallet.can_afford(cost)):
		return {
			"success": false,
			"error": "INSUFFICIENT_GOLD",
			"gold_after": int(wallet.get_gold()),
			"cost": cost,
			"final_level": current_level,
		}

	wallet.spend(cost)
	item.set_upgrade_level(target_level)
	return {
		"success": true,
		"cost": cost,
		"gold_after": int(wallet.get_gold()),
		"final_level": item.get_upgrade_level(),
	}


func enhance_to_level(item, target_level: int) -> Dictionary:
	var current_level = item.get_upgrade_level()
	if target_level > 3:
		return {
			"success": false,
			"error": "MAX_LEVEL",
			"gold_after": int(wallet.get_gold()),
			"total_cost": 0,
			"final_level": current_level,
		}

	var calculator = load(CALCULATOR_PATH)
	if calculator == null:
		return {
			"success": false,
			"error": "CALCULATOR_MISSING",
			"gold_after": int(wallet.get_gold()),
			"total_cost": 0,
			"final_level": current_level,
		}

	var total_cost = calculator.get_total_cost(item.get_grade(), current_level, target_level)
	if total_cost < 0:
		return {
			"success": false,
			"error": "INVALID_LEVEL",
			"gold_after": int(wallet.get_gold()),
			"total_cost": total_cost,
			"final_level": current_level,
		}

	if not bool(wallet.can_afford(total_cost)):
		return {
			"success": false,
			"error": "INSUFFICIENT_GOLD",
			"gold_after": int(wallet.get_gold()),
			"total_cost": total_cost,
			"final_level": current_level,
		}

	wallet.spend(total_cost)
	item.set_upgrade_level(target_level)
	return {
		"success": true,
		"total_cost": total_cost,
		"gold_after": int(wallet.get_gold()),
		"final_level": item.get_upgrade_level(),
	}
