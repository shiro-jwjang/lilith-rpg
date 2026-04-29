extends "res://test/rpg/test_base.gd"

const MAP_VIEW_SCRIPT = preload("res://scenes/terminal/map_view.gd")


class _MockTextLog extends RefCounted:
	var texts: Array = []

	func append_text(text: String) -> void:
		texts.append(text)

	func clear_log() -> void:
		texts.clear()


class _MockChoicePanel extends RefCounted:
	var clears := 0
	var choices: Array = []

	func clear_choices() -> void:
		clears += 1
		choices.clear()

	func add_choice(label: String, method_name: String, args: Array) -> void:
		choices.append({"label": label, "method": method_name, "args": args.duplicate(true)})


class _MockRunner extends RefCounted:
	var party_status := [
		{"name": "리나", "current_hp": 72, "max_hp": 100},
		{"name": "카인", "current_hp": 55, "max_hp": 80},
	]

	func get_party_status() -> Array:
		return party_status.duplicate(true)


class _StateHolder extends RefCounted:
	var _current_state := "idle"
	var _last_map_floor := -1
	var _last_battle_type := ""
	var _battle_intro_shown := false


func test_render_map_state_outputs_floor_party_and_choices() -> void:
	var view = MAP_VIEW_SCRIPT.new()
	var text_log = _MockTextLog.new()
	var choice_panel = _MockChoicePanel.new()
	var state_holder = _StateHolder.new()
	view.setup(_MockRunner.new(), text_log, choice_panel, state_holder)

	view.render_map_state({
		"current_floor": 2,
		"available_nodes": [
			{"id": "n1", "type": "combat"},
			{"id": "n2", "type": "shop"},
		],
	})

	assert_eq(text_log.texts[0], "", "map view should start with a blank separator line")
	assert_eq(text_log.texts[1], "[color=yellow]═══ 2층 ═══[/color]", "map view should show the floor header")
	assert_eq(text_log.texts[2], "[color=gray]2층으로 올라왔다. 주변이 점점 어두워지며, 달빛이 비정상적으로 붉게 빛난다.[/color]", "map view should show the floor intro text")
	assert_eq(text_log.texts[3], "[color=gray]── 파티 ──[/color]", "map view should render the party narrative header")
	assert_eq(text_log.texts[4], "  리나 HP:72/100", "map view should render the first party member")
	assert_eq(text_log.texts[5], "  카인 HP:55/80", "map view should render the second party member")
	assert_eq(text_log.texts[7], "[color=cyan]앞에 2개의 길이 보입니다.[/color]", "map view should describe the node count")
	assert_eq(text_log.texts[8], "  [1] ⚔ 일반 전투", "map view should render the first node label")
	assert_eq(text_log.texts[9], "  [2] 🏪 상점", "map view should render the second node label")
	assert_eq(choice_panel.choices.size(), 2, "map view should create one choice per node")
	assert_eq(choice_panel.choices[0]["method"], "_on_node_selected", "map view node choices should call back through terminal_ui")
	assert_eq(choice_panel.choices[1]["args"][0], "n2", "map view should forward the selected node id")
	assert_eq(state_holder._current_state, "map", "map view should mark the shared state as map")
