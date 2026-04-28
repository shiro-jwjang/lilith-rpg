extends RefCounted


static func calculate_final_chance(base_chance: float, effect_hit: float, effect_resist: float) -> float:
	return clampf(base_chance + effect_hit - effect_resist, 0.0, 1.0)
