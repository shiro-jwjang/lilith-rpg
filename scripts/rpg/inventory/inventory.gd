extends RefCounted

const POTION_REGISTRY_PATH := "res://scripts/rpg/inventory/potion_registry.gd"

const EQUIPMENT_MAX := 6
const RELIC_MAX := 4
const POTION_STACK_MAX := 5
const FOCUS_DURATION := 2
const FOCUS_DELTA := 0.10

var equipment: Array = []
var relics: Array = []
var potions: Dictionary = {}
var wallet: RefCounted = null

var _potion_registry


func _init(config: Dictionary = {}) -> void:
	equipment = config.get("equipment", []).duplicate(true)
	relics = config.get("relics", []).duplicate(true)
	potions = config.get("potions", {}).duplicate(true)
	wallet = config.get("wallet", null)

	var registry_script = load(POTION_REGISTRY_PATH)
	if registry_script != null:
		_potion_registry = registry_script.new()


func add_equipment(item) -> Dictionary:
	if equipment.size() >= EQUIPMENT_MAX:
		return {
			"success": false,
			"count": equipment.size(),
		}

	equipment.append(item)
	return {
		"success": true,
		"count": equipment.size(),
	}


func remove_equipment(item) -> Dictionary:
	var index = equipment.find(item)
	if index == -1:
		return {
			"success": false,
			"count": equipment.size(),
		}

	equipment.remove_at(index)
	return {
		"success": true,
		"count": equipment.size(),
	}


func add_relic(relic) -> Dictionary:
	if relics.size() >= RELIC_MAX:
		return {
			"success": false,
			"count": relics.size(),
		}

	relics.append(relic)
	return {
		"success": true,
		"count": relics.size(),
	}


func remove_relic(relic) -> Dictionary:
	var index = relics.find(relic)
	if index == -1:
		return {
			"success": false,
			"count": relics.size(),
		}

	relics.remove_at(index)
	return {
		"success": true,
		"count": relics.size(),
	}


func add_potion(potion_name: String, spend_from_wallet := false) -> Dictionary:
	var potion = _get_potion(potion_name)
	if potion == null:
		return {
			"success": false,
			"cost": 0,
			"gold_after": _get_current_gold(),
			"count": potions.get(potion_name, 0),
		}

	var current_count := int(potions.get(potion_name, 0))
	if current_count >= POTION_STACK_MAX:
		return {
			"success": false,
			"cost": potion.cost,
			"gold_after": _get_current_gold(),
			"count": current_count,
		}

	if spend_from_wallet and wallet != null and not bool(wallet.can_afford(potion.cost)):
		return {
			"success": false,
			"cost": potion.cost,
			"gold_after": int(wallet.get_gold()),
			"count": current_count,
		}

	if spend_from_wallet and wallet != null:
		wallet.spend(potion.cost)
	potions[potion_name] = current_count + 1

	return {
		"success": true,
		"cost": potion.cost,
		"gold_after": _get_current_gold(),
		"count": potions[potion_name],
	}


func use_potion(potion_name: String, target: Dictionary) -> Dictionary:
	var current_count := int(potions.get(potion_name, 0))
	if current_count <= 0:
		return {
			"success": false,
			"count": current_count,
		}

	var potion = _get_potion(potion_name)
	if potion == null:
		return {
			"success": false,
			"count": current_count,
		}

	match potion.effect_type:
		"heal_hp":
			return _use_healing_potion(potion_name, potion, target)
		"restore_mp":
			return _use_mana_potion(potion_name, potion, target)
		"purify":
			return _use_purification_potion(potion_name, potion, target)
		"battle_focus":
			return _use_focus_potion(potion_name, target)
		_:
			return {
				"success": false,
				"count": current_count,
			}


func tick_temporary_effects(target: Dictionary) -> void:
	var temporary_effects: Array = target.get("temporary_effects", [])
	var remaining_effects: Array = []

	for effect in temporary_effects:
		var next_effect: Dictionary = effect.duplicate(true)
		next_effect["remaining_turns"] = int(next_effect.get("remaining_turns", 0)) - 1
		if int(next_effect["remaining_turns"]) <= 0:
			target["crit_rate"] = _round_stat(float(target.get("crit_rate", 0.0)) - float(next_effect.get("crit_delta", 0.0)))
			target["effect_hit"] = _round_stat(float(target.get("effect_hit", 0.0)) - float(next_effect.get("effect_hit_delta", 0.0)))
		else:
			remaining_effects.append(next_effect)

	target["temporary_effects"] = remaining_effects


func reset_for_new_run() -> void:
	relics.clear()


func _get_current_gold() -> int:
	if wallet == null:
		return 0
	return int(wallet.get_gold())


func _use_healing_potion(potion_name: String, potion, target: Dictionary) -> Dictionary:
	var current_hp := int(target.get("current_hp", 0))
	var max_hp := int(target.get("max_hp", current_hp))
	var healed: int = min(int(potion.value), max(0, max_hp - current_hp))
	target["current_hp"] = current_hp + healed
	_consume_potion(potion_name)
	return {
		"success": true,
		"healed": healed,
		"count": potions.get(potion_name, 0),
	}


func _use_mana_potion(potion_name: String, potion, target: Dictionary) -> Dictionary:
	var current_mp := int(target.get("current_mp", 0))
	var max_mp := int(target.get("max_mp", current_mp))
	var restored: int = min(int(potion.value), max(0, max_mp - current_mp))
	target["current_mp"] = current_mp + restored
	_consume_potion(potion_name)
	return {
		"success": true,
		"restored": restored,
		"count": potions.get(potion_name, 0),
	}


func _use_purification_potion(potion_name: String, potion, target: Dictionary) -> Dictionary:
	var debuffs: Array = target.get("debuffs", [])
	if debuffs.is_empty():
		return {
			"success": false,
			"count": potions.get(potion_name, 0),
			"removed_debuff_count": 0,
		}

	debuffs.remove_at(0)
	target["debuffs"] = debuffs
	var current_hp := int(target.get("current_hp", 0))
	var max_hp := int(target.get("max_hp", current_hp))
	target["current_hp"] = min(max_hp, current_hp + int(potion.value))
	_consume_potion(potion_name)
	return {
		"success": true,
		"count": potions.get(potion_name, 0),
		"removed_debuff_count": 1,
	}


func _use_focus_potion(potion_name: String, target: Dictionary) -> Dictionary:
	target["crit_rate"] = _round_stat(float(target.get("crit_rate", 0.0)) + FOCUS_DELTA)
	target["effect_hit"] = _round_stat(float(target.get("effect_hit", 0.0)) + FOCUS_DELTA)

	var temporary_effects: Array = target.get("temporary_effects", [])
	temporary_effects.append({
		"type": "battle_focus",
		"remaining_turns": FOCUS_DURATION,
		"crit_delta": FOCUS_DELTA,
		"effect_hit_delta": FOCUS_DELTA,
	})
	target["temporary_effects"] = temporary_effects

	_consume_potion(potion_name)
	return {
		"success": true,
		"count": potions.get(potion_name, 0),
		"duration": FOCUS_DURATION,
	}


func _consume_potion(potion_name: String) -> void:
	var current_count := int(potions.get(potion_name, 0))
	potions[potion_name] = max(0, current_count - 1)


func _get_potion(potion_name: String):
	if _potion_registry == null:
		return null
	return _potion_registry.get_potion(potion_name)


func _round_stat(value: float) -> float:
	return snappedf(value, 0.0001)
