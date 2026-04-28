extends "res://scripts/rpg/events/event_base.gd"


func _init(config: Dictionary = {}) -> void:
	var merged_config := {
		"event_id": "ruin_merchant",
		"title": "폐허 상인",
		"event_enemy_pool": ["merchant_enforcer", "coin_mimic"],
		"choices": [
			{"id": "구매"},
			{"id": "강탈"},
			{"id": "특별 거래", "hidden_condition": {"type": "gold", "min": 100}},
		],
		"condition_checker": config.get("condition_checker", null),
		"rng": config.get("rng", null),
	}
	super._init(merged_config)


func _apply_choice(choice_id: String, result: Dictionary, _context: Dictionary) -> void:
	var player: Dictionary = result["player"]

	match choice_id:
		"구매":
			_spend_player_gold(player, 25)
			var roll := _randf()
			if roll < 0.34:
				_set_reward(result, "equipment", 1)
			elif roll < 0.67:
				_set_reward(result, "potion", 1)
			else:
				_set_reward(result, "upgrade_material", 1)
		"강탈":
			if _randf() < 0.6:
				_add_player_gold(player, 40)
				_set_reward(result, "gold_bonus", 1)
			else:
				_trigger_combat(result)
		"특별 거래":
			_spend_player_gold(player, 100)
			_set_reward(result, "high_equipment", 1)
