extends RefCounted


static func resolve_turn_order(units: Array) -> Array:
	var ordered := units.duplicate()
	ordered.sort_custom(_sort_units)
	return ordered


static func _sort_units(a, b) -> bool:
	if a.speed != b.speed:
		return a.speed > b.speed
	if a.is_ally != b.is_ally:
		return a.is_ally and not b.is_ally

	var a_ratio := _hp_ratio(a)
	var b_ratio := _hp_ratio(b)
	if a_ratio != b_ratio:
		return a_ratio < b_ratio
	return a.internal_id < b.internal_id


static func _hp_ratio(unit) -> float:
	if unit.max_hp <= 0:
		return 1.0
	return float(unit.current_hp) / float(unit.max_hp)
