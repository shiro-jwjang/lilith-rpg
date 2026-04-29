extends SceneTree

const GAME_RUNNER_SCRIPT = preload("res://scripts/rpg/game_runner.gd")

var _run_count: int = 100
var _results: Array = []
var _current_run_index: int = 0
var _wins: int = 0
var _total_floors_cleared: int = 0
var _total_combats_won: int = 0
var _total_gold_earned: int = 0
var _step_count: int = 0
var _max_steps: int = 500


func _init() -> void:
	_install_headless_autoloads()
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--count="):
			_run_count = int(arg.split("=")[1])

	print("═══ Balance Test ═══")
	print("Runs: %d" % _run_count)
	print("")
	_run_next()


func _install_headless_autoloads() -> void:
	_install_headless_autoload("EventBus", "_event_bus_instance")
	_install_headless_autoload("RunState", "_run_state_instance")


func _install_headless_autoload(autoload_name: String, meta_key: String) -> void:
	if get_root().get_node_or_null(autoload_name) != null:
		return
	var setting := String(ProjectSettings.get_setting("autoload/" + autoload_name, ""))
	if setting.is_empty():
		return
	var script_path := setting.trim_prefix("*")
	var script = load(script_path)
	if script == null:
		return
	var instance = script.new()
	if instance == null:
		return
	instance.name = autoload_name
	get_root().add_child(instance)
	Engine.set_meta(meta_key, instance)


func _run_next() -> void:
	if _current_run_index >= _run_count:
		_print_summary()
		quit()
		return

	_current_run_index += 1
	var runner = GAME_RUNNER_SCRIPT.new()
	var result := _auto_play_run(runner)
	_results.append(result)

	if bool(result.get("victory", false)):
		_wins += 1
	_total_floors_cleared += int(result.get("floors_cleared", 0))
	_total_combats_won += int(result.get("combats_won", 0))
	_total_gold_earned += int(result.get("gold_earned", 0))

	if _current_run_index % 10 == 0:
		print("  ... %d/%d runs completed" % [_current_run_index, _run_count])

	call_deferred("_run_next")


func _auto_play_run(runner) -> Dictionary:
	_step_count = 0
	runner.start_run()

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

		var chosen_node = _pick_node(runner, nodes)
		var node_id: String = String(chosen_node.id)
		var select_result: Dictionary = runner.select_node(node_id)
		if not bool(select_result.get("ok", false)):
			break

		var node: Dictionary = select_result.get("node", {})
		var node_type: String = String(node.get("type", ""))
		var enter_result: Dictionary = runner.enter_node()
		var enter_type: String = String(enter_result.get("type", ""))

		match enter_type:
			"combat", "unique", "boss":
				_auto_play_combat(runner)
			"event":
				_auto_play_event(runner, enter_result.get("data", {}))
				if not bool(runner.run_state.get("ended", false)):
					runner.complete_node()
			"shop":
				runner.complete_node()
			"campfire":
				_auto_play_campfire(runner)
				runner.complete_node()
			"treasure":
				runner.complete_node()
			_:
				if not node_type.is_empty():
					runner.complete_node()

		if bool(runner.run_state.get("ended", false)):
			break
		if int(runner.map_manager.current_floor_number) < 3:
			runner.advance_floor()

	var summary: Dictionary = runner.get_run_summary()
	return {
		"victory": bool(summary.get("victory", false)),
		"floors_cleared": int(summary.get("floors_cleared", 0)),
		"combats_won": int(summary.get("combats_won", 0)),
		"gold_earned": int(summary.get("gold_earned", 0)),
	}


func _auto_play_combat(runner) -> void:
	while _step_count < _max_steps and not bool(runner.run_state.get("ended", false)):
		_step_count += 1
		var turn_result: Dictionary = runner.next_turn()
		if turn_result.is_empty():
			return

		var battle_result = turn_result.get("battle_result", null)
		if battle_result != null:
			if battle_result == "victory":
				runner.complete_node()
			return

		var unit = turn_result.get("unit", null)
		if unit == null:
			return

		var auto_action = turn_result.get("auto_action", null)
		if auto_action != null:
			continue

		if bool(turn_result.get("action_allowed", false)) and bool(unit.is_ally):
			var attack_result: Dictionary = runner.player_attack(0)
			if not bool(attack_result.get("ok", false)):
				return
			var follow_up: Dictionary = attack_result.get("next_turn", {})
			_process_follow_up(runner, follow_up)
			if bool(runner.run_state.get("ended", false)):
				return
			if _combat_has_ended(runner):
				return


func _process_follow_up(runner, turn_result: Dictionary) -> void:
	while not turn_result.is_empty():
		var battle_result = turn_result.get("battle_result", null)
		if battle_result != null:
			if battle_result == "victory":
				runner.complete_node()
			return

		var unit = turn_result.get("unit", null)
		if unit == null:
			return

		var auto_action = turn_result.get("auto_action", null)
		if auto_action != null:
			turn_result = runner.next_turn()
			continue

		if bool(turn_result.get("action_allowed", false)) and bool(unit.is_ally):
			return

		if not bool(turn_result.get("action_allowed", false)):
			turn_result = runner.next_turn()
			continue

		return


func _combat_has_ended(runner) -> bool:
	var result = runner.battle_manager.check_battle_end()
	return result != null


func _auto_play_event(runner, event_data: Dictionary) -> void:
	var choices: Array = event_data.get("choices", [])
	if choices.is_empty():
		return
	var first_choice: Dictionary = choices[0]
	var choice_id: String = String(first_choice.get("id", ""))
	runner.resolve_event_choice(choice_id)


func _auto_play_campfire(runner) -> void:
	runner.campfire_rest()


func _pick_node(runner, nodes: Array):
	var best = nodes[0]
	var best_score: int = -999999
	for node in nodes:
		var score := _node_score(runner, String(node.type))
		if score > best_score:
			best = node
			best_score = score
	return best


func _node_score(runner, node_type: String) -> int:
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


func _print_summary() -> void:
	var losses: int = _run_count - _wins
	var run_total: int = max(_run_count, 1)

	print("═══ Results ═══")
	print("Win rate: %.1f%% (%d/%d)" % [(float(_wins) / float(run_total)) * 100.0, _wins, losses])
	print("Avg floors cleared: %.1f" % (float(_total_floors_cleared) / float(run_total)))
	print("Avg combats won: %.1f" % (float(_total_combats_won) / float(run_total)))
	print("Avg gold earned: %.1f" % (float(_total_gold_earned) / float(run_total)))
