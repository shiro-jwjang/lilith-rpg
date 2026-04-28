extends "res://scripts/rpg/ai/enemy_ai.gd"

const WEIGHTS := {
	"basic_attack": 50,
	"status_effect": 30,
	"high_coefficient": 20,
}


func get_skill_weights() -> Dictionary:
	return WEIGHTS.duplicate(true)


func select_skill(skills: Array, secondary_input = null):
	for skill in skills:
		if str(skill.get("type", "")) == "basic_attack":
			continue
		if bool(skill.get("condition_met", true)):
			return skill

	var basic_attack = _find_skill_by_type(skills, "basic_attack")
	if not basic_attack.is_empty():
		return basic_attack

	return {}
func _find_skill_by_type(skills: Array, skill_type: String) -> Dictionary:
	for skill in skills:
		if str(skill.get("type", "")) == skill_type:
			return skill
	return {}
