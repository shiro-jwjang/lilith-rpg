extends RefCounted


static func apply_effect(equipment_name: String, level: int, context: Dictionary) -> Dictionary:
	var result := context.duplicate(true)
	result["active"] = level >= 3
	if level < 3:
		return result

	match equipment_name:
		"녹슨 검":
			var base_attack_coefficient := float(result.get("base_attack_coefficient", 1.0))
			result["attack_coefficient_bonus"] = 0.1
			result["attack_coefficient"] = base_attack_coefficient + 0.1
		"붉은 달 단도":
			if bool(result.get("critical_hit", false)):
				result["bleed_stacks"] = int(result.get("bleed_stacks", 0)) + 1
		"균열 완드":
			if bool(result.get("target_has_debuff", false)):
				result["damage_multiplier"] = float(result.get("damage_multiplier", 1.0)) * 1.1
		"견고한 흉갑":
			if not bool(result.get("effect_used", false)):
				result["incoming_damage"] = int(floor(float(result.get("incoming_damage", 0)) * 0.9))
				result["effect_used"] = true
		"사냥견 가죽갑":
			if int(result.get("turn_number", 0)) == 1:
				result["incoming_damage"] = int(floor(float(result.get("incoming_damage", 0)) * 0.95))
		"의식가 로브":
			if bool(result.get("skill_hit", false)):
				result["current_mp"] = int(result.get("current_mp", 0)) + 2
		"붉은 실 반지":
			result["bleed_chance"] = float(result.get("bleed_chance", 0.0)) + 0.05
		"달빛 부적":
			if int(result.get("turn_number", 0)) == 1:
				result["speed"] = int(result.get("speed", 0)) + 2
		"파편 목걸이":
			var current_hp := float(result.get("current_hp", 0.0))
			var max_hp := float(result.get("max_hp", 0.0))
			if max_hp > 0.0 and current_hp <= (max_hp * 0.5):
				result["incoming_damage"] = int(floor(float(result.get("incoming_damage", 0)) * 0.92))
		"봉인된 열쇠":
			var uses_remaining := int(result.get("uses_remaining", 0))
			if uses_remaining > 0 and int(result.get("locked_choices", 0)) > 0:
				result["locked_choices"] = max(0, int(result.get("locked_choices", 0)) - 1)
				result["uses_remaining"] = uses_remaining - 1
		"잠든 종":
			result["campfire_heal"] = float(result.get("campfire_heal", 0.0)) * 1.1
			result["event_penalty"] = float(result.get("event_penalty", 0.0)) * 0.8
		"재의 조각":
			result["burn_damage"] = float(result.get("burn_damage", 0.0)) * 1.15
			result["burn_chance"] = float(result.get("burn_chance", 0.0)) + 0.05

	return result
