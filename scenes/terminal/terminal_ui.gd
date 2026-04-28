extends Control

var text_log: RichTextLabel = null
var choice_container: VBoxContainer = null
var status_label: RichTextLabel = null

var runner = null
var _current_state: String = "idle"
var _last_battle_type: String = ""


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

	var font: FontFile = load("res://assets/fonts/NotoSansKR.tres")
	var font_size := 18

	status_label = RichTextLabel.new()
	status_label.anchor_right = 1.0
	status_label.anchor_bottom = 0.08
	status_label.bbcode_enabled = true
	status_label.scroll_active = false
	status_label.fit_content = true
	status_label.add_theme_font_override("normal_font", font)
	status_label.add_theme_font_size_override("normal_font_size", font_size)
	add_child(status_label)

	text_log = RichTextLabel.new()
	text_log.anchor_top = 0.10
	text_log.anchor_right = 1.0
	text_log.anchor_bottom = 0.75
	text_log.bbcode_enabled = true
	text_log.scroll_following = true
	text_log.add_theme_font_override("normal_font", font)
	text_log.add_theme_font_size_override("normal_font_size", font_size)
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
	append_text("[color=gray]%s[/color]" % _floor_intro_text(floor_num))

	var party_status: Array = runner.get_party_status() if runner != null else []
	_show_party_narrative(party_status)

	var nodes: Array = state.get("available_nodes", [])
	_clear_choices()
	append_text("")
	append_text("[color=cyan]앞에 %d개의 길이 보입니다.[/color]" % nodes.size())
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

	_update_party_status(allies)

	if _last_battle_type == "boss":
		append_text("")
		append_text("[color=red][b]═══ BOSS ═══[/b][/color]")
	elif _last_battle_type == "elite":
		append_text("")
		append_text("[color=orange]═══ 정예 전투 ═══[/color]")
	else:
		append_text("")
		append_text("[color=red]═══ 전투 ═══[/color]")

	# 적 소개
	var enemy_names: Array = []
	for enemy in enemies:
		var e_name: String = String(enemy.get("name", "적%d" % int(enemy.get("internal_id", 0))))
		var hp: int = int(enemy.get("current_hp", 0))
		var max_hp: int = int(enemy.get("max_hp", 1))
		if bool(enemy.get("alive", true)):
			enemy_names.append("[color=red]%s[/color]" % e_name)
			append_text("  [color=red]%s[/color] HP: %d/%d" % [e_name, hp, max_hp])
		else:
			append_text("  [color=gray]%s (처치)[/color]" % e_name)

	if enemy_names.size() > 0:
		var combined := ", ".join(enemy_names)
		if _last_battle_type == "boss":
			append_text("[color=red]%s이(가) 길을 막아섰다![/color]" % combined)
		elif enemy_names.size() == 1:
			append_text("[color=red]%s이(가) 나타났다![/color]" % combined)
		else:
			append_text("[color=red]%s이(가) 나타났다![/color]" % combined)


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
	var result: Dictionary = runner.select_node(node_id)
	if not bool(result.get("ok", false)):
		append_text("[color=red]오류: %s[/color]" % String(result.get("error", "")))
		return

	var node: Dictionary = result.get("node", {})
	var node_type: String = String(node.get("type", ""))
	var enter_result: Dictionary = runner.enter_node()

	match node_type:
		"combat", "unique", "boss":
			_last_battle_type = node_type
			append_text("")
			if node_type == "boss":
				append_text("[color=red][b]보스가 다가온다...[/b][/color]")
			elif node_type == "elite":
				append_text("[color=orange]강력한 기운이 느껴진다...[/color]")
			else:
				append_text("[color=red]적과 마주쳤다![/color]")
			_auto_advance_combat()
		"event":
			_current_state = "event"
			var event_data: Dictionary = enter_result.get("data", {})
			var event_title: String = String(event_data.get("title", "이벤트"))
			append_text("")
			append_text("[color=purple][b]── %s ──[/b][/color]" % event_title)
			var choices: Array = event_data.get("choices", [])
			_on_input_requested(choices)
		"shop":
			_show_shop(enter_result.get("data", {}))
		"campfire":
			_show_campfire()
		"treasure":
			var treasure_data: Dictionary = enter_result.get("data", {})
			append_text("[color=gold]보물 상자를 발견했다![/color]")
			var rewards: Dictionary = treasure_data.get("rewards", {})
			var gold: int = int(rewards.get("gold", 0))
			if gold > 0:
				append_text("[color=gold]골드 %d를 획득했다![/color]" % gold)
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
				if _last_battle_type == "boss":
					append_text("[color=gold]보스를 쓰러뜨렸다![/color]")
				var complete_result: Dictionary = runner.complete_node()
				var combat_data: Dictionary = complete_result.get("combat", {})
				var gold: int = int(combat_data.get("gold_earned", 0))
				if gold > 0:
					append_text("[color=gold]골드 %d를 획득했다![/color]" % gold)
				if bool(runner.run_state.get("ended", false)):
					return
				_show_map()
			elif battle_result == "defeat":
				append_text("[color=red]전투 패배...[/color]")
				return
			continue

		if unit == null:
			return

		var unit_name: String = String(unit.get("name", "")) if unit.get("name", "") != "" else ("아군%d" % int(unit.get("internal_id", 0)))
		var is_ally := bool(unit.get("is_ally", false))

		if auto_action != null:
			var target_id: int = int(auto_action.get("target_internal_id", 0))
			var damage: int = int(auto_action.get("damage", 0))
			var target_name := _get_ally_name(target_id)
			if is_ally:
				append_text("  [color=cyan]%s[/color]이(가) 적에게 %d 데미지!" % [unit_name, damage])
			else:
				append_text("  [color=red]%s[/color]이(가) %s에게 %d 데미지!" % [unit_name, target_name, damage])
			continue

		if bool(turn_result.get("action_allowed", false)) and is_ally:
			return

		if not bool(turn_result.get("action_allowed", false)):
			if is_ally:
				append_text("  [color=gray]%s은(는) 행동 불가...[/color]" % unit_name)
			else:
				append_text("  [color=gray]%s은(는) 움직이지 못한다...[/color]" % unit_name)


func _on_skill_selected(skill_index: int) -> void:
	var result: Dictionary = runner.player_attack(skill_index)
	if not bool(result.get("ok", false)):
		append_text("[color=red]%s[/color]" % String(result.get("error", "")))
		return

	var skill: Dictionary = result.get("skill", {})
	var damage: int = int(result.get("damage", 0))
	var target_hp: int = int(result.get("target_hp", 0))
	var skill_name: String = String(skill.get("name", "공격"))

	# 현재 턴 유닛 이름 찾기
	var actor_name := "리나"
	if runner != null and runner.battle_manager != null:
		for ally in runner.battle_manager.allies:
			if bool(ally.is_ally) and ally.is_alive():
				actor_name = String(ally.name) if ally.name != "" else "아군"
				break

	append_text("  [color=cyan]%s[/color]의 [b]%s[/b]! %d 데미지!" % [actor_name, skill_name, damage])

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
				if _last_battle_type == "boss":
					append_text("[color=gold]보스를 쓰러뜨렸다![/color]")
				var complete_result: Dictionary = runner.complete_node()
				var combat_data: Dictionary = complete_result.get("combat", {})
				var gold: int = int(combat_data.get("gold_earned", 0))
				if gold > 0:
					append_text("[color=gold]골드 %d를 획득했다![/color]" % gold)
				if bool(runner.run_state.get("ended", false)):
					return
				_show_map()
			elif battle_result == "defeat":
				append_text("[color=red]전투 패배...[/color]")
				return
			return

		if unit == null:
			return

		var unit_name: String = String(unit.get("name", "")) if unit.get("name", "") != "" else ("아군%d" % int(unit.get("internal_id", 0)))
		var is_ally := bool(unit.get("is_ally", false))

		if auto_action != null:
			var target_id: int = int(auto_action.get("target_internal_id", 0))
			var damage: int = int(auto_action.get("damage", 0))
			var target_name := _get_ally_name(target_id)
			if is_ally:
				append_text("  [color=cyan]%s[/color]이(가) 적에게 %d 데미지!" % [unit_name, damage])
			else:
				append_text("  [color=red]%s[/color]이(가) %s에게 %d 데미지!" % [unit_name, target_name, damage])
			turn_result = runner.next_turn()
			continue

		if bool(turn_result.get("action_allowed", false)) and is_ally:
			return

		if not bool(turn_result.get("action_allowed", false)):
			if is_ally:
				append_text("  [color=gray]%s은(는) 행동 불가...[/color]" % unit_name)
			else:
				append_text("  [color=gray]%s은(는) 움직이지 못한다...[/color]" % unit_name)
			turn_result = runner.next_turn()
			continue

		return


func _on_event_choice_selected(choice_id: String, label: String) -> void:
	append_text("  선택: [color=cyan]%s[/color]" % label)
	var result: Dictionary = runner.resolve_event_choice(choice_id)
	if not bool(result.get("event_resolved", false)):
		append_text("[color=red]이벤트 처리 실패[/color]")
		return

	var reward: Dictionary = result.get("granted_rewards", {})
	var gold: int = int(reward.get("gold", 0))
	if gold > 0:
		append_text("[color=green]골드 %d를 획득했다![/color]" % gold)

	if bool(result.get("combat_triggered", false)):
		append_text("[color=yellow]적들이 습격해온다![/color]")

	runner.complete_node()
	_show_map()


func _show_shop(shop_data: Dictionary) -> void:
	_current_state = "shop"
	_clear_choices()
	append_text("")
	append_text("[color=yellow][b]═══ 상점 ═══[/b][/color]")
	append_text("[color=gray]낡은 간판이 걸린 상점이다. 안쪽에서 희미한 등불이 깜빡인다.[/color]")
	append_text("소지 골드: [color=gold]%dG[/color]" % int(shop_data.get("gold", 0)))
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
	append_text("[color=gray]상점을 나왔다.[/color]")
	runner.complete_node()
	_show_map()


func _show_campfire() -> void:
	_current_state = "campfire"
	_clear_choices()
	append_text("")
	append_text("[color=orange][b]═══ 모닥불 ═══[/b][/color]")
	append_text("[color=gray]따뜻한 불꽃이 주위를 밝힌다. 잠시 쉬어가는 것이 좋을 것이다.[/color]")
	var party_status: Array = runner.get_party_status()
	if party_status.size() > 0:
		var leader: Dictionary = party_status[0]
		var leader_name: String = String(leader.get("name", "리나"))
		append_text("%s의 상태: HP %d/%d" % [leader_name, int(leader.get("current_hp", 0)), int(leader.get("max_hp", 0))])
	_add_choice("1. 휴식 (HP 회복)", "_on_campfire_rest", [])
	_add_choice("2. 투자 (ATK +1, 25G)", "_on_campfire_invest", ["atk"])
	_add_choice("3. 투자 (DEF +1, 25G)", "_on_campfire_invest", ["def"])
	_add_choice("0. 나가기", "_on_campfire_leave", [])


func _on_campfire_rest() -> void:
	var result: Dictionary = runner.campfire_rest()
	var healed: int = int(result.get("healed", 0))
	append_text("[color=green]모닥불 옆에서 쉬었다. HP %d 회복![/color]" % healed)
	runner.complete_node()
	_show_map()


func _on_campfire_invest(stat_name: String) -> void:
	var result: Dictionary = runner.campfire_invest(stat_name)
	if bool(result.get("success", false)):
		var stat_display := {"atk": "공격력", "def": "방어력"}
		append_text("[color=green]%s이(가) 1 증가했다![/color]" % String(stat_display.get(stat_name, stat_name.to_upper())))
	else:
		append_text("[color=red]%s[/color]" % String(result.get("error", "골드 부족!")))
	_show_campfire()


func _on_campfire_leave() -> void:
	append_text("[color=gray]모닥불의 온기가 등 뒤로 멀어진다.[/color]")
	runner.complete_node()
	_show_map()


func _on_restart() -> void:
	text_log.clear()
	append_text("[color=cyan][b]── 새로운 모험이 시작된다 ──[/b][/color]")
	append_text("")
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


func _show_party_narrative(party_status: Array) -> void:
	if party_status.is_empty():
		return
	append_text("[color=gray]── 파티 ──[/color]")
	for member in party_status:
		var name: String = String(member.get("name", "아군"))
		var hp: int = int(member.get("current_hp", 0))
		var max_hp: int = int(member.get("max_hp", 1))
		append_text("  %s HP:%d/%d" % [name, hp, max_hp])


func _update_party_status(allies: Array) -> void:
	if status_label == null:
		return
	status_label.clear()
	var text := ""
	for i in range(allies.size()):
		var ally: Dictionary = allies[i]
		var name: String = String(ally.get("name", "아군%d" % int(ally.get("internal_id", 0))))
		var hp: int = int(ally.get("current_hp", 0))
		var max_hp: int = int(ally.get("max_hp", 1))
		var mp: int = int(ally.get("current_mp", 0))
		if i > 0:
			text += " │ "
		text += "%s HP:%d/%d MP:%d" % [name, hp, max_hp, mp]
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
	var font: FontFile = load("res://assets/fonts/NotoSansKR.tres")
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(_make_choice_callback(method, args))
	choice_container.add_child(button)


func _make_choice_callback(method: String, args: Array) -> Callable:
	return func() -> void:
		callv(method, args)


func _node_display_name(node_type: String) -> String:
	match node_type:
		"combat":
			return "⚔ 일반 전투"
		"elite":
			return "⚔ 정예 전투"
		"boss":
			return "💀 보스"
		"unique":
			return "💀 고유 적"
		"event":
			return "✦ 이벤트"
		"shop":
			return "🏪 상점"
		"campfire":
			return "🔥 모닥불"
		"treasure":
			return "💰 보물"
		_:
			return node_type


func _floor_intro_text(floor_num: int) -> String:
	match floor_num:
		1:
			return "낡은 성의 1층이다. 공기가 축축하고, 벽에는 이끼가 끼어 있다."
		2:
			return "2층으로 올라왔다. 주변이 점점 어두워지며, 달빛이 비정상적으로 붉게 빛난다."
		3:
			return "최상층이다. 붉은 달의 기운이 공기를 무겁게 짓누른다. 보스가 가까이 있다..."
		_:
			return "알 수 없는 층이다."


func _get_ally_name(target_internal_id: int) -> String:
	if runner == null:
		return "아군%d" % target_internal_id
	var party_status: Array = runner.get_party_status()
	if target_internal_id - 1 >= 0 and target_internal_id - 1 < party_status.size():
		return String(party_status[target_internal_id - 1].get("name", "아군%d" % target_internal_id))
	return "아군%d" % target_internal_id
