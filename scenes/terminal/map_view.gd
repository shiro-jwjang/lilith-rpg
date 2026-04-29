extends RefCounted

var runner = null
var text_log = null
var choice_panel = null
var state_holder = null

const NODE_DISPLAY_NAMES := {
	"combat": "⚔ 일반 전투",
	"elite": "⚔ 정예 전투",
	"boss": "💀 보스",
	"unique": "💀 고유 적",
	"event": "✦ 이벤트",
	"shop": "🏪 상점",
	"campfire": "🔥 모닥불",
	"treasure": "💰 보물",
}


func setup(runner_ref, text_log_ref, choice_panel_ref, state_ref) -> void:
	runner = runner_ref
	text_log = text_log_ref
	choice_panel = choice_panel_ref
	state_holder = state_ref


func append_text(text: String) -> void:
	if text_log != null:
		text_log.append_text(text)


func clear_choices() -> void:
	if choice_panel != null:
		choice_panel.clear_choices()


func add_choice(text: String, method: String, args: Array) -> void:
	if choice_panel != null:
		choice_panel.add_choice(text, method, args)


func render_map_state(state: Dictionary) -> void:
	var floor_num: int = int(state.get("current_floor", 1))
	var state_hash := hash(floor_num * 1000 + state.get("available_nodes", []).size())
	if state_holder != null and state_hash == state_holder._last_map_floor and state_holder._current_state == "map":
		return
	if state_holder != null:
		state_holder._last_map_floor = state_hash
		state_holder._current_state = "map"
	append_text("")
	append_text("[color=yellow]═══ %d층 ═══[/color]" % floor_num)
	append_text("[color=gray]%s[/color]" % floor_intro_text(floor_num))

	var party_status: Array = runner.get_party_status() if runner != null else []
	show_party_narrative(party_status)

	var nodes: Array = state.get("available_nodes", [])
	clear_choices()
	append_text("")
	append_text("[color=cyan]앞에 %d개의 길이 보입니다.[/color]" % nodes.size())
	for i in range(nodes.size()):
		var node = nodes[i]
		var node_type: String = String(node.type)
		var display_name := node_display_name(node_type)
		append_text("  [%d] %s" % [i + 1, display_name])
		add_choice("%d. %s" % [i + 1, display_name], "_on_node_selected", [String(node.id)])


func handle_node_selected(node_id: String) -> void:
	var result: Dictionary = runner.select_node(node_id)
	if not bool(result.get("ok", false)):
		append_text("[color=red]오류: %s[/color]" % String(result.get("error", "")))
		return

	var node: Dictionary = result.get("node", {})
	var node_type: String = String(node.get("type", ""))
	var enter_result: Dictionary = runner.enter_node()

	match node_type:
		"combat", "unique", "boss":
			if state_holder != null:
				state_holder._last_battle_type = node_type
				state_holder._battle_intro_shown = false
			append_text("")
			if node_type == "boss":
				append_text("[color=red][b]보스가 다가온다...[/b][/color]")
			elif node_type == "elite":
				append_text("[color=orange]강력한 기운이 느껴진다...[/color]")
			else:
				append_text("[color=red]적과 마주쳤다![/color]")
			if state_holder != null:
				state_holder._auto_advance_combat()
		"event":
			if state_holder != null:
				state_holder._current_state = "event"
			var event_data: Dictionary = enter_result.get("data", {})
			var event_title: String = String(event_data.get("title", "이벤트"))
			append_text("")
			append_text("[color=purple][b]── %s ──[/b][/color]" % event_title)
			var choices: Array = event_data.get("choices", [])
			if state_holder != null:
				state_holder._on_input_requested(choices)
		"shop":
			show_shop(enter_result.get("data", {}))
		"campfire":
			show_campfire()
		"treasure":
			var treasure_data: Dictionary = enter_result.get("data", {})
			append_text("[color=gold]보물 상자를 발견했다![/color]")
			var rewards: Dictionary = treasure_data.get("rewards", {})
			var gold: int = int(rewards.get("gold", 0))
			if gold > 0:
				append_text("[color=gold]골드 %d를 획득했다![/color]" % gold)
			runner.complete_node()


func handle_event_choice(choice_id: String, label: String) -> void:
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


func show_shop(shop_data: Dictionary) -> void:
	if state_holder != null:
		state_holder._current_state = "shop"
	clear_choices()
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
		add_choice("%d. %s (%dG)" % [i + 1, name, price], "_on_shop_buy", [i])
	add_choice("0. 나가기", "_on_shop_leave", [])


func handle_shop_buy(item_index: int) -> void:
	var result: Dictionary = runner.shop_purchase(item_index)
	if bool(result.get("success", false)):
		append_text("[color=green]구매 완료![/color]")
		show_shop(runner.enter_shop())
	else:
		append_text("[color=red]%s[/color]" % String(result.get("error", result.get("reason", "구매 실패"))))


func handle_shop_leave() -> void:
	append_text("[color=gray]상점을 나왔다.[/color]")
	runner.complete_node()


func show_campfire() -> void:
	if state_holder != null:
		state_holder._current_state = "campfire"
	clear_choices()
	append_text("")
	append_text("[color=orange][b]═══ 모닥불 ═══[/b][/color]")
	append_text("[color=gray]따뜻한 불꽃이 주위를 밝힌다. 잠시 쉬어가는 것이 좋을 것이다.[/color]")
	var party_status: Array = runner.get_party_status()
	if party_status.size() > 0:
		var leader: Dictionary = party_status[0]
		var leader_name: String = String(leader.get("name", "리나"))
		append_text("%s의 상태: HP %d/%d" % [leader_name, int(leader.get("current_hp", 0)), int(leader.get("max_hp", 0))])
	add_choice("1. 휴식 (HP 회복)", "_on_campfire_rest", [])
	add_choice("2. 투자 (ATK +1, 25G)", "_on_campfire_invest", ["atk"])
	add_choice("3. 투자 (DEF +1, 25G)", "_on_campfire_invest", ["def"])
	add_choice("0. 나가기", "_on_campfire_leave", [])


func handle_campfire_rest() -> void:
	var result: Dictionary = runner.campfire_rest()
	var healed: int = int(result.get("healed", 0))
	append_text("[color=green]모닥불 옆에서 쉬었다. HP %d 회복![/color]" % healed)
	runner.complete_node()


func handle_campfire_invest(stat_name: String) -> void:
	var result: Dictionary = runner.campfire_invest(stat_name)
	if bool(result.get("success", false)):
		var stat_display := {"atk": "공격력", "def": "방어력"}
		append_text("[color=green]%s이(가) 1 증가했다![/color]" % String(stat_display.get(stat_name, stat_name.to_upper())))
	else:
		append_text("[color=red]%s[/color]" % String(result.get("error", "골드 부족!")))
	show_campfire()


func handle_campfire_leave() -> void:
	append_text("[color=gray]모닥불의 온기가 등 뒤로 멀어진다.[/color]")
	runner.complete_node()


func show_party_narrative(party_status: Array) -> void:
	if party_status.is_empty():
		return
	append_text("[color=gray]── 파티 ──[/color]")
	for member in party_status:
		var name: String = String(member.get("name", "아군"))
		var hp: int = int(member.get("current_hp", 0))
		var max_hp: int = int(member.get("max_hp", 1))
		append_text("  %s HP:%d/%d" % [name, hp, max_hp])


func node_display_name(node_type: String) -> String:
	return String(NODE_DISPLAY_NAMES.get(node_type, node_type))


func floor_intro_text(floor_num: int) -> String:
	match floor_num:
		1:
			return "낡은 성의 1층이다. 공기가 축축하고, 벽에는 이끼가 끼어 있다."
		2:
			return "2층으로 올라왔다. 주변이 점점 어두워지며, 달빛이 비정상적으로 붉게 빛난다."
		3:
			return "최상층이다. 붉은 달의 기운이 공기를 무겁게 짓누른다. 보스가 가까이 있다..."
		_:
			return "알 수 없는 층이다."
