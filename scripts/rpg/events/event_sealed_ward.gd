extends "res://scripts/rpg/events/event_base.gd"


func _init(config: Dictionary = {}) -> void:
	var merged_config := {
		"event_id": "sealed_ward",
		"title": "봉인된 병실",
		"event_enemy_pool": ["ward_sentinel", "seal_horror"],
		"choices": [
			{"id": "치료"},
			{"id": "해방"},
			{"id": "약탈"},
			{"id": "봉인 해제", "hidden_condition": {"type": "battle_wins", "min": 3}},
		],
		"condition_checker": config.get("condition_checker", null),
		"rng": config.get("rng", null),
	}
	super._init(merged_config)


func _apply_choice(choice_id: String, result: Dictionary, _context: Dictionary) -> void:
	var player: Dictionary = result["player"]

	match choice_id:
		"치료":
			_increase_hp_percent_of_max(player, 0.30)
			_set_reward(result, "healing", 1)
		"해방":
			_clear_statuses(player)
			_add_player_gold(player, 25)
			_set_reward(result, "gold", 1)
		"약탈":
			if _randf() < 0.5:
				_set_reward(result, "equipment", 1)
			else:
				_trigger_combat(result)
		"봉인 해제":
			_set_reward(result, "relic_candidate", 1)
