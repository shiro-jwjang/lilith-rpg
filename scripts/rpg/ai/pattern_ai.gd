extends "res://scripts/rpg/ai/enemy_ai.gd"


func select_skill(skill_loop: Array, current_loop_index = 0) -> Dictionary:
	if skill_loop.is_empty():
		return {
			"selected_skill": "",
			"next_loop_index": 0,
		}

	var loop_size := skill_loop.size()
	var index := posmod(int(current_loop_index), loop_size)
	return {
		"selected_skill": skill_loop[index],
		"next_loop_index": (index + 1) % loop_size,
	}
