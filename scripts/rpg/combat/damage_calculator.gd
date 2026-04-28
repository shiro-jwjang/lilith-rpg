extends RefCounted


static func calculate_base_damage(attacker_atk, skill_coefficient, defender_def) -> int:
	var scaled_attack := int(floor(float(attacker_atk) * float(skill_coefficient)))
	return max(1, scaled_attack - int(defender_def))


static func apply_critical(base_damage, is_critical, crit_multiplier := 1.5) -> int:
	var damage := int(base_damage)
	if not is_critical:
		return damage
	if damage <= 1:
		return 1
	return max(1, int(floor(float(damage) * float(crit_multiplier))))


static func calculate_fixed_damage(amount) -> int:
	return int(amount)
