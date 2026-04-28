extends "res://scripts/rpg/events/event_base.gd"


func _init(config: Dictionary = {}) -> void:
	var merged_config := {
		"event_id": "moonlight_rift",
		"title": "달빛 균열",
		"event_enemy_pool": ["rift_spawn", "moonshade"],
		"choices": [
			{"id": "탐사"},
			{"id": "봉인"},
			{"id": "수용"},
			{"id": "균열 강화", "hidden_condition": {"type": "status_effects", "min": 2}},
		],
		"condition_checker": config.get("condition_checker", null),
		"rng": config.get("rng", null),
	}
	super._init(merged_config)


func _apply_choice(choice_id: String, result: Dictionary, _context: Dictionary) -> void:
	var player: Dictionary = result["player"]

	match choice_id:
		"탐사":
			if _randf() < 0.65:
				_set_reward(result, "relic_candidate", 1)
			else:
				_trigger_combat(result)
		"봉인":
			result["next_combat_modifier"]["enemy_speed"] = -2
			_set_reward(result, "seal", 1)
		"수용":
			_reduce_hp_percent(player, 0.10)
			_set_reward(result, "equipment", 1)
		"균열 강화":
			_clear_statuses(player)
			_set_reward(result, "relic_candidate", 1)
