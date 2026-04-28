extends RefCounted

const CONDITION_CHECKER_PATH := "res://scripts/rpg/events/event_condition_checker.gd"
const RUINED_ALTAR_PATH := "res://scripts/rpg/events/event_ruined_altar.gd"
const RUIN_MERCHANT_PATH := "res://scripts/rpg/events/event_ruin_merchant.gd"
const SEALED_WARD_PATH := "res://scripts/rpg/events/event_sealed_ward.gd"
const MOONLIGHT_RIFT_PATH := "res://scripts/rpg/events/event_moonlight_rift.gd"

var _events: Dictionary = {}
var _condition_checker = null
var _rng = null


func _init(config: Dictionary = {}) -> void:
	_rng = config.get("rng", null)
	var checker_script = load(CONDITION_CHECKER_PATH)
	if checker_script != null:
		_condition_checker = checker_script.new()
	_register_events()


func get_event(event_id: String):
	return _events.get(event_id, null)


func get_visible_choices(event_id: String, context: Dictionary) -> Array:
	var event = get_event(event_id)
	if event == null:
		return []
	return event.get_visible_choices(context)


func resolve_choice(event_id: String, choice_id: String, context: Dictionary) -> Dictionary:
	var event = get_event(event_id)
	if event == null:
		return {
			"event_id": event_id,
			"current_node": context.get("current_node", null),
			"player": (context.get("player", {}) as Dictionary).duplicate(true),
			"event_resolved": false,
			"next_state": "blocked",
			"next_node": null,
			"reward": {},
			"reward_count": 0,
			"combat_triggered": false,
			"combat": {},
			"next_combat_modifier": {},
		}
	return event.resolve_choice(choice_id, context)


func _register_events() -> void:
	_register_event(RUINED_ALTAR_PATH)
	_register_event(RUIN_MERCHANT_PATH)
	_register_event(SEALED_WARD_PATH)
	_register_event(MOONLIGHT_RIFT_PATH)


func _register_event(path: String) -> void:
	var script = load(path)
	if script == null:
		return
	var event = script.new({
		"condition_checker": _condition_checker,
		"rng": _rng,
	})
	_events[event.event_id] = event
