extends "res://test/rpg/test_base.gd"

const GAME_RUNNER_SCRIPT := preload("res://scripts/rpg/game_runner.gd")
const EVENT_MANAGER_SCRIPT := preload("res://scripts/rpg/events/event_manager.gd")
const FLOOR_SCRIPT := preload("res://scripts/rpg/map/floor.gd")
const NODE_SCRIPT := preload("res://scripts/rpg/map/node.gd")
const UNIT_SCRIPT := preload("res://scripts/rpg/combat/unit.gd")
const WALLET_SCRIPT := preload("res://scripts/rpg/economy/wallet.gd")


class _MapSignalTracker extends RefCounted:
	var count := 0
	var states: Array = []

	func on_map(state: Dictionary) -> void:
		count += 1
		states.append(state.duplicate(true))


class _SignalOrderTracker extends RefCounted:
	var events: Array = []

	func on_battle(_state: Dictionary) -> void:
		events.append("battle")

	func on_map(_state: Dictionary) -> void:
		events.append("map")

	func on_input(_choices: Array) -> void:
		events.append("input")

	func on_message(_text: String) -> void:
		events.append("message")

	func on_end(_result: Dictionary) -> void:
		events.append("end")


class _DeterministicRng extends RefCounted:
	var _values: Array = []
	var _index := 0

	func _init(values: Array = [0.0]) -> void:
		_values = values.duplicate(true)
		if _values.is_empty():
			_values = [0.0]

	func randf() -> float:
		var value := float(_values[min(_index, _values.size() - 1)])
		_index += 1
		return value

	func randi_range(min_value: int, _max_value: int) -> int:
		return min_value


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


class _MpCostContentData extends _StubContentData:
	func _init() -> void:
		super._init()
		skill_map["마법지원가"] = [
			{"name": "화염", "mp_cost": 5, "multiplier": 1.1, "target": "single"},
		]


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
	var generated_types: Array = []

	func generate_rewards(battle_type: String) -> Dictionary:
		generated_types.append(battle_type)
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


class _StubShopManager extends RefCounted:
	var wallet = null
	var items: Array = []

	func _init(target_wallet) -> void:
		wallet = target_wallet
		items = [
			{"type": "equipment", "name": "상점 검", "price": 30},
			{"type": "potion", "name": "healing_potion", "price": 10},
		]

	func visit_shop(_config: Dictionary = {}) -> Dictionary:
		return {
			"equipment_list": [items[0].duplicate(true)],
			"relic_list": [],
			"potion_list": [items[1].duplicate(true)],
		}

	func purchase_item(item: Dictionary) -> Dictionary:
		var price := int(item.get("price", 0))
		if not wallet.spend(price):
			return {"success": false, "reason": "insufficient_gold", "gold_after": wallet.get_gold()}
		return {"success": true, "item": item.duplicate(true), "gold_after": wallet.get_gold()}


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


func test_main_story_playthrough() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var reward_generator = _FixedRewardGenerator.new()
	var reward_manager = _CaptureRewardManager.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"reward_generator": reward_generator,
		"reward_manager": reward_manager,
		"act": _playthrough_act(),
	})

	runner.start_run({"act": _playthrough_act()})
	assert_true(bool(runner.select_node("floor1_node1").get("ok", false)), "main story should select floor 1 combat")
	assert_eq(String(runner.enter_node().get("type", "")), "combat", "main story should enter floor 1 combat")
	battle_manager.battle_end_result = "victory"
	assert_true(bool(runner.complete_node().get("success", false)), "main story should clear floor 1 combat")
	assert_eq(int(runner.run_state.get("current_floor", 0)), 2, "main story should advance to floor 2")

	assert_true(bool(runner.select_node("floor2_node2").get("ok", false)), "main story should select elite combat")
	assert_eq(String(runner.enter_node().get("type", "")), "combat", "main story should enter elite combat")
	assert_eq(String(battle_manager.enemy_configs[0].get("tier", "")), "elite", "main story should load elite enemies")
	battle_manager.battle_end_result = "victory"
	assert_true(bool(runner.complete_node().get("success", false)), "main story should clear elite combat")
	assert_eq(int(runner.run_state.get("current_floor", 0)), 3, "main story should advance to floor 3")

	assert_true(bool(runner.select_node("floor3_node3").get("ok", false)), "main story should select boss")
	assert_eq(String(runner.enter_node().get("type", "")), "boss", "main story should enter boss combat")
	assert_eq(String(battle_manager.enemy_configs[0].get("tier", "")), "boss", "main story should load boss enemy")
	battle_manager.battle_end_result = "victory"
	var complete_result: Dictionary = runner.complete_node()
	assert_true(bool(complete_result.get("success", false)), "main story should end on boss victory")
	assert_true(bool(runner.run_state.get("ended", false)), "main story should end the run")
	assert_true(bool(runner.run_state.get("victory", false)), "main story should mark victory")
	assert_eq(int(runner.run_state.get("floors_cleared", 0)), 3, "main story should clear all floors")
	assert_eq(int(runner.run_state.get("combats_won", 0)), 3, "main story should count three wins")
	assert_eq((runner.run_state.get("nodes_visited", []) as Array).size(), 3, "main story should track three visited nodes")
	assert_eq(reward_manager.calls.size(), 3, "main story should grant rewards for all three combats")
	assert_eq(reward_generator.generated_types, ["normal", "elite", "boss"], "main story should grant rewards by battle tier")
	assert_eq(String(runner.run_state.get("current_node_id", "")), "", "main story should clear current node after ending")


func test_all_node_types_playthrough() -> void:
	var event_manager = _StubEventManager.new()
	var event_shop_battle_manager = _CaptureBattleManager.new()
	var event_shop_act := _make_act([
		[{"type": "combat", "id": "floor1_node1", "tier": "normal"}],
		[{"type": "event", "id": "floor2_node1", "event_id": "ruin_merchant"}],
		[{"type": "shop", "id": "floor3_node1"}],
	])
	var shop_runner = _make_runner({
		"battle_manager": event_shop_battle_manager,
		"event_manager": event_manager,
		"act": event_shop_act,
	})
	shop_runner.start_run({
		"starting_gold": 80,
		"battle_manager": event_shop_battle_manager,
		"event_manager": event_manager,
		"act": event_shop_act,
	})
	shop_runner.shop_manager = _StubShopManager.new(shop_runner.wallet)
	shop_runner.select_node("floor1_node1")
	shop_runner.enter_node()
	event_shop_battle_manager.battle_end_result = "victory"
	shop_runner.complete_node()
	shop_runner.select_node("floor2_node1")
	var event_enter: Dictionary = shop_runner.enter_node()
	assert_eq(String(event_enter.get("type", "")), "event", "all node types should visit an event node")
	assert_true(bool(shop_runner.resolve_event_choice("기도").get("event_resolved", false)), "all node types should resolve the event")
	shop_runner.complete_node()
	shop_runner.select_node("floor3_node1")
	var shop_enter: Dictionary = shop_runner.enter_node()
	assert_eq(String(shop_enter.get("type", "")), "shop", "all node types should visit a shop node")
	assert_true(bool(shop_runner.shop_purchase(0).get("success", false)), "all node types should allow a shop purchase")

	var treasure_reward_manager = _CaptureRewardManager.new()
	var treasure_act := _make_act([
		[{"type": "campfire", "id": "floor1_node1"}],
		[{"type": "shop", "id": "floor2_node1"}],
		[{"type": "treasure", "id": "floor3_node1"}],
	])
	var treasure_runner = _make_runner({
		"reward_manager": treasure_reward_manager,
		"act": treasure_act,
	})
	treasure_runner.start_run({"act": treasure_act})
	treasure_runner.select_node("floor1_node1")
	treasure_runner.enter_node()
	treasure_runner.complete_node()
	treasure_runner.select_node("floor2_node1")
	treasure_runner.enter_node()
	treasure_runner.complete_node()
	treasure_runner.select_node("floor3_node1")
	var treasure_enter: Dictionary = treasure_runner.enter_node()
	assert_eq(String(treasure_enter.get("type", "")), "treasure", "all node types should visit a treasure node")
	assert_true(bool(treasure_runner.complete_node().get("success", false)), "all node types should complete treasure")
	assert_eq(treasure_reward_manager.calls.size(), 1, "all node types should grant treasure rewards once")

	var boss_battle_manager = _CaptureBattleManager.new()
	var boss_act := _make_act([
		[{"type": "campfire", "id": "floor1_node1"}],
		[{"type": "event", "id": "floor2_node1", "event_id": "ruined_altar"}],
		[{"type": "boss", "id": "floor3_node1"}],
	])
	var boss_runner = _make_runner({
		"battle_manager": boss_battle_manager,
		"event_manager": _StubEventManager.new(),
		"act": boss_act,
	})
	boss_runner.start_run({"event_manager": _StubEventManager.new(), "act": boss_act})
	boss_runner.select_node("floor1_node1")
	boss_runner.enter_node()
	boss_runner.complete_node()
	boss_runner.select_node("floor2_node1")
	boss_runner.enter_node()
	boss_runner.resolve_event_choice("기도")
	boss_runner.complete_node()
	boss_runner.select_node("floor3_node1")
	assert_eq(String(boss_runner.enter_node().get("type", "")), "boss", "all node types should still cover the boss ending")
	boss_battle_manager.battle_end_result = "victory"
	assert_true(bool(boss_runner.complete_node().get("success", false)), "all node types should finish with a boss victory")
	assert_true(bool(boss_runner.run_state.get("ended", false)), "all node types should include a completed ending")


func test_defeat_ending() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"act": _act_with_single_node("combat", {"tier": "normal"}),
	})

	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	battle_manager.battle_end_result = "defeat"
	var defeat_result: Dictionary = runner.next_turn()
	assert_eq(String(defeat_result.get("battle_result", "")), "defeat", "defeat ending should surface defeat")
	assert_true(bool(runner.run_state.get("ended", false)), "defeat ending should end the run")
	assert_false(bool(runner.run_state.get("victory", true)), "defeat ending should not mark victory")
	assert_false(bool(runner.select_node("floor1_node1").get("ok", true)), "defeat ending should block further selection")
	assert_false(bool(runner.enter_node().get("ok", true)), "defeat ending should block re-entering the node")
	assert_false(bool(runner.complete_node().get("success", true)), "defeat ending should block completion")
	assert_false(bool(runner.next_turn().get("ok", true)), "defeat ending should block further turns")


func test_boss_rush() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"act": _make_act([
			[{"type": "boss", "id": "floor1_node1"}],
			[{"type": "boss", "id": "floor2_node1"}],
			[{"type": "boss", "id": "floor3_node1"}],
		]),
	})

	runner.start_run({"act": _make_act([
		[{"type": "boss", "id": "floor1_node1"}],
		[{"type": "boss", "id": "floor2_node1"}],
		[{"type": "boss", "id": "floor3_node1"}],
	])})
	runner.select_node("floor1_node1")
	assert_eq(String(runner.enter_node().get("type", "")), "boss", "boss rush should allow a floor 1 boss")
	battle_manager.battle_end_result = "victory"
	assert_true(bool(runner.complete_node().get("success", false)), "boss rush should end on the first boss")
	assert_true(bool(runner.run_state.get("ended", false)), "boss rush should end immediately")
	assert_eq((runner.run_state.get("nodes_visited", []) as Array).size(), 1, "boss rush should only visit one node")


func test_all_event_choices() -> void:
	var cases := [
		{
			"event_id": "ruined_altar",
			"context": {"visit_count": 3, "player": {"wallet": WALLET_SCRIPT.new({"gold": 50}), "hp": 100, "hp_max": 100, "mp": 40, "status_effects": []}},
			"rng": [0.25, 0.0],
			"choices": ["기도", "봉헌", "파괴", "기원"],
		},
		{
			"event_id": "ruin_merchant",
			"context": {"player": {"wallet": WALLET_SCRIPT.new({"gold": 150}), "hp": 100, "hp_max": 100, "mp": 40, "status_effects": []}},
			"rng": [0.2, 0.2],
			"choices": ["구매", "강탈", "특별 거래"],
		},
		{
			"event_id": "sealed_ward",
			"context": {"battle_wins": 3, "player": {"wallet": WALLET_SCRIPT.new({"gold": 50}), "hp": 50, "hp_max": 100, "mp": 40, "status_effects": ["poison", "burn"]}},
			"rng": [0.2],
			"choices": ["치료", "해방", "약탈", "봉인 해제"],
		},
		{
			"event_id": "moonlight_rift",
			"context": {"player": {"wallet": WALLET_SCRIPT.new({"gold": 50}), "hp": 100, "hp_max": 100, "mp": 40, "status_effects": ["freeze", "burn"]}},
			"rng": [0.2],
			"choices": ["탐사", "봉인", "수용", "균열 강화"],
		},
	]

	for case_value in cases:
		var manager = EVENT_MANAGER_SCRIPT.new({"rng": _DeterministicRng.new(case_value["rng"])})
		var event_id := String(case_value["event_id"])
		var context: Dictionary = (case_value["context"] as Dictionary).duplicate(true)
		var visible_choices: Array = manager.get_visible_choices(event_id, context)
		for choice_id in case_value["choices"]:
			assert_true(_choice_ids(visible_choices).has(choice_id), "event %s should expose choice %s" % [event_id, choice_id])
			var result: Dictionary = manager.resolve_choice(event_id, String(choice_id), context)
			assert_true(bool(result.get("event_resolved", false)), "event %s choice %s should resolve" % [event_id, choice_id])
			assert_ne(String(result.get("next_state", "pending")), "pending", "event %s choice %s should advance state" % [event_id, choice_id])
			assert_not_null(result.get("next_node", null), "event %s choice %s should produce a next node" % [event_id, choice_id])
			assert_true(bool(result.get("combat_triggered", false)) or not (result.get("reward", {}) as Dictionary).is_empty(), "event %s choice %s should produce combat or reward" % [event_id, choice_id])


func test_cannot_select_previous_floor_nodes() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"act": _playthrough_act(),
	})

	runner.start_run({"act": _playthrough_act()})
	runner.select_node("floor1_node1")
	runner.enter_node()
	battle_manager.battle_end_result = "victory"
	runner.complete_node()
	var result: Dictionary = runner.select_node("floor1_node1")
	assert_false(bool(result.get("ok", true)), "previous floor nodes should not be selectable")


func test_cannot_select_two_nodes_same_floor() -> void:
	var runner = _make_runner({"act": _playthrough_act()})
	runner.start_run({"act": _playthrough_act()})
	assert_true(bool(runner.select_node("floor1_node1").get("ok", false)), "first selection should succeed")
	var second_result: Dictionary = runner.select_node("floor1_node2")
	assert_false(bool(second_result.get("ok", true)), "second selection on the same floor should fail")
	assert_eq(String(second_result.get("error", "")), "Only one node per floor", "same-floor reselection should explain the limit")


func test_complete_node_without_entering() -> void:
	var runner = _make_runner({"act": _playthrough_act()})
	runner.start_run({"act": _playthrough_act()})
	var result: Dictionary = runner.complete_node()
	assert_false(bool(result.get("success", true)), "complete_node without a current node should fail")
	assert_eq(String(result.get("error", "")), "No current node", "complete_node without selection should report the missing node")


func test_complete_node_during_combat() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"act": _act_with_single_node("combat", {"tier": "normal"}),
	})

	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	var result: Dictionary = runner.complete_node()
	assert_false(bool(result.get("success", true)), "complete_node during combat should fail")
	assert_eq(String(result.get("error", "")), "Combat not won", "complete_node during combat should require victory")
	assert_eq((runner.run_state.get("nodes_visited", []) as Array).size(), 0, "failed completion should not mark the node visited")
	assert_false(bool(runner.current_node.visited), "failed completion should not flip the node visited flag")


func test_no_actions_after_ending() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"act": _act_with_single_node("boss"),
	})

	runner.start_run({"act": _act_with_single_node("boss")})
	runner.select_node("floor1_node1")
	runner.enter_node()
	battle_manager.battle_end_result = "victory"
	runner.complete_node()
	assert_false(bool(runner.select_node("floor1_node1").get("ok", true)), "ending should block select_node")
	assert_false(bool(runner.enter_node().get("ok", true)), "ending should block enter_node")
	assert_false(bool(runner.complete_node().get("success", true)), "ending should block complete_node")
	assert_false(bool(runner.next_turn().get("ok", true)), "ending should block next_turn")


func test_campfire_heals_party() -> void:
	var runner = _make_runner({"act": _act_with_single_node("campfire")})
	runner.start_run({"act": _act_with_single_node("campfire")})
	runner.party[0]["current_hp"] = 40
	runner.party[1]["current_hp"] = 70
	runner.party[2]["current_hp"] = 20
	runner.select_node("floor1_node1")
	runner.enter_node()
	var result: Dictionary = runner.campfire_rest()
	assert_gt(int(runner.party[0]["current_hp"]), 40, "campfire should heal the first party member")
	assert_gt(int(runner.party[1]["current_hp"]), 70, "campfire should heal the second party member")
	assert_gt(int(runner.party[2]["current_hp"]), 20, "campfire should heal the third party member")
	assert_gt(int(result.get("total_healed", 0)), 0, "campfire should report party healing")


func test_shop_purchase_reduces_gold() -> void:
	var runner = _make_runner({"act": _act_with_single_node("shop")})
	runner.start_run({"starting_gold": 50, "act": _act_with_single_node("shop")})
	runner.shop_manager = _StubShopManager.new(runner.wallet)
	runner.select_node("floor1_node1")
	runner.enter_node()
	var gold_before := int(runner.wallet.get_gold())
	var result: Dictionary = runner.shop_purchase(0)
	assert_true(bool(result.get("success", false)), "shop purchase should succeed")
	assert_true(int(runner.wallet.get_gold()) < gold_before, "shop purchase should reduce gold")
	assert_has(runner.inventory.equipment, "상점 검", "shop purchase should add the item to inventory")


func test_restart_resets_all_state() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var reward_manager = _CaptureRewardManager.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"reward_manager": reward_manager,
		"act": _playthrough_act(),
	})

	runner.start_run({"act": _playthrough_act()})
	assert_true(bool(runner.select_node("floor1_node3").get("ok", false)), "restart reset should allow a first run node selection")
	assert_eq(String(runner.enter_node().get("type", "")), "campfire", "restart reset should enter the first run campfire")
	assert_true(bool(runner.complete_node().get("success", false)), "restart reset should complete the first run campfire")
	assert_true(bool(runner.select_node("floor2_node4").get("ok", false)), "restart reset should allow the first run shop selection")
	assert_eq(String(runner.enter_node().get("type", "")), "shop", "restart reset should enter the first run shop")
	assert_true(bool(runner.complete_node().get("success", false)), "restart reset should complete the first run shop")
	assert_true(bool(runner.select_node("floor3_node3").get("ok", false)), "restart reset should allow the first run boss selection")
	assert_eq(String(runner.enter_node().get("type", "")), "boss", "restart reset should enter the first run boss")
	battle_manager.battle_end_result = "victory"
	assert_true(bool(runner.complete_node().get("success", false)), "restart reset should finish the first run")
	assert_true(bool(runner.run_state.get("ended", false)), "restart reset should end the first run")
	assert_gt((runner.run_state.get("nodes_visited", []) as Array).size(), 0, "restart reset should record visited nodes in the first run")
	assert_gt(int(runner.run_state.get("combats_won", 0)), 0, "restart reset should record combat wins in the first run")
	assert_gt(int(runner.run_state.get("gold_earned", 0)), 0, "restart reset should record gold in the first run")

	runner.start_run({"act": _act_with_single_node("campfire")})
	assert_eq(int(runner.run_state.get("current_floor", 0)), 1, "restart reset should restart at floor 1")
	assert_eq((runner.run_state.get("nodes_visited", []) as Array).size(), 0, "restart reset should clear visited nodes")
	assert_eq(int(runner.run_state.get("combats_won", 0)), 0, "restart reset should clear combat wins")
	assert_eq(int(runner.run_state.get("gold_earned", 0)), 0, "restart reset should clear earned gold")
	assert_false(bool(runner.run_state.get("ended", true)), "restart reset should clear ended state")
	assert_false(bool(runner.run_state.get("victory", true)), "restart reset should clear victory state")
	assert_null(runner.current_node, "restart reset should clear the current node")

	assert_true(bool(runner.select_node("floor1_node1").get("ok", false)), "restart reset should allow the second run selection")
	assert_eq(String(runner.enter_node().get("type", "")), "campfire", "restart reset should allow the second run node entry")
	assert_true(bool(runner.complete_node().get("success", false)), "restart reset should allow the second run node completion")
	assert_eq(int(runner.run_state.get("current_floor", 0)), 2, "restart reset should continue progressing after restart")


func test_event_triggers_combat() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var event_manager = EVENT_MANAGER_SCRIPT.new({"rng": _DeterministicRng.new([0.75, 0.0])})
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"event_manager": event_manager,
		"act": _act_with_single_node("event", {"event_id": "ruined_altar"}),
	})

	runner.start_run({"event_manager": event_manager, "act": _act_with_single_node("event", {"event_id": "ruined_altar"})})
	assert_true(bool(runner.select_node("floor1_node1").get("ok", false)), "event combat should allow selecting the event node")
	var enter_result: Dictionary = runner.enter_node()
	assert_eq(String(enter_result.get("type", "")), "event", "event combat should enter an event node")

	var choices: Array = enter_result.get("data", {}).get("choices", []) as Array
	var combat_choice_id := ""
	var combat_result: Dictionary = {}
	for choice in choices:
		var choice_id := String(choice.get("id", ""))
		var resolved: Dictionary = runner.resolve_event_choice(choice_id)
		if bool(resolved.get("combat_triggered", false)):
			combat_choice_id = choice_id
			combat_result = resolved
			break
	if combat_choice_id.is_empty():
		return

	assert_true(bool(combat_result.get("combat_triggered", false)), "event combat should report that combat was triggered")
	var combat_data: Dictionary = combat_result.get("combat", {})
	assert_false(combat_data.is_empty(), "event combat should include combat payload data")
	assert_has(combat_data, "battle_type", "event combat should include battle type")
	assert_has(combat_data, "enemy", "event combat should include an enemy id")

	runner.enter_combat(runner._get_enemy_configs_for_tier(String(combat_data.get("battle_type", "normal"))))
	assert_gt(battle_manager.enemies.size(), 0, "event combat should prepare at least one enemy")
	battle_manager.battle_end_result = "victory"
	assert_true(bool(runner.complete_node().get("success", false)), "event combat should still allow the event node to complete after the follow-up combat")
	assert_eq(int(runner.run_state.get("current_floor", 0)), 2, "event combat should still advance after completing the event node")


func test_shop_purchase_with_insufficient_gold() -> void:
	var runner = _make_runner({"act": _act_with_single_node("shop")})
	runner.start_run({"starting_gold": 0, "act": _act_with_single_node("shop")})
	runner.shop_manager = _StubShopManager.new(runner.wallet)
	assert_true(bool(runner.select_node("floor1_node1").get("ok", false)), "insufficient gold should allow selecting the shop")
	var enter_result: Dictionary = runner.enter_node()
	assert_eq(String(enter_result.get("type", "")), "shop", "insufficient gold should enter the shop")

	var items: Array = enter_result.get("data", {}).get("items", []) as Array
	assert_gt(items.size(), 0, "insufficient gold should expose at least one shop item")
	var expensive_index := 0
	var expensive_price := -1
	for index in range(items.size()):
		var item_price := int((items[index] as Dictionary).get("price", 0))
		if item_price > expensive_price:
			expensive_price = item_price
			expensive_index = index

	var equipment_before: Array = runner.inventory.equipment.duplicate(true)
	var potions_before: Dictionary = runner.inventory.potions.duplicate(true)
	var result: Dictionary = runner.shop_purchase(expensive_index)
	assert_false(bool(result.get("success", true)), "insufficient gold purchase should fail")
	assert_eq(String(result.get("reason", "")), "insufficient_gold", "insufficient gold purchase should explain the failure")
	assert_ge(int(runner.wallet.get_gold()), 0, "insufficient gold purchase should not make gold negative")
	assert_eq(runner.inventory.equipment, equipment_before, "insufficient gold purchase should not add equipment")
	assert_eq(runner.inventory.potions, potions_before, "insufficient gold purchase should not add potions")


func test_unique_enemy_combat() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var reward_generator = _FixedRewardGenerator.new()
	var reward_manager = _CaptureRewardManager.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"reward_generator": reward_generator,
		"reward_manager": reward_manager,
		"act": _playthrough_act(),
	})

	runner.start_run({"act": _playthrough_act()})
	assert_true(runner.advance_floor(), "unique combat should advance to floor 2")
	assert_true(runner.advance_floor(), "unique combat should advance to floor 3")
	assert_true(bool(runner.select_node("floor3_node2").get("ok", false)), "unique combat should select the floor 3 unique node")
	var enter_result: Dictionary = runner.enter_node()
	assert_eq(String(enter_result.get("type", "")), "unique", "unique combat should enter a unique node")
	assert_eq(String(battle_manager.enemy_configs[0].get("tier", "")), "unique", "unique combat should load unique enemies")

	battle_manager.battle_end_result = "victory"
	var complete_result: Dictionary = runner.complete_node()
	assert_true(bool(complete_result.get("success", false)), "unique combat should complete successfully")
	assert_eq(int(runner.run_state.get("combats_won", 0)), 1, "unique combat should increment combats won")
	assert_eq(reward_generator.generated_types, ["unique"], "unique combat should request unique-tier rewards")
	assert_eq(reward_manager.calls.size(), 1, "unique combat should grant rewards once")
	assert_has(runner.inventory.equipment, "reward_sword", "unique combat should grant the fixed reward item")


func test_combat_consumes_mp() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"content_data": _MpCostContentData.new(),
		"act": _act_with_single_node("combat", {"tier": "normal"}),
	})

	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	assert_true(bool(runner.select_node("floor1_node1").get("ok", false)), "mp combat should allow selecting the combat node")
	assert_eq(String(runner.enter_node().get("type", "")), "combat", "mp combat should enter combat")

	var mage_index := 2
	var initial_mp := int(runner.party[mage_index].get("current_mp", 0))
	battle_manager.turn_results = [{
		"unit": battle_manager.allies[mage_index],
		"action_allowed": true,
		"dot_damage": 0,
		"battle_result": null,
	}]
	var turn_result: Dictionary = runner.next_turn()
	assert_eq(turn_result.get("unit", null), battle_manager.allies[mage_index], "mp combat should hand the turn to the mage")
	var attack_result: Dictionary = runner.player_attack(0)
	assert_true(bool(attack_result.get("ok", false)), "mp combat should allow using the MP-costing skill")
	assert_true(int(runner.party[mage_index].get("current_mp", 0)) < initial_mp, "mp combat should reduce MP after skill use")

	runner.party[mage_index]["current_mp"] = 0
	battle_manager.allies[mage_index].current_mp = 0
	battle_manager.turn_results = [{
		"unit": battle_manager.allies[mage_index],
		"action_allowed": true,
		"dot_damage": 0,
		"battle_result": null,
	}]
	runner.next_turn()
	var insufficient_result: Dictionary = runner.player_attack(0)
	assert_false(bool(insufficient_result.get("ok", true)), "mp combat should reject the skill when MP is insufficient")
	assert_eq(String(insufficient_result.get("error", "")), "Not enough MP", "mp combat should explain the insufficient MP failure")


func test_treasure_rewards_not_duplicated() -> void:
	var reward_manager = _CaptureRewardManager.new()
	var runner = _make_runner({
		"reward_manager": reward_manager,
		"act": _act_with_single_node("treasure", {}, 3),
	})

	runner.start_run({"act": _act_with_single_node("treasure", {}, 3)})
	runner.map_manager.set_current_floor(3)
	runner.run_state["current_floor"] = 3
	runner.select_node("floor3_node1")
	var enter_result: Dictionary = runner.enter_node()
	var complete_result: Dictionary = runner.complete_node()
	assert_eq(reward_manager.calls.size(), 1, "treasure should only grant rewards once")
	assert_eq(complete_result.get("treasure", {}).get("rewards", {}), enter_result.get("data", {}).get("rewards", {}), "treasure completion should reuse the entered rewards")


func test_run_state_statistics() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var reward_manager = _CaptureRewardManager.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"reward_manager": reward_manager,
		"act": _make_act([
			[{"type": "combat", "id": "floor1_node1", "tier": "normal"}],
			[{"type": "event", "id": "floor2_node1", "event_id": "ruined_altar"}],
			[{"type": "treasure", "id": "floor3_node1"}],
		]),
	})

	runner.start_run({"act": _make_act([
		[{"type": "combat", "id": "floor1_node1", "tier": "normal"}],
		[{"type": "event", "id": "floor2_node1", "event_id": "ruined_altar"}],
		[{"type": "treasure", "id": "floor3_node1"}],
	])})
	runner.select_node("floor1_node1")
	runner.enter_node()
	battle_manager.battle_end_result = "victory"
	runner.complete_node()
	runner.select_node("floor2_node1")
	runner.enter_node()
	runner.resolve_event_choice("기도")
	runner.complete_node()
	runner.select_node("floor3_node1")
	runner.enter_node()
	runner.complete_node()
	assert_eq((runner.run_state.get("nodes_visited", []) as Array).size(), 3, "statistics should track each visited node")
	assert_eq(int(runner.run_state.get("combats_won", 0)), 1, "statistics should count combat wins only")
	assert_eq(int(runner.run_state.get("floors_cleared", 0)), 2, "statistics should count advanced floors before the final floor")
	assert_eq(int(runner.run_state.get("gold_earned", 0)), 40, "statistics should include combat and event gold")


func test_signal_order_consistency() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var tracker = _SignalOrderTracker.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"act": _make_act([
			[{"type": "combat", "id": "floor1_node1", "tier": "normal"}],
			[{"type": "boss", "id": "floor2_node1"}],
			[{"type": "campfire", "id": "floor3_node1"}],
		]),
	})

	runner.battle_state_changed.connect(tracker.on_battle)
	runner.map_state_changed.connect(tracker.on_map)
	runner.player_input_requested.connect(tracker.on_input)
	runner.message_logged.connect(tracker.on_message)
	runner.run_ended.connect(tracker.on_end)
	runner.start_run({"act": _make_act([
		[{"type": "combat", "id": "floor1_node1", "tier": "normal"}],
		[{"type": "boss", "id": "floor2_node1"}],
		[{"type": "campfire", "id": "floor3_node1"}],
	])})
	runner.select_node("floor1_node1")
	runner.enter_node()
	var ally = battle_manager.allies[0]
	battle_manager.turn_results = [{"unit": ally, "action_allowed": true, "dot_damage": 0, "battle_result": null}]
	runner.next_turn()
	battle_manager.battle_end_result = "victory"
	runner.complete_node()
	assert_eq(tracker.events[0], "map", "signal order should start from the initial map state")
	assert_true(tracker.events.find("message") < tracker.events.find("battle"), "combat should log before battle state changes")
	assert_true(tracker.events.find("battle") < tracker.events.find("input"), "battle state should precede input requests")
	assert_eq(tracker.events.count("map"), 3, "signal order should only emit map changes for start, select, and floor advance")


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


func _make_act(floor_node_specs: Array) -> Dictionary:
	var floors: Array = []
	for floor_number in [1, 2, 3]:
		var floor = FLOOR_SCRIPT.new(floor_number, {"skip_generation": true})
		floor.nodes = []
		var specs: Array = floor_node_specs[floor_number - 1] if floor_number - 1 < floor_node_specs.size() else []
		for index in range(specs.size()):
			var spec: Dictionary = specs[index]
			var node_data := {"id": String(spec.get("id", "floor%d_node%d" % [floor_number, index + 1]))}
			for key in spec:
				if key in ["type", "id"]:
					continue
				node_data[key] = spec[key]
			floor.nodes.append(NODE_SCRIPT.new(String(spec.get("type", "")), floor_number, index, node_data))
		floors.append(floor)
	return {"floors": floors, "event_catalog": []}


func _choice_ids(choices: Array) -> Array:
	var ids: Array = []
	for choice in choices:
		ids.append(String(choice.get("id", "")))
	return ids


func _find_node_by_type(nodes: Array, node_type: String):
	for node in nodes:
		if String(node.type) == node_type:
			return node
	return null
