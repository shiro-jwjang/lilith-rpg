extends RefCounted


func select_target(target_type: String, allies: Array, effect_type: String = ""):
	var taunter: Dictionary = {}
	for ally in allies:
		if int(ally.get("taunt_turns", 0)) > 0:
			taunter = ally
	if not taunter.is_empty():
		return taunter

	match target_type:
		"single":
			return _select_lowest_hp_ratio(allies)
		"aoe":
			return allies.duplicate(true)
		"status_effect":
			return _select_ally_without_status(allies, effect_type)
		_:
			return null


func _select_lowest_hp_ratio(allies: Array) -> Dictionary:
	var best_target: Dictionary = {}
	var best_ratio: float = INF
	for ally in allies:
		var max_hp: int = int(ally.get("max_hp", 0))
		if max_hp < 1:
			max_hp = 1
		var current_hp: int = int(ally.get("current_hp", 0))
		var ratio: float = float(current_hp) / float(max_hp)
		if ratio < best_ratio:
			best_ratio = ratio
			best_target = ally
	return best_target


func _select_ally_without_status(allies: Array, effect_type: String) -> Dictionary:
	for ally in allies:
		var statuses: Array = []
		var raw_statuses = ally.get("statuses", [])
		if raw_statuses is Array:
			statuses = raw_statuses
		if not statuses.has(effect_type):
			return ally
	return {}
