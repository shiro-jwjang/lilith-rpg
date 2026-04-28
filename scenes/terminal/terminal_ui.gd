extends Control

var text_log: RichTextLabel = null
var choice_container: VBoxContainer = null
var status_label: RichTextLabel = null

var runner = null
var _current_state: String = "idle"


func _ready() -> void:
	_setup_ui()
	_connect_runner()


func setup(game_runner) -> void:
	runner = game_runner
	if is_inside_tree():
		_connect_runner()


func _setup_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	status_label = RichTextLabel.new()
	status_label.anchor_right = 1.0
	status_label.anchor_bottom = 0.08
	status_label.bbcode_enabled = true
	status_label.scroll_active = false
	status_label.fit_content = true
	add_child(status_label)

	text_log = RichTextLabel.new()
	text_log.anchor_top = 0.10
	text_log.anchor_right = 1.0
	text_log.anchor_bottom = 0.75
	text_log.bbcode_enabled = true
	text_log.scroll_following = true
	add_child(text_log)

	var scroll := ScrollContainer.new()
	scroll.anchor_top = 0.78
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	add_child(scroll)

	choice_container = VBoxContainer.new()
	choice_container.anchor_right = 1.0
	choice_container.anchor_bottom = 1.0
	scroll.add_child(choice_container)


func _connect_runner() -> void:
	if runner == null:
		return
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


func _on_message(text: String) -> void:
	append_text(text)


func _on_map_state(state: Dictionary) -> void:
	_current_state = "map"
	var floor_num: int = int(state.get("current_floor", 1))
	append_text("")
	append_text("[color=yellow]═══ %d층 ═══[/color]" % floor_num)

	var party_status: Array = runner.get_party_status() if runner != null else []
	_update_party_status(party_status)

	var nodes: Array = state.get("available_nodes", [])
	_clear_choices()
	for i in range(nodes.size()):
		var node = nodes[i]
		var node_type: String = String(node.type)
		var display_name := _node_display_name(node_type)
		append_text("  [%d] %s" % [i + 1, display_name])
		_add_choice("%d. %s" % [i + 1, display_name], "_on_node_selected", [String(node.id)])


func _on_battle_state(state: Dictionary) -> void:
	_current_state = "combat"
	var allies: Array = state.get("allies", [])
	var enemies: Array = state.get("enemies", [])

	append_text("")
	append_text("[color=red]═══ 전투 ═══[/color]")
	for enemy in enemies:
		var name: String = "적%d" % int(enemy.get("internal_id", 0))
		var hp: int = int(enemy.get("current_hp", 0))
		var max_hp: int = int(enemy.get("max_hp", 1))
		if bool(enemy.get("alive", true)):
			append_text("  [color=red]%s[/color] HP: %d/%d" % [name, hp, max_hp])
		else:
			append_text("  [color=gray]%s (처치)[/color]" % name)

	_update_party_status(allies)


func _on_input_requested(choices: Array) -> void:
	_clear_choices()
	if _current_state == "combat":
		append_text("")
		append_text("[color=cyan]─ 행동 선택 ─[/color]")
		for i in range(choices.size()):
			var skill: Dictionary = choices[i]
			var skill_name: String = String(skill.get("name", "스킬%d" % (i + 1)))
			var mp_cost: int = int(skill.get("mp_cost", 0))
			append_text("  [%d] %s (MP: %d)" % [i + 1, skill_name, mp_cost])
			_add_choice("%d. %s (MP:%d)" % [i + 1, skill_name, mp_cost], "_on_skill_selected", [i])
		return

	append_text("")
	append_text("[color=cyan]─ 선택지 ─[/color]")
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var choice_id: String = String(choice.get("id", "choice_%d" % i))
		var label: String = String(choice.get("text", choice_id))
		append_text("  [%d] %s" % [i + 1, label])
		_add_choice("%d. %s" % [i + 1, label], "_on_event_choice_selected", [choice_id, label])


func _on_run_ended(result: Dictionary) -> void:
	_current_state = "ended"
	_clear_choices()
	if bool(result.get("victory", false)):
		append_text("")
		append_text("[color=gold]승리![/color]")
	else:
		append_text("")
		append_text("[color=red]패배...[/color]")
	var summary: Dictionary = runner.get_run_summary() if runner != null else {}
	append_text("클리어 층: %d" % int(summary.get("floors_cleared", 0)))
	append_text("전투 승리: %d" % int(summary.get("combats_won", 0)))
	append_text("획득 골드: %d" % int(summary.get("gold_earned", 0)))
	_add_choice("다시 시작", "_on_restart", [])


func _on_node_selected(node_id: String) -> void:
	var result: Dictionary = runner.select_node(node_id)
	if not bool(result.get("ok", false)):
		append_text("[color=red]오류: %s[/color]" % String(result.get("error", "")))
		return

	var node: Dictionary = result.get("node", {})
	var node_type: String = String(node.get("type", ""))
	var enter_result: Dictionary = runner.enter_node()

	match node_type:
		"combat", "unique", "boss":
			append_text("")
			append_text("[color=red]전투 시작![/color]")
			_auto_advance_combat()
		"event":
			_current_state = "event"
			append_text("")
			append_text("[color=purple]이벤트 발생[/color]")
			var event_data: Dictionary = enter_result.get("data", {})
			var choices: Array = event_data.get("choices", [])
			_on_input_requested(choices)
		"shop":
			_show_shop(enter_result.get("data", {}))
		"campfire":
			_show_campfire()
		"treasure":
			var treasure_data: Dictionary = enter_result.get("data", {})
			append_text("[color=gold]보물 발견![/color]")
			var rewards: Dictionary = treasure_data.get("rewards", {})
			var gold: int = int(rewards.get("gold", 0))
			if gold > 0:
				append_text("골드 + %d" % gold)
			runner.complete_node()
			_show_map()


func _auto_advance_combat() -> void:
	while true:
		var turn_result: Dictionary = runner.next_turn()
		if turn_result.is_empty():
			return

		var battle_result = turn_result.get("battle_result", null)
		var unit = turn_result.get("unit", null)
		var auto_action = turn_result.get("auto_action", null)

		if battle_result != null:
			if battle_result == "victory":
				append_text("[color=green]전투 승리![/color]")
				var complete_result: Dictionary = runner.complete_node()
				var combat_data: Dictionary = complete_result.get("combat", {})
				var gold: int = int(combat_data.get("gold_earned", 0))
				if gold > 0:
					append_text("골드 + %d" % gold)
				if bool(runner.run_state.get("ended", false)):
					return
				_show_map()
			elif battle_result == "defeat":
				append_text("[color=red]전투 패배...[/color]")
			return

		if unit == null:
			return

		if auto_action != null:
			var target_id: int = int(auto_action.get("target_internal_id", 0))
			var damage: int = int(auto_action.get("damage", 0))
			append_text("  적이 아군%d에게 %d 데미지!" % [target_id, damage])
			continue

		if bool(turn_result.get("action_allowed", false)) and bool(unit.is_ally):
			return

		if not bool(turn_result.get("action_allowed", false)):
			append_text("  %s은 행동 불가" % ("아군" if bool(unit.is_ally) else "적"))


func _on_skill_selected(skill_index: int) -> void:
	var result: Dictionary = runner.player_attack(skill_index)
	if not bool(result.get("ok", false)):
		append_text("[color=red]%s[/color]" % String(result.get("error", "")))
		return

	var skill: Dictionary = result.get("skill", {})
	var damage: int = int(result.get("damage", 0))
	var target_hp: int = int(result.get("target_hp", 0))
	append_text("  %s 사용! %d 데미지! (적 HP: %d)" % [String(skill.get("name", "공격")), damage, target_hp])

	var follow_up: Dictionary = result.get("next_turn", {})
	_process_follow_up(follow_up)


func _process_follow_up(turn_result: Dictionary) -> void:
	while not turn_result.is_empty():
		var battle_result = turn_result.get("battle_result", null)
		var unit = turn_result.get("unit", null)
		var auto_action = turn_result.get("auto_action", null)

		if battle_result != null:
			if battle_result == "victory":
				append_text("[color=green]전투 승리![/color]")
				var complete_result: Dictionary = runner.complete_node()
				var combat_data: Dictionary = complete_result.get("combat", {})
				var gold: int = int(combat_data.get("gold_earned", 0))
				if gold > 0:
					append_text("골드 + %d" % gold)
				if bool(runner.run_state.get("ended", false)):
					return
				_show_map()
			elif battle_result == "defeat":
				append_text("[color=red]전투 패배...[/color]")
			return

		if unit == null:
			return

		if auto_action != null:
			var target_id: int = int(auto_action.get("target_internal_id", 0))
			var damage: int = int(auto_action.get("damage", 0))
			append_text("  적이 아군%d에게 %d 데미지!" % [target_id, damage])
			turn_result = runner.next_turn()
			continue

		if bool(turn_result.get("action_allowed", false)) and bool(unit.is_ally):
			return

		if not bool(turn_result.get("action_allowed", false)):
			append_text("  %s은 행동 불가" % ("아군" if bool(unit.is_ally) else "적"))
			turn_result = runner.next_turn()
			continue

		return


func _on_event_choice_selected(choice_id: String, label: String) -> void:
	append_text("  선택: %s" % label)
	var result: Dictionary = runner.resolve_event_choice(choice_id)
	if not bool(result.get("event_resolved", false)):
		append_text("[color=red]이벤트 처리 실패[/color]")
		return

	var reward: Dictionary = result.get("granted_rewards", {})
	var gold: int = int(reward.get("gold", 0))
	if gold > 0:
		append_text("[color=green]골드 + %d[/color]" % gold)

	if bool(result.get("combat_triggered", false)):
		append_text("[color=yellow]이 이벤트 결과는 전투를 예고합니다.[/color]")

	runner.complete_node()
	_show_map()


func _show_shop(shop_data: Dictionary) -> void:
	_current_state = "shop"
	_clear_choices()
	append_text("")
	append_text("[color=yellow]═══ 상점 ═══[/color]")
	append_text("소지 골드: %d" % int(shop_data.get("gold", 0)))
	var items: Array = shop_data.get("items", [])
	for i in range(items.size()):
		var item: Dictionary = items[i]
		var name: String = String(item.get("name", item.get("id", "")))
		var price: int = int(item.get("price", 0))
		var item_type: String = String(item.get("type", ""))
		append_text("  [%d] %s (%s) - %dG" % [i + 1, name, item_type, price])
		_add_choice("%d. %s (%dG)" % [i + 1, name, price], "_on_shop_buy", [i])
	_add_choice("0. 나가기", "_on_shop_leave", [])


func _on_shop_buy(item_index: int) -> void:
	var result: Dictionary = runner.shop_purchase(item_index)
	if bool(result.get("success", false)):
		append_text("[color=green]구매 완료![/color]")
		_show_shop(runner.enter_shop())
	else:
		append_text("[color=red]%s[/color]" % String(result.get("error", result.get("reason", "구매 실패"))))


func _on_shop_leave() -> void:
	runner.complete_node()
	_show_map()


func _show_campfire() -> void:
	_current_state = "campfire"
	_clear_choices()
	append_text("")
	append_text("[color=orange]═══ 모닥불 ═══[/color]")
	var party_status: Array = runner.get_party_status()
	if party_status.size() > 0:
		var leader: Dictionary = party_status[0]
		append_text("리나 HP: %d/%d" % [int(leader.get("current_hp", 0)), int(leader.get("max_hp", 0))])
	_add_choice("1. 휴식 (HP 회복)", "_on_campfire_rest", [])
	_add_choice("2. 투자 (ATK +1, 25G)", "_on_campfire_invest", ["atk"])
	_add_choice("3. 투자 (DEF +1, 25G)", "_on_campfire_invest", ["def"])
	_add_choice("0. 나가기", "_on_campfire_leave", [])


func _on_campfire_rest() -> void:
	var result: Dictionary = runner.campfire_rest()
	var healed: int = int(result.get("healed", 0))
	append_text("[color=green]HP %d 회복![/color]" % healed)
	runner.complete_node()
	_show_map()


func _on_campfire_invest(stat_name: String) -> void:
	var result: Dictionary = runner.campfire_invest(stat_name)
	if bool(result.get("success", false)):
		append_text("[color=green]%s +1![/color]" % stat_name.to_upper())
	else:
		append_text("[color=red]%s[/color]" % String(result.get("error", "골드 부족!")))
	_show_campfire()


func _on_campfire_leave() -> void:
	runner.complete_node()
	_show_map()


func _on_restart() -> void:
	runner.start_run()


func _show_map() -> void:
	_current_state = "map"
	if runner == null:
		return
	_on_map_state({
		"current_floor": int(runner.run_state.get("current_floor", 1)),
		"available_nodes": runner.get_available_nodes(),
	})


func append_text(text: String) -> void:
	if text_log != null:
		text_log.append_text(text + "\n")


func _update_party_status(allies: Array) -> void:
	if status_label == null:
		return
	status_label.clear()
	var text := "[color=white]═══ 파티 ═══[/color]  "
	for ally in allies:
		var name: String = String(ally.get("name", "아군%d" % int(ally.get("internal_id", 0))))
		var hp: int = int(ally.get("current_hp", 0))
		var max_hp: int = int(ally.get("max_hp", 1))
		var mp: int = int(ally.get("current_mp", 0))
		text += "%s HP:%d/%d MP:%d  " % [name, hp, max_hp, mp]
	status_label.append_text(text)


func _clear_choices() -> void:
	if choice_container == null:
		return
	for child in choice_container.get_children():
		child.queue_free()


func _add_choice(text: String, method: String, args: Array) -> void:
	if choice_container == null:
		return
	var button := Button.new()
	button.text = text
	button.pressed.connect(_make_choice_callback(method, args))
	choice_container.add_child(button)


func _make_choice_callback(method: String, args: Array) -> Callable:
	return func() -> void:
		callv(method, args)


func _node_display_name(node_type: String) -> String:
	match node_type:
		"combat":
			return "일반 전투"
		"elite":
			return "정예 전투"
		"boss":
			return "보스"
		"unique":
			return "고유 적"
		"event":
			return "이벤트"
		"shop":
			return "상점"
		"campfire":
			return "모닥불"
		"treasure":
			return "보물"
		_:
			return node_type
