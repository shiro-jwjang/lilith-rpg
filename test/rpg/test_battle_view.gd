extends "res://test/rpg/test_base.gd"

const BATTLE_VIEW_SCRIPT = preload("res://scenes/terminal/battle_view.gd")


class _MockTextLog extends RefCounted:
	var texts: Array = []

	func append_text(text: String) -> void:
		texts.append(text)


class _MockChoicePanel extends RefCounted:
	var clears := 0
	var choices: Array = []

	func clear_choices() -> void:
		clears += 1
		choices.clear()

	func add_choice(label: String, method_name: String, args: Array) -> void:
		choices.append({"label": label, "method": method_name, "args": args.duplicate(true)})


class _MockStatusLabel extends RefCounted:
	var text := ""

	func clear() -> void:
		text = ""

	func append_text(value: String) -> void:
		text += value


class _MockRunner extends RefCounted:
	var _current_turn = {"name": "리나"}
	var party_status := [
		{"name": "리나", "current_hp": 64, "max_hp": 100, "current_mp": 12},
		{"name": "카인", "current_hp": 51, "max_hp": 80, "current_mp": 3},
	]

	func get_party_status() -> Array:
		return party_status.duplicate(true)


class _StateHolder extends RefCounted:
	var _current_state := "idle"
	var _last_battle_type := "boss"
	var _battle_intro_shown := false
	var _last_battle_intro_hash := 0
	var status_label = _MockStatusLabel.new()


func test_render_battle_state_outputs_intro_enemies_and_status() -> void:
	var view = BATTLE_VIEW_SCRIPT.new()
	var text_log = _MockTextLog.new()
	var choice_panel = _MockChoicePanel.new()
	var state_holder = _StateHolder.new()
	view.setup(_MockRunner.new(), text_log, choice_panel, state_holder)

	view.render_battle_state({
		"allies": [
			{"name": "리나", "internal_id": 1, "current_hp": 64, "max_hp": 100, "current_mp": 12},
			{"name": "카인", "internal_id": 2, "current_hp": 51, "max_hp": 80, "current_mp": 3},
		],
		"enemies": [
			{"name": "붉은 달의 파수꾼", "internal_id": 1, "current_hp": 120, "max_hp": 120, "alive": true},
		],
	})

	assert_eq(state_holder.status_label.text, "리나 HP:64/100 MP:12 │ 카인 HP:51/80 MP:3", "battle view should refresh the party status bar")
	assert_eq(text_log.texts[0], "", "battle view should start with a blank separator line")
	assert_eq(text_log.texts[1], "[color=red][b]═══ BOSS ═══[/b][/color]", "battle view should render the boss intro header")
	assert_eq(text_log.texts[2], "  [color=red]붉은 달의 파수꾼[/color] HP: 120/120", "battle view should list living enemies with HP")
	assert_eq(text_log.texts[3], "[color=red][color=red]붉은 달의 파수꾼[/color]이(가) 길을 막아섰다![/color]", "battle view should render the boss encounter line")
	assert_eq(state_holder._current_state, "combat", "battle view should mark the shared state as combat")


func test_render_input_choices_outputs_turn_prompt_and_skill_buttons() -> void:
	var view = BATTLE_VIEW_SCRIPT.new()
	var text_log = _MockTextLog.new()
	var choice_panel = _MockChoicePanel.new()
	var state_holder = _StateHolder.new()
	state_holder._current_state = "combat"
	view.setup(_MockRunner.new(), text_log, choice_panel, state_holder)

	view.render_input_choices([
		{"name": "베기", "mp_cost": 0},
		{"name": "달빛 참격", "mp_cost": 5},
	])

	assert_eq(text_log.texts[0], "", "battle input should separate the turn prompt with a blank line")
	assert_eq(text_log.texts[1], "[color=yellow]▶ 리나의 턴[/color]", "battle input should show the acting ally")
	assert_eq(text_log.texts[2], "[color=cyan]─ 행동 선택 ─[/color]", "battle input should show the combat choice header")
	assert_eq(text_log.texts[3], "  [1] 베기 (MP: 0)", "battle input should render the first skill")
	assert_eq(text_log.texts[4], "  [2] 달빛 참격 (MP: 5)", "battle input should render the second skill")
	assert_eq(choice_panel.choices.size(), 2, "battle input should create a choice per skill")
	assert_eq(choice_panel.choices[0]["method"], "_on_skill_selected", "battle skill choices should route through terminal_ui")
