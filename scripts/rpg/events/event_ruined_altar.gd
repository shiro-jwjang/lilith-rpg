extends "res://scripts/rpg/events/event_base.gd"


func _init(config: Dictionary = {}) -> void:
	var merged_config := {
		"event_id": "ruined_altar",
		"title": "무너진 제단",
		"event_enemy_pool": ["altar_wraith", "altar_guardian"],
		"choices": [
			{"id": "기도"},
			{"id": "봉헌"},
			{"id": "파괴"},
			{"id": "기원", "hidden_condition": {"type": "visit_count", "min": 3}},
		],
		"condition_checker": config.get("condition_checker", null),
		"rng": config.get("rng", null),
	}
	super._init(merged_config)


func _apply_choice(choice_id: String, result: Dictionary, _context: Dictionary) -> void:
	var player: Dictionary = result["player"]

	match choice_id:
		"기도":
			_reduce_hp_percent(player, 0.15)
			_reduce_mp_percent(player, 0.05)
			_offer_relic(result, false)
		"봉헌":
			_reduce_mp_percent(player, 0.10)
			_set_reward(result, "reward", 1, {"source": "altar_offering"})
		"파괴":
			if _randf() < 0.5:
				_offer_relic(result, false)
			else:
				_trigger_combat(result)
		"기원":
			_reduce_hp_percent(player, 0.30)
			_reduce_mp_percent(player, 0.15)
			_offer_relic(result, true)
