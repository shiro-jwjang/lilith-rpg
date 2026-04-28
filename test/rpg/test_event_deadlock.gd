extends "res://test/rpg/test_base.gd"

const EVENT_MANAGER_PATH := "res://scripts/rpg/events/event_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_event_028_all_event_choices_produce_valid_next_state() -> void:
	var manager = _make_manager()
	if manager == null:
		return

	var event_contexts := {
		"ruined_altar": _altar_context(),
		"ruin_merchant": _merchant_context(),
		"sealed_ward": _ward_context(),
		"moonlight_rift": _rift_context(),
	}

	for event_id in event_contexts:
		var choices: Array = manager.get_visible_choices(event_id, event_contexts[event_id])
		assert_ge(choices.size(), 2, "event-028 expected visible choices for %s" % event_id)
		for choice in choices:
			var choice_id := String(choice.get("id", ""))
			var context: Dictionary = event_contexts[event_id].duplicate(true)
			var result: Dictionary = manager.resolve_choice(event_id, choice_id, context)
			assert_true(bool(result.get("event_resolved", false)), "event-028 expected %s/%s to resolve" % [event_id, choice_id])
			assert_ne(String(result.get("next_state", "blocked")), "blocked", "event-028 expected %s/%s not to dead-end" % [event_id, choice_id])
			assert_not_null(result.get("next_node", null), "event-028 expected %s/%s to assign next node" % [event_id, choice_id])


func _make_manager(config: Dictionary = {}):
	var script = load(EVENT_MANAGER_PATH)
	assert_not_null(script, "expected event_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _altar_context() -> Dictionary:
	return {
		"current_node": {"id": "event_node_altar_deadlock", "type": "event", "event_id": "ruined_altar"},
		"player": {
			"hp_max": 100.0,
			"hp": 100.0,
			"mp_max": 50.0,
			"mp": 50.0,
			"wallet": _make_wallet(80),
			"status_effects": [],
		},
		"visit_count": 3,
		"battle_wins": 0,
	}


func _merchant_context() -> Dictionary:
	return {
		"current_node": {"id": "event_node_merchant_deadlock", "type": "event", "event_id": "ruin_merchant"},
		"player": {
			"hp_max": 100.0,
			"hp": 100.0,
			"mp_max": 50.0,
			"mp": 50.0,
			"wallet": _make_wallet(150),
			"status_effects": [],
		},
		"visit_count": 0,
		"battle_wins": 0,
	}


func _ward_context() -> Dictionary:
	return {
		"current_node": {"id": "event_node_ward_deadlock", "type": "event", "event_id": "sealed_ward"},
		"player": {
			"hp_max": 100.0,
			"hp": 80.0,
			"mp_max": 50.0,
			"mp": 30.0,
			"wallet": _make_wallet(60),
			"status_effects": ["poison", "weakness"],
		},
		"visit_count": 0,
		"battle_wins": 3,
	}


func _rift_context() -> Dictionary:
	return {
		"current_node": {"id": "event_node_rift_deadlock", "type": "event", "event_id": "moonlight_rift"},
		"player": {
			"hp_max": 100.0,
			"hp": 80.0,
			"mp_max": 50.0,
			"mp": 40.0,
			"wallet": _make_wallet(50),
			"status_effects": ["poison", "weakness"],
		},
		"visit_count": 0,
		"battle_wins": 0,
	}


func _make_wallet(gold: int):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})
