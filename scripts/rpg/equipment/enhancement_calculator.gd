extends RefCounted

const COSTS_PATH := "res://scripts/rpg/equipment/enhancement_costs.gd"


static func scale_stat(base_value: float, level: int) -> float:
	return base_value * (1.0 + (0.10 * float(level)))


static func get_cost(grade: String, target_level: int) -> int:
	var costs = load(COSTS_PATH)
	if costs == null:
		return -1
	return costs.get_cost(grade, target_level)


static func get_total_cost(grade: String, current_level: int, target_level: int) -> int:
	if target_level < current_level:
		return 0

	var total_cost := 0
	for level in range(current_level + 1, target_level + 1):
		var cost := get_cost(grade, level)
		if cost < 0:
			return -1
		total_cost += cost
	return total_cost
