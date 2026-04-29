extends RefCounted

var runner = null
var text_log = null
var choice_panel = null
var state_holder = null


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


func render_battle_state(state: Dictionary) -> void:
	var allies: Array = state.get("allies", [])
	var enemies: Array = state.get("enemies", [])
	var ally_hp_sum := 0
	for a in allies:
		ally_hp_sum += int(a.get("current_hp", 0))
	var enemy_hp_sum := 0
	for e in enemies:
		enemy_hp_sum += int(e.get("current_hp", 0))
	var state_key := ally_hp_sum * 10000 + enemy_hp_sum
	if state_holder != null and state_key == state_holder._last_battle_intro_hash and state_holder._current_state == "combat":
		return
	if state_holder != null:
		state_holder._last_battle_intro_hash = state_key
		state_holder._current_state = "combat"

	update_party_status(allies)

	if state_holder != null and not state_holder._battle_intro_shown:
		state_holder._battle_intro_shown = true
		if state_holder._last_battle_type == "boss":
			append_text("")
			append_text("[color=red][b]═══ BOSS ═══[/b][/color]")
		elif state_holder._last_battle_type == "elite":
			append_text("")
			append_text("[color=orange]═══ 정예 전투 ═══[/color]")
		else:
			append_text("")
			append_text("[color=red]═══ 전투 ═══[/color]")

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
			if state_holder._last_battle_type == "boss":
				append_text("[color=red]%s이(가) 길을 막아섰다![/color]" % combined)
			elif enemy_names.size() == 1:
				append_text("[color=red]%s이(가) 나타났다![/color]" % combined)
			else:
				append_text("[color=red]%s이(가) 나타났다![/color]" % combined)


func render_input_choices(choices: Array) -> void:
	clear_choices()
	if state_holder != null and state_holder._current_state == "combat":
		var turn_unit = runner._current_turn
		var turn_name := ""
		if turn_unit != null:
			turn_name = String(turn_unit.get("name", "")) if turn_unit.get("name", "") != "" else "아군"
		append_text("")
		if turn_name != "":
			append_text("[color=yellow]▶ %s의 턴[/color]" % turn_name)
		append_text("[color=cyan]─ 행동 선택 ─[/color]")
		for i in range(choices.size()):
			var skill: Dictionary = choices[i]
			var skill_name: String = String(skill.get("name", "스킬%d" % (i + 1)))
			var mp_cost: int = int(skill.get("mp_cost", 0))
			append_text("  [%d] %s (MP: %d)" % [i + 1, skill_name, mp_cost])
			add_choice("%d. %s (MP:%d)" % [i + 1, skill_name, mp_cost], "_on_skill_selected", [i])
		return

	append_text("")
	append_text("[color=cyan]─ 선택지 ─[/color]")
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var choice_id: String = String(choice.get("id", "choice_%d" % i))
		var label: String = String(choice.get("text", choice_id))
		append_text("  [%d] %s" % [i + 1, label])
		add_choice("%d. %s" % [i + 1, label], "_on_event_choice_selected", [choice_id, label])


func handle_skill_selected(skill_index: int) -> void:
	var turn_unit = runner._current_turn
	var actor_name := "아군"
	if turn_unit != null:
		actor_name = String(turn_unit.get("name", "")) if turn_unit.get("name", "") != "" else "아군"

	var result: Dictionary = runner.player_attack(skill_index)
	if not bool(result.get("ok", false)):
		append_text("[color=red]%s[/color]" % String(result.get("error", "")))
		return

	var skill: Dictionary = result.get("skill", {})
	var damage: int = int(result.get("damage", 0))
	var skill_name: String = String(skill.get("name", "공격"))
	var effect_type: String = String(result.get("effect_type", "damage"))
	var target_name: String = String(result.get("target_name", "적"))

	match effect_type:
		"heal":
			var heal_amount: int = int(result.get("heal_amount", 0))
			append_text("  [color=green]%s[/color]이(가) %s을(를) 치유! HP %d 회복!" % [actor_name, target_name, heal_amount])
		"buff":
			append_text("  [color=blue]%s[/color]이(가) [b]%s[/b]을(를) 사용했다!" % [actor_name, skill_name])
		"taunt":
			append_text("  [color=yellow]%s[/color]이(가) 적의 주의를 끌었다!" % actor_name)
		"damage":
			append_text("  [color=cyan]%s[/color]의 [b]%s[/b]! %s에게 %d 데미지!" % [actor_name, skill_name, target_name, damage])
		_:
			append_text("  [color=cyan]%s[/color]의 [b]%s[/b]! %d 데미지!" % [actor_name, skill_name, damage])

	var follow_up: Dictionary = result.get("next_turn", {})
	process_follow_up(follow_up)


func auto_advance_combat() -> void:
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
				if state_holder != null and state_holder._last_battle_type == "boss":
					append_text("[color=gold]보스를 쓰러뜨렸다![/color]")
				var complete_result: Dictionary = runner.complete_node(true)
				var combat_data: Dictionary = complete_result.get("combat", {})
				var gold: int = int(combat_data.get("gold_earned", 0))
				if gold > 0:
					append_text("[color=gold]골드 %d를 획득했다![/color]" % gold)
				if bool(complete_result.get("needs_advance", false)):
					runner.advance_floor()
				if bool(runner.run_state.get("ended", false)):
					return
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
			var target_name := String(auto_action.get("target_name", ""))
			if target_name.is_empty():
				target_name = get_ally_name(target_id)
			if is_ally:
				var enemy_name := target_name if not target_name.is_empty() else "적"
				append_text("  [color=cyan]%s[/color]이(가) %s에게 %d 데미지!" % [unit_name, enemy_name, damage])
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


func process_follow_up(turn_result: Dictionary) -> void:
	while not turn_result.is_empty():
		var battle_result = turn_result.get("battle_result", null)
		var unit = turn_result.get("unit", null)
		var auto_action = turn_result.get("auto_action", null)

		if battle_result != null:
			if battle_result == "victory":
				append_text("[color=green]전투 승리![/color]")
				if state_holder != null and state_holder._last_battle_type == "boss":
					append_text("[color=gold]보스를 쓰러뜨렸다![/color]")
				var complete_result: Dictionary = runner.complete_node(true)
				var combat_data: Dictionary = complete_result.get("combat", {})
				var gold: int = int(combat_data.get("gold_earned", 0))
				if gold > 0:
					append_text("[color=gold]골드 %d를 획득했다![/color]" % gold)
				if bool(complete_result.get("needs_advance", false)):
					runner.advance_floor()
				if bool(runner.run_state.get("ended", false)):
					return
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
			var target_name := String(auto_action.get("target_name", ""))
			if target_name.is_empty():
				target_name = get_ally_name(target_id)
			if is_ally:
				var enemy_name := target_name if not target_name.is_empty() else "적"
				append_text("  [color=cyan]%s[/color]이(가) %s에게 %d 데미지!" % [unit_name, enemy_name, damage])
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


func update_party_status(allies: Array) -> void:
	if state_holder == null or state_holder.status_label == null:
		return
	state_holder.status_label.clear()
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
	state_holder.status_label.append_text(text)


func get_ally_name(target_internal_id: int) -> String:
	if runner == null:
		return "아군%d" % target_internal_id
	var party_status: Array = runner.get_party_status()
	if target_internal_id - 1 >= 0 and target_internal_id - 1 < party_status.size():
		return String(party_status[target_internal_id - 1].get("name", "아군%d" % target_internal_id))
	return "아군%d" % target_internal_id
