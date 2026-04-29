extends Control

const BuildVersion = preload("res://scripts/rpg/version.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansKR.tres")
const TextLogScript = preload("res://scenes/terminal/components/text_log.gd")
const ChoicePanelScript = preload("res://scenes/terminal/components/choice_panel.gd")
const MapViewScript = preload("res://scenes/terminal/map_view.gd")
const BattleViewScript = preload("res://scenes/terminal/battle_view.gd")

var text_log: RichTextLabel = null
var choice_container: VBoxContainer = null
var status_label: RichTextLabel = null
var copy_log_button: Button = null
var version_label: Label = null
var text_log_component = null
var choice_panel = null
var map_view = null
var battle_view = null

var runner = null
var _current_state: String = "idle"
var _last_battle_type: String = ""
var _battle_intro_shown: bool = false
var _last_map_floor: int = -1
var _last_battle_intro_hash: int = 0
var _suppress_next_input_request: bool = false


func _ready() -> void:
	_setup_ui()
	_setup_views()
	_connect_runner()


func setup(game_runner) -> void:
	runner = game_runner
	if is_inside_tree():
		_setup_views()
		_connect_runner()


func _setup_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var font: FontFile = UI_FONT
	var font_size := 18

	status_label = RichTextLabel.new()
	status_label.anchor_right = 1.0
	status_label.anchor_bottom = 0.08
	status_label.bbcode_enabled = true
	status_label.scroll_active = false
	status_label.fit_content = true
	status_label.add_theme_font_override("normal_font", _create_font_with_emoji_fallback(font))
	status_label.add_theme_font_size_override("normal_font_size", font_size)
	add_child(status_label)

	text_log_component = TextLogScript.new()
	add_child(text_log_component)
	text_log = text_log_component._rich_text
	copy_log_button = text_log_component._copy_button

	var scroll := ScrollContainer.new()
	scroll.anchor_top = 0.78
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	add_child(scroll)

	choice_panel = ChoicePanelScript.new()
	choice_panel.anchor_right = 1.0
	choice_panel.anchor_bottom = 1.0
	choice_panel.setup(self)
	scroll.add_child(choice_panel)
	choice_container = choice_panel

	version_label = Label.new()
	version_label.anchor_left = 1.0
	version_label.anchor_top = 1.0
	version_label.anchor_right = 1.0
	version_label.anchor_bottom = 1.0
	version_label.offset_left = -160.0
	version_label.offset_top = -26.0
	version_label.offset_right = -12.0
	version_label.offset_bottom = -8.0
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	version_label.text = "v%s" % BuildVersion.VERSION
	version_label.add_theme_font_override("font", font)
	version_label.add_theme_font_size_override("font_size", 12)
	version_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.8))
	add_child(version_label)


func _create_font_with_emoji_fallback(font: Font) -> FontVariation:
	var fallback_font := SystemFont.new()
	fallback_font.font_names = [
		"Noto Color Emoji",
		"Apple Color Emoji",
		"Segoe UI Emoji",
		"Noto Sans Symbols 2",
	]

	var font_with_fallback := FontVariation.new()
	font_with_fallback.base_font = font
	font_with_fallback.fallbacks = [fallback_font]
	return font_with_fallback


func _connect_runner() -> void:
	if runner == null:
		return
	var bus = get_node_or_null("/root/EventBus")
	if bus == null:
		if not runner.battle_state_changed.is_connected(_on_battle_state):
			runner.battle_state_changed.connect(_on_battle_state)
		if not runner.map_state_changed.is_connected(_on_map_state):
			runner.map_state_changed.connect(_on_map_state)
		if not runner.player_input_requested.is_connected(_on_input_requested):
			runner.player_input_requested.connect(_on_input_requested)
		if not runner.message_logged.is_connected(_on_message):
			runner.message_logged.connect(_on_message)
		if not runner.run_ended.is_connected(_on_run_ended):
			runner.run_ended.connect(_on_run_ended)
		return
	if not bus.battle_state_changed.is_connected(_on_battle_state):
		bus.battle_state_changed.connect(_on_battle_state)
	if not bus.map_state_changed.is_connected(_on_map_state):
		bus.map_state_changed.connect(_on_map_state)
	if not bus.player_input_requested.is_connected(_on_input_requested):
		bus.player_input_requested.connect(_on_input_requested)
	if not bus.message_logged.is_connected(_on_message):
		bus.message_logged.connect(_on_message)
	if not bus.run_ended.is_connected(_on_run_ended):
		bus.run_ended.connect(_on_run_ended)


func _on_message(text: String) -> void:
	append_text(text)


func _on_map_state(state: Dictionary) -> void:
	if map_view != null:
		map_view.render_map_state(state)


func _on_battle_state(state: Dictionary) -> void:
	if battle_view != null:
		battle_view.render_battle_state(state)


func _on_input_requested(choices: Array) -> void:
	if _suppress_next_input_request:
		_suppress_next_input_request = false
		return
	if _current_state == "combat":
		if battle_view != null:
			battle_view.render_input_choices(choices)
		return
	if map_view != null:
		map_view.render_input_choices(choices)
	elif battle_view != null:
		battle_view.render_input_choices(choices)


func _on_run_ended(result: Dictionary) -> void:
	_current_state = "ended"
	_clear_choices()
	if bool(result.get("victory", false)):
		append_text("")
		append_text("[color=gold][b]═══ 승리! ═══[/b][/color]")
		append_text("[color=gold]붉은 달의 파수꾼을 쓰러뜨렸다![/color]")
		append_text("[color=gold]달빛이 다시 옅어지며, 고대의 봉인이 풀렸다.[/color]")
	else:
		append_text("")
		append_text("[color=red][b]═══ 패배... ═══[/b][/color]")
		append_text("[color=red]어둠에 삼켜졌다...[/color]")
	var summary: Dictionary = runner.get_run_summary() if runner != null else {}
	append_text("")
	append_text("[color=gray]── 결과 ──[/color]")
	append_text("클리어 층: %d" % int(summary.get("floors_cleared", 0)))
	append_text("전투 승리: %d" % int(summary.get("combats_won", 0)))
	append_text("획득 골드: %d" % int(summary.get("gold_earned", 0)))
	_add_choice("다시 시작", "_on_restart", [])


func _on_node_selected(node_id: String) -> void:
	if map_view != null:
		map_view.handle_node_selected(node_id)


func _auto_advance_combat() -> void:
	if battle_view != null:
		battle_view.auto_advance_combat()


func _on_skill_selected(skill_index: int) -> void:
	if battle_view != null:
		battle_view.handle_skill_selected(skill_index)


func _process_follow_up(turn_result: Dictionary) -> void:
	if battle_view != null:
		battle_view.process_follow_up(turn_result)


func _on_event_choice_selected(choice_id: String, label: String) -> void:
	if map_view != null:
		map_view.handle_event_choice(choice_id, label)


func _show_shop(shop_data: Dictionary) -> void:
	if map_view != null:
		map_view.show_shop(shop_data)


func _on_shop_buy(item_index: int) -> void:
	if map_view != null:
		map_view.handle_shop_buy(item_index)


func _on_shop_leave() -> void:
	if map_view != null:
		map_view.handle_shop_leave()


func _show_campfire() -> void:
	if map_view != null:
		map_view.show_campfire()


func _on_campfire_rest() -> void:
	if map_view != null:
		map_view.handle_campfire_rest()


func _on_campfire_invest(stat_name: String) -> void:
	if map_view != null:
		map_view.handle_campfire_invest(stat_name)


func _on_campfire_leave() -> void:
	if map_view != null:
		map_view.handle_campfire_leave()


func _on_restart() -> void:
	if text_log_component != null:
		text_log_component.clear_log()
	append_text("[color=cyan][b]── 새로운 모험이 시작된다 ──[/b][/color]")
	append_text("")
	runner.start_run()


func append_text(text: String) -> void:
	if text_log_component != null:
		text_log_component.append_text(text)
		text_log = text_log_component._rich_text
		copy_log_button = text_log_component._copy_button


func _show_party_narrative(party_status: Array) -> void:
	if map_view != null:
		map_view.show_party_narrative(party_status)


func _update_party_status(allies: Array) -> void:
	if battle_view != null:
		battle_view.update_party_status(allies)


func _clear_choices() -> void:
	if choice_panel != null:
		choice_panel.clear_choices()
		choice_container = choice_panel


func _add_choice(text: String, method: String, args: Array) -> void:
	if choice_panel != null:
		choice_panel.add_choice(text, method, args)
		choice_container = choice_panel


func _node_display_name(node_type: String) -> String:
	if map_view != null:
		return map_view.node_display_name(node_type)
	return node_type


func _floor_intro_text(floor_num: int) -> String:
	if map_view != null:
		return map_view.floor_intro_text(floor_num)
	return ""


func _get_ally_name(target_internal_id: int) -> String:
	if battle_view != null:
		return battle_view.get_ally_name(target_internal_id)
	return "아군%d" % target_internal_id


func _setup_views() -> void:
	if map_view == null:
		map_view = MapViewScript.new()
	if battle_view == null:
		battle_view = BattleViewScript.new()
	map_view.setup(runner, text_log_component, choice_panel, self)
	battle_view.setup(runner, text_log_component, choice_panel, self)
