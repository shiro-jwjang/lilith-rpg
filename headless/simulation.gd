extends SceneTree

const GAME_RUNNER_SCRIPT = preload("res://scripts/rpg/game_runner.gd")

var runner = null
var _step_count: int = 0
var _max_steps: int = 500


func _init() -> void:
	runner = GAME_RUNNER_SCRIPT.new()
	runner.message_logged.connect(_on_message)
	runner.run_ended.connect(_on_run_ended)
	runner.battle_state_changed.connect(_on_battle_state)
	runner.player_input_requested.connect(_on_input_requested)
	runner.start_run()
	_print_party()
	call_deferred("_show_map_and_auto_play")


func _on_message(text: String) -> void:
	print(text)


func _on_battle_state(state: Dictionary) -> void:
	var allies: Array = state.get("allies", [])
	var enemies: Array = state.get("enemies", [])
	print("  --- 전투 상태 ---")
	for enemy in enemies:
		var eid: int = int(enemy.get("internal_id", 0))
		var hp: int = int(enemy.get("current_hp", 0))
		var max_hp: int = int(enemy.get("max_hp", 1))
		if bool(enemy.get("alive", true)):
			print("  적%d: HP %d/%d" % [eid, hp, max_hp])
	_print_party_brief(allies)


func _on_input_requested(_choices: Array) -> void:
	pass


func _on_run_ended(result: Dictionary) -> void:
	if bool(result.get("victory", false)):
		print("")
		print("========== 승리! ==========")
	else:
		print("")
		print("========== 패배 ==========")
	var summary: Dictionary = runner.get_run_summary()
	print("클리어 층: %d" % int(summary.get("floors_cleared", 0)))
	print("전투 승리: %d" % int(summary.get("combats_won", 0)))
	print("획득 골드: %d" % int(summary.get("gold_earned", 0)))
	quit()


func _show_map_and_auto_play() -> void:
	while _step_count < _max_steps and not bool(runner.run_state.get("ended", false)):
		_step_count += 1
		var nodes: Array = runner.get_available_nodes()
		if nodes.is_empty():
			if int(runner.map_manager.current_floor_number) < 3 and runner.advance_floor():
				nodes = runner.get_available_nodes()
			else:
				break

		if nodes.is_empty():
			break

		var chosen_node = _pick_node(nodes)
		var node_id: String = String(chosen_node.id)
		var result: Dictionary = runner.select_node(node_id)
		if not bool(result.get("ok", false)):
			print("노드 선택 실패: %s" % String(result.get("error", "")))
			break

		var node: Dictionary = result.get("node", {})
		var node_type: String = String(node.get("type", ""))
		print("")
		print("[%d층] %s 진입" % [int(runner.run_state.get("current_floor", 1)), _node_display(node_type)])

		var enter_result: Dictionary = runner.enter_node()
		var enter_type: String = String(enter_result.get("type", ""))

		match enter_type:
			"combat", "unique", "boss":
				_auto_play_combat()
			"event":
				_auto_play_event(enter_result.get("data", {}))
				if not bool(runner.run_state.get("ended", false)):
					runner.complete_node()
			"shop":
				print("  상점 방문 (골드: %d)" % int(runner.wallet.get_gold()))
				runner.complete_node()
			"campfire":
				_auto_play_campfire()
				runner.complete_node()
			"treasure":
				var treasure_data: Dictionary = enter_result.get("data", {})
				var rewards: Dictionary = treasure_data.get("rewards", {})
				print("  보물 획득! 골드 +%d" % int(rewards.get("gold", 0)))
				runner.complete_node()
			_:
				runner.complete_node()

		if bool(runner.run_state.get("ended", false)):
			break
		if int(runner.map_manager.current_floor_number) < 3:
			runner.advance_floor()

	if not bool(runner.run_state.get("ended", false)):
		print("")
		print("시뮬레이션 종료 (스텝 제한: %d)" % _max_steps)
		quit()


func _auto_play_combat() -> void:
	while _step_count < _max_steps and not bool(runner.run_state.get("ended", false)):
		_step_count += 1
		var turn_result: Dictionary = runner.next_turn()
		if turn_result.is_empty():
			return

		var battle_result = turn_result.get("battle_result", null)
		if battle_result != null:
			if battle_result == "victory":
				print("  전투 승리!")
				var complete_result: Dictionary = runner.complete_node()
				var combat_data: Dictionary = complete_result.get("combat", {})
				var gold: int = int(combat_data.get("gold_earned", 0))
				if gold > 0:
					print("  골드 +%d" % gold)
			else:
				print("  전투 패배...")
			return

		var unit = turn_result.get("unit", null)
		if unit == null:
			return

		var auto_action = turn_result.get("auto_action", null)
		if auto_action != null:
			print("  적 행동: 아군%d에게 %d 데미지" % [
				int(auto_action.get("target_internal_id", 0)),
				int(auto_action.get("damage", 0)),
			])
			continue

		if bool(turn_result.get("action_allowed", false)) and bool(unit.is_ally):
			var attack_result: Dictionary = runner.player_attack(0)
			if not bool(attack_result.get("ok", false)):
				print("  공격 실패: %s" % String(attack_result.get("error", "")))
				return
			print("  아군 행동: %s, %d 데미지" % [
				String((attack_result.get("skill", {}) as Dictionary).get("name", "공격")),
				int(attack_result.get("damage", 0)),
			])
			var follow_up: Dictionary = attack_result.get("next_turn", {})
			_process_follow_up(follow_up)
			if bool(runner.run_state.get("ended", false)):
				return
			if _combat_has_ended():
				return


func _process_follow_up(turn_result: Dictionary) -> void:
	while not turn_result.is_empty():
		var battle_result = turn_result.get("battle_result", null)
		if battle_result != null:
			if battle_result == "victory":
				print("  전투 승리!")
				var complete_result: Dictionary = runner.complete_node()
				var combat_data: Dictionary = complete_result.get("combat", {})
				var gold: int = int(combat_data.get("gold_earned", 0))
				if gold > 0:
					print("  골드 +%d" % gold)
			else:
				print("  전투 패배...")
			return

		var unit = turn_result.get("unit", null)
		if unit == null:
			return

		var auto_action = turn_result.get("auto_action", null)
		if auto_action != null:
			print("  적 행동: 아군%d에게 %d 데미지" % [
				int(auto_action.get("target_internal_id", 0)),
				int(auto_action.get("damage", 0)),
			])
			turn_result = runner.next_turn()
			continue

		if bool(turn_result.get("action_allowed", false)) and bool(unit.is_ally):
			return

		if not bool(turn_result.get("action_allowed", false)):
			turn_result = runner.next_turn()
			continue

		return


func _combat_has_ended() -> bool:
	var result = runner.battle_manager.check_battle_end()
	return result != null


func _auto_play_event(event_data: Dictionary) -> void:
	var choices: Array = event_data.get("choices", [])
	if choices.is_empty():
		print("  이벤트 선택지 없음")
		return
	var first_choice: Dictionary = choices[0]
	var choice_id: String = String(first_choice.get("id", ""))
	print("  선택: %s" % String(first_choice.get("text", choice_id)))
	var result: Dictionary = runner.resolve_event_choice(choice_id)
	var reward: Dictionary = result.get("granted_rewards", {})
	var gold: int = int(reward.get("gold", 0))
	if gold > 0:
		print("  골드 +%d" % gold)
	if bool(result.get("combat_triggered", false)):
		print("  이벤트 결과: 전투 예고")


func _auto_play_campfire() -> void:
	var result: Dictionary = runner.campfire_rest()
	var healed: int = int(result.get("healed", 0))
	print("  휴식: HP %d 회복" % healed)


func _pick_node(nodes: Array):
	var best = nodes[0]
	var best_score: int = -999999
	for node in nodes:
		var score := _node_score(String(node.type))
		if score > best_score:
			best = node
			best_score = score
	return best


func _node_score(node_type: String) -> int:
	match node_type:
		"boss":
			return 200
		"combat":
			return 100
		"unique":
			return 95
		"treasure":
			return 80
		"campfire":
			return 70
		"event":
			return 60
		"shop":
			return 50 if int(runner.wallet.get_gold()) > 0 else 10
		_:
			return 0


func _print_party() -> void:
	var party: Array = runner.get_party_status()
	print("═══ 파티 ═══")
	for member in party:
		var name: String = String(member.get("name", ""))
		var hp: int = int(member.get("current_hp", 0))
		var max_hp: int = int(member.get("max_hp", 1))
		var mp: int = int(member.get("current_mp", 0))
		print("  %s HP: %d/%d MP: %d" % [name, hp, max_hp, mp])


func _print_party_brief(allies: Array) -> void:
	var parts: Array = []
	for ally in allies:
		var hp: int = int(ally.get("current_hp", 0))
		var max_hp: int = int(ally.get("max_hp", 1))
		parts.append("HP:%d/%d" % [hp, max_hp])
	print("  아군: %s" % " | ".join(parts))


func _node_display(node_type: String) -> String:
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
