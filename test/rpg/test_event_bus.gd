extends "res://test/rpg/test_base.gd"

const GAME_RUNNER_SCRIPT := preload("res://scripts/rpg/game_runner.gd")
const FLOOR_SCRIPT := preload("res://scripts/rpg/map/floor.gd")
const NODE_SCRIPT := preload("res://scripts/rpg/map/node.gd")


class _SignalCapture extends RefCounted:
	var runner_map_states: Array = []
	var bus_map_states: Array = []
	var runner_input_choices: Array = []
	var bus_input_choices: Array = []

	func on_runner_map(state: Dictionary) -> void:
		runner_map_states.append(state.duplicate(true))

	func on_bus_map(state: Dictionary) -> void:
		bus_map_states.append(state.duplicate(true))

	func on_runner_input(choices: Array) -> void:
		runner_input_choices.append(choices.duplicate(true))

	func on_bus_input(choices: Array) -> void:
		bus_input_choices.append(choices.duplicate(true))


class _StubEventManager extends RefCounted:
	func get_event(event_id: String) -> RefCounted:
		var event_base = load("res://scripts/rpg/events/event_base.gd")
		return event_base.new({"event_id": event_id, "title": "이벤트 버스 테스트"})

	func get_visible_choices(_event_id: String, _context: Dictionary) -> Array:
		return [
			{"id": "choice_1", "text": "첫 번째 선택", "condition_met": true},
			{"id": "choice_2", "text": "두 번째 선택", "condition_met": true},
		]

	func resolve_choice(_event_id: String, _choice_id: String, _context: Dictionary) -> Dictionary:
		return {}


func test_event_bus_autoload_exists() -> void:
	var bus = Engine.get_meta("_event_bus_instance", null)
	assert_not_null(bus, "EventBus autoload should be installed for SceneTree tests")
	if bus == null:
		return
	assert_eq(String(bus.name), "EventBus", "autoload instance should be mounted as EventBus")
	assert_true(bus.has_signal("battle_state_changed"), "EventBus should expose battle_state_changed")
	assert_true(bus.has_signal("map_state_changed"), "EventBus should expose map_state_changed")
	assert_true(bus.has_signal("player_input_requested"), "EventBus should expose player_input_requested")
	assert_true(bus.has_signal("message_logged"), "EventBus should expose message_logged")
	assert_true(bus.has_signal("run_ended"), "EventBus should expose run_ended")


func test_game_runner_dual_emits_map_and_input_signals() -> void:
	var bus = Engine.get_meta("_event_bus_instance", null)
	assert_not_null(bus, "EventBus autoload should exist for signal routing")
	if bus == null:
		return

	var capture = _SignalCapture.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"event_manager": _StubEventManager.new(),
		"act": _act_with_single_event_node(),
	})

	runner.map_state_changed.connect(capture.on_runner_map)
	bus.map_state_changed.connect(capture.on_bus_map)
	runner.player_input_requested.connect(capture.on_runner_input)
	bus.player_input_requested.connect(capture.on_bus_input)

	runner.start_run({
		"event_manager": _StubEventManager.new(),
		"act": _act_with_single_event_node(),
	})
	runner.select_node("floor1_node1")
	var event_result: Dictionary = runner.enter_node()

	assert_eq(capture.runner_map_states.size(), 2, "runner should emit map_state_changed on start and select")
	assert_eq(capture.bus_map_states.size(), 2, "EventBus should mirror map_state_changed on start and select")
	assert_eq(capture.runner_map_states, capture.bus_map_states, "EventBus map payloads should match runner payloads")
	assert_eq(capture.runner_input_choices.size(), 1, "runner should emit player_input_requested on event entry")
	assert_eq(capture.bus_input_choices.size(), 1, "EventBus should mirror player_input_requested on event entry")
	assert_eq(capture.runner_input_choices, capture.bus_input_choices, "EventBus input payloads should match runner payloads")


func _act_with_single_event_node() -> Dictionary:
	var floors: Array = []
	for number in [1, 2, 3]:
		var floor = FLOOR_SCRIPT.new(number, {"skip_generation": true})
		floor.nodes = []
		if number == 1:
			floor.nodes.append(NODE_SCRIPT.new("event", number, 0, {
				"id": "floor1_node1",
				"event_id": "test_event",
			}))
		floors.append(floor)
	return {"floors": floors, "event_catalog": []}
