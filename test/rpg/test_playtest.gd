extends "res://test/rpg/test_base.gd"

const GAME_RUNNER_SCRIPT := preload("res://scripts/rpg/game_runner.gd")
const FLOOR_SCRIPT := preload("res://scripts/rpg/map/floor.gd")
const NODE_SCRIPT := preload("res://scripts/rpg/map/node.gd")
const UNIT_SCRIPT := preload("res://scripts/rpg/combat/unit.gd")


class _MapSignalTracker extends RefCounted:
	var count := 0
	var states: Array = []

	func on_map(state: Dictionary) -> void:
		count += 1
		states.append(state.duplicate(true))


class _StubContentData extends RefCounted:
	var normal_enemies: Array
	var elite_enemies: Array
	var unique_enemies: Array
	var boss_enemy: Dictionary
	var skill_map: Dictionary

	func _init() -> void:
		normal_enemies = [_enemy_template("일반 적", "normal", 40, 10, 4, 9, ["출혈"])]
		elite_enemies = [_enemy_template("정예 적", "elite", 70, 14, 6, 8, [])]
		unique_enemies = [_enemy_template("유니크 적", "unique", 85, 15, 7, 10, [])]
		boss_enemy = _enemy_template("보스 적", "boss", 120, 18, 8, 7, [])
		skill_map = {
			"전위딜러": [{"name": "베기", "mp_cost": 0, "multiplier": 1.0, "target": "single"}],
			"수호자": [{"name": "방패타격", "mp_cost": 0, "multiplier": 1.0, "target": "single"}],
			"마법지원가": [{"name": "화염", "mp_cost": 0, "multiplier": 1.1, "target": "single"}],
		}

	func get_normal_enemies() -> Array:
		return normal_enemies.duplicate(true)

	func get_elite_enemies() -> Array:
		return elite_enemies.duplicate(true)

	func get_unique_enemies() -> Array:
		return unique_enemies.duplicate(true)

	func get_boss() -> Dictionary:
		return boss_enemy.duplicate(true)

	func get_skills_for_character(name: String) -> Array:
		return (skill_map.get(name, []) as Array).duplicate(true)

	func _enemy_template(name: String, tier: String, hp: int, atk: int, defense: int, speed: int, statuses: Array) -> Dictionary:
		return {
			"name": name,
			"tier": tier,
			"max_hp": hp,
			"attack": atk,
			"defense": defense,
			"speed": speed,
			"status_effects": statuses.duplicate(true),
		}


class _CaptureBattleManager extends RefCounted:
	var ally_configs: Array = []
	var enemy_configs: Array = []
	var allies: Array = []
	var enemies: Array = []
	var turn_results: Array = []
	var battle_end_result = null

	func init_battle(party_configs: Array, foe_configs: Array) -> void:
		ally_configs = party_configs.duplicate(true)
		enemy_configs = foe_configs.duplicate(true)
		allies.clear()
		enemies.clear()
		for config_value in ally_configs:
			var ally_config: Dictionary = config_value.duplicate(true)
			ally_config["is_ally"] = true
			allies.append(UNIT_SCRIPT.new(ally_config))
		for config_value in enemy_configs:
			var enemy_config: Dictionary = config_value.duplicate(true)
			enemy_config["is_ally"] = false
			enemies.append(UNIT_SCRIPT.new(enemy_config))

	func next_turn() -> Dictionary:
		if turn_results.is_empty():
			return {"battle_result": battle_end_result}
		return turn_results.pop_front()

	func check_battle_end():
		return battle_end_result


class _FixedRewardGenerator extends RefCounted:
	func generate_rewards(_battle_type: String) -> Dictionary:
		return {
			"gold": 25,
			"items": [{"category": "equipment", "id": "reward_sword"}],
			"relics": [],
		}

	func generate_treasure_rewards() -> Dictionary:
		return {
			"gold": 0,
			"items": [],
			"relics": [{"id": "treasure_relic"}],
		}

	func generate_event_reward(_choice: String) -> Dictionary:
		return {"gold": 15, "items": [], "relics": []}


class _CaptureRewardManager extends RefCounted:
	var calls: Array = []

	func grant_rewards(rewards: Dictionary, inventory) -> Dictionary:
		calls.append(rewards.duplicate(true))
		if rewards.has("gold"):
			inventory.wallet.add_gold(int(rewards.get("gold", 0)))
		for item in rewards.get("items", []):
			if String(item.get("category", "")) == "equipment":
				inventory.add_equipment(String(item.get("id", "")))
		for relic in rewards.get("relics", []):
			inventory.add_relic(String(relic.get("id", "")))
		return {"success": true}


class _StubEventManager extends RefCounted:
	var choices := [
		{"id": "기도", "text": "기도", "condition_met": true},
		{"id": "파괴", "text": "파괴", "condition_met": true},
	]
	var resolve_result := {
		"event_resolved": true,
		"next_state": "done",
		"reward": {"gold": 12, "items": [], "relics": []},
		"combat_triggered": false,
		"combat": {},
	}
	var last_choice_id := ""

	func get_event(event_id: String) -> RefCounted:
		var event_base = load("res://scripts/rpg/events/event_base.gd")
		return event_base.new({"event_id": event_id, "title": "테스트 이벤트"})

	func get_visible_choices(_event_id: String, _context: Dictionary) -> Array:
		return choices.duplicate(true)

	func resolve_choice(_event_id: String, choice_id: String, _context: Dictionary) -> Dictionary:
		last_choice_id = choice_id
		return resolve_result.duplicate(true)


func test_full_playthrough() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var reward_manager = _CaptureRewardManager.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"reward_generator": _FixedRewardGenerator.new(),
		"reward_manager": reward_manager,
		"act": _playthrough_act(),
	})

	runner.start_run({"act": _playthrough_act()})
	assert_eq(int(runner.run_state.get("current_floor", 0)), 1, "playtest full run should start on floor 1")
	assert_eq(runner.get_available_nodes().size(), 3, "playtest full run should expose 3 floor 1 nodes")

	var campfire_node = _find_node_by_type(runner.get_available_nodes(), "campfire")
	assert_not_null(campfire_node, "playtest full run should include a floor 1 campfire")
	if campfire_node == null:
		return
	var campfire_select: Dictionary = runner.select_node(String(campfire_node.id))
	assert_true(bool(campfire_select.get("ok", false)), "playtest full run campfire selection should succeed")
	var campfire_enter: Dictionary = runner.enter_node()
	assert_eq(String(campfire_enter.get("type", "")), "campfire", "playtest full run should enter campfire")
	var campfire_complete: Dictionary = runner.complete_node()
	assert_true(bool(campfire_complete.get("success", false)), "playtest full run campfire completion should succeed")
	assert_eq(int(runner.run_state.get("current_floor", 0)), 2, "playtest full run should advance to floor 2 after campfire")
	assert_eq(runner.get_available_nodes().size(), 4, "playtest full run should expose 4 floor 2 nodes")

	var shop_node = _find_node_by_type(runner.get_available_nodes(), "shop")
	assert_not_null(shop_node, "playtest full run should include a floor 2 shop")
	if shop_node == null:
		return
	var shop_select: Dictionary = runner.select_node(String(shop_node.id))
	assert_true(bool(shop_select.get("ok", false)), "playtest full run shop selection should succeed")
	var shop_enter: Dictionary = runner.enter_node()
	assert_eq(String(shop_enter.get("type", "")), "shop", "playtest full run should enter shop")
	var shop_complete: Dictionary = runner.complete_node()
	assert_true(bool(shop_complete.get("success", false)), "playtest full run shop completion should succeed")
	assert_eq(int(runner.run_state.get("current_floor", 0)), 3, "playtest full run should advance to floor 3 after shop")

	var boss_node = _find_node_by_type(runner.get_available_nodes(), "boss")
	assert_not_null(boss_node, "playtest full run should include a floor 3 boss")
	if boss_node == null:
		return
	var boss_select: Dictionary = runner.select_node(String(boss_node.id))
	assert_true(bool(boss_select.get("ok", false)), "playtest full run boss selection should succeed")
	var boss_enter: Dictionary = runner.enter_node()
	assert_eq(String(boss_enter.get("type", "")), "boss", "playtest full run should enter boss combat")
	battle_manager.battle_end_result = "victory"
	var boss_complete: Dictionary = runner.complete_node()
	assert_true(bool(boss_complete.get("success", false)), "playtest full run boss completion should succeed")
	assert_true(bool(runner.run_state.get("ended", false)), "playtest full run should end after boss victory")
	assert_true(bool(runner.run_state.get("victory", false)), "playtest full run should mark victory")
	assert_eq(int(runner.run_state.get("floors_cleared", 0)), 3, "playtest full run should clear three floors")
	assert_eq((runner.run_state.get("nodes_visited", []) as Array).size(), 3, "playtest full run should track visited nodes")
	assert_eq(int(runner.run_state.get("combats_won", 0)), 1, "playtest full run should count the boss win")
	assert_eq(reward_manager.calls.size(), 1, "playtest full run should grant rewards once for the boss")


func test_combat_playthrough() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"reward_generator": _FixedRewardGenerator.new(),
		"reward_manager": _CaptureRewardManager.new(),
		"act": _act_with_single_node("combat", {"tier": "normal"}),
	})

	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	var select_result: Dictionary = runner.select_node("floor1_node1")
	assert_true(bool(select_result.get("ok", false)), "playtest combat selection should succeed")
	var enter_result: Dictionary = runner.enter_node()
	assert_eq(String(enter_result.get("type", "")), "combat", "playtest combat should enter a combat node")
	battle_manager.battle_end_result = "victory"
	var complete_result: Dictionary = runner.complete_node()
	assert_true(bool(complete_result.get("success", false)), "playtest combat completion should succeed")
	assert_eq(int(runner.run_state.get("current_floor", 0)), 2, "playtest combat should advance to floor 2")
	assert_eq(int(runner.run_state.get("combats_won", 0)), 1, "playtest combat should increment wins")
	assert_eq((runner.run_state.get("nodes_visited", []) as Array).size(), 1, "playtest combat should record the visited node")


func test_event_playthrough() -> void:
	var event_manager = _StubEventManager.new()
	var runner = _make_runner({
		"event_manager": event_manager,
		"reward_manager": _CaptureRewardManager.new(),
		"act": _act_with_single_node("event", {"event_id": "ruined_altar"}),
	})

	runner.start_run({"act": _act_with_single_node("event", {"event_id": "ruined_altar"})})
	var select_result: Dictionary = runner.select_node("floor1_node1")
	assert_true(bool(select_result.get("ok", false)), "playtest event selection should succeed")
	var enter_result: Dictionary = runner.enter_node()
	assert_eq(String(enter_result.get("type", "")), "event", "playtest event should enter an event node")
	var choices: Array = enter_result.get("data", {}).get("choices", []) as Array
	assert_gt(choices.size(), 0, "playtest event should expose at least one choice")
	var first_choice_id := String(choices[0].get("id", ""))
	var resolve_result: Dictionary = runner.resolve_event_choice(first_choice_id)
	assert_true(bool(resolve_result.get("event_resolved", false)), "playtest event choice should resolve")
	assert_eq(String(event_manager.last_choice_id), first_choice_id, "playtest event should resolve the selected choice")
	var complete_result: Dictionary = runner.complete_node()
	assert_true(bool(complete_result.get("success", false)), "playtest event completion should succeed")
	assert_eq(int(runner.run_state.get("current_floor", 0)), 2, "playtest event should advance to floor 2")


func test_treasure_playthrough() -> void:
	var reward_manager = _CaptureRewardManager.new()
	var runner = _make_runner({
		"reward_manager": reward_manager,
		"act": _playthrough_act(),
	})

	runner.start_run({"act": _playthrough_act()})
	assert_true(runner.advance_floor(), "playtest treasure should advance from floor 1 to floor 2")
	assert_true(runner.advance_floor(), "playtest treasure should advance from floor 2 to floor 3")

	var treasure_node = _find_node_by_type(runner.get_available_nodes(), "treasure")
	assert_not_null(treasure_node, "playtest treasure should include a floor 3 treasure")
	if treasure_node == null:
		return
	var select_result: Dictionary = runner.select_node(String(treasure_node.id))
	assert_true(bool(select_result.get("ok", false)), "playtest treasure selection should succeed")
	var enter_result: Dictionary = runner.enter_node()
	assert_eq(String(enter_result.get("type", "")), "treasure", "playtest treasure should enter a treasure node")
	var complete_result: Dictionary = runner.complete_node()
	assert_true(bool(complete_result.get("success", false)), "playtest treasure completion should succeed")
	assert_eq(int(runner.run_state.get("current_floor", 0)), 3, "playtest treasure should stay on floor 3")
	assert_false(bool(runner.run_state.get("ended", false)), "playtest treasure should not end the run")
	assert_eq(reward_manager.calls.size(), 1, "playtest treasure should grant rewards once")

	var boss_select: Dictionary = runner.select_node("floor3_node3")
	assert_false(bool(boss_select.get("ok", true)), "playtest treasure should reject a second floor 3 selection")


func test_signal_emission_counts() -> void:
	var tracker = _MapSignalTracker.new()
	var runner = _make_runner({
		"act": _act_with_single_node("campfire"),
	})
	runner.map_state_changed.connect(tracker.on_map)

	runner.start_run({"act": _act_with_single_node("campfire")})
	assert_eq(tracker.count, 1, "playtest signals should emit once on start_run")

	var select_result: Dictionary = runner.select_node("floor1_node1")
	assert_true(bool(select_result.get("ok", false)), "playtest signals selection should succeed")
	assert_eq(tracker.count, 2, "playtest signals should emit once on select_node")

	runner.enter_node()
	assert_eq(tracker.count, 2, "playtest signals should not emit on enter_node")

	var complete_result: Dictionary = runner.complete_node()
	assert_true(bool(complete_result.get("success", false)), "playtest signals completion should succeed")
	assert_eq(tracker.count, 3, "playtest signals should emit once on complete_node")


func test_no_double_map_display() -> void:
	var tracker = _MapSignalTracker.new()
	var runner = _make_runner({
		"act": _act_with_single_node("event", {"event_id": "ruined_altar"}),
		"event_manager": _StubEventManager.new(),
		"reward_manager": _CaptureRewardManager.new(),
	})

	runner.start_run({"act": _act_with_single_node("event", {"event_id": "ruined_altar"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	runner.resolve_event_choice("기도")

	runner.map_state_changed.connect(tracker.on_map)
	var complete_result: Dictionary = runner.complete_node()
	assert_true(bool(complete_result.get("success", false)), "playtest no-double-map completion should succeed")
	assert_eq(tracker.count, 1, "playtest no-double-map should emit map_state_changed once on complete_node")

	var replay_select: Dictionary = runner.select_node("floor1_node1")
	assert_false(bool(replay_select.get("ok", true)), "playtest no-double-map should reject reselection of a completed floor 1 node")


func _make_runner(config: Dictionary) -> RefCounted:
	var merged := {
		"content_data": _StubContentData.new(),
		"reward_generator": _FixedRewardGenerator.new(),
		"reward_manager": _CaptureRewardManager.new(),
	}
	for key in config:
		merged[key] = config[key]
	return GAME_RUNNER_SCRIPT.new(merged)


func _playthrough_act() -> Dictionary:
	var floor1 = FLOOR_SCRIPT.new(1, {"skip_generation": true})
	floor1.nodes = [
		NODE_SCRIPT.new("combat", 1, 0, {"id": "floor1_node1", "tier": "normal"}),
		NODE_SCRIPT.new("event", 1, 1, {"id": "floor1_node2", "event_id": "ruined_altar"}),
		NODE_SCRIPT.new("campfire", 1, 2, {"id": "floor1_node3"}),
	]

	var floor2 = FLOOR_SCRIPT.new(2, {"skip_generation": true})
	floor2.nodes = [
		NODE_SCRIPT.new("combat", 2, 0, {"id": "floor2_node1", "tier": "normal"}),
		NODE_SCRIPT.new("combat", 2, 1, {"id": "floor2_node2", "tier": "elite"}),
		NODE_SCRIPT.new("event", 2, 2, {"id": "floor2_node3", "event_id": "ruin_merchant"}),
		NODE_SCRIPT.new("shop", 2, 3, {"id": "floor2_node4"}),
	]

	var floor3 = FLOOR_SCRIPT.new(3, {"skip_generation": true})
	floor3.nodes = [
		NODE_SCRIPT.new("treasure", 3, 0, {"id": "floor3_node1"}),
		NODE_SCRIPT.new("unique", 3, 1, {"id": "floor3_node2"}),
		NODE_SCRIPT.new("boss", 3, 2, {"id": "floor3_node3"}),
	]
	return {"floors": [floor1, floor2, floor3], "event_catalog": []}


func _act_with_single_node(node_type: String, data: Dictionary = {}, floor_number: int = 1) -> Dictionary:
	var floors: Array = []
	for number in [1, 2, 3]:
		var floor = FLOOR_SCRIPT.new(number, {"skip_generation": true})
		floor.nodes = []
		if number == floor_number:
			var node_data := {"id": "floor%d_node1" % number}
			for key in data:
				node_data[key] = data[key]
			floor.nodes.append(NODE_SCRIPT.new(node_type, number, 0, node_data))
		floors.append(floor)
	return {"floors": floors, "event_catalog": []}


func _find_node_by_type(nodes: Array, node_type: String):
	for node in nodes:
		if String(node.type) == node_type:
			return node
	return null
