extends RefCounted

const INVEST_COST := 25

var _rng := RandomNumberGenerator.new()


func _init(config: Dictionary = {}) -> void:
	_rng.randomize()
	if config.has("seed"):
		_rng.seed = int(config.get("seed", 0))


func rest(player: Dictionary) -> Dictionary:
	var player_after: Dictionary = player.duplicate(true)
	var max_hp: int = int(player_after.get("max_hp", player_after.get("hp", 0)))
	var current_hp: int = int(player_after.get("hp", 0))
	var heal_amount: int = int(floor(float(max_hp) * 0.35))
	var hp_after: int = mini(current_hp + heal_amount, max_hp)
	player_after["hp"] = hp_after

	return {
		"player": player_after,
		"healed": hp_after - current_hp,
	}


func invest_stat(player: Dictionary, stat_name: String) -> Dictionary:
	var player_after: Dictionary = player.duplicate(true)
	var target_wallet = player_after["wallet"]
	var current_gold := int(target_wallet.get_gold())
	if not bool(target_wallet.can_afford(INVEST_COST)):
		return {
			"success": false,
			"player": player_after,
			"gold_after": current_gold,
		}

	target_wallet.spend(INVEST_COST)
	player_after[stat_name] = int(player_after.get(stat_name, 0)) + 1
	return {
		"success": true,
		"player": player_after,
		"gold_after": int(target_wallet.get_gold()),
	}


func roll_campfire_count(config: Dictionary = {}) -> int:
	if config.has("forced_count"):
		return clampi(int(config.get("forced_count", 1)), 1, 2)
	return _rng.randi_range(1, 2)
