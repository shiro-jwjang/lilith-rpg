extends "res://test/rpg/test_base.gd"

const GAME_RUNNER_SCRIPT := preload("res://scripts/rpg/game_runner.gd")
const FLOOR_SCRIPT := preload("res://scripts/rpg/map/floor.gd")
const NODE_SCRIPT := preload("res://scripts/rpg/map/node.gd")
const UNIT_SCRIPT := preload("res://scripts/rpg/combat/unit.gd")
const WALLET_SCRIPT := preload("res://scripts/rpg/economy/wallet.gd")


class _SignalTracker extends RefCounted:
	var battle_count := 0
	var map_count := 0
	var input_count := 0
	var message_count := 0
	var end_count := 0

	func on_battle(_state: Dictionary) -> void:
		battle_count += 1

	func on_map(_state: Dictionary) -> void:
		map_count += 1

	func on_input(_choices: Array) -> void:
		input_count += 1

	func on_message(_text: String) -> void:
		message_count += 1

	func on_end(_result: Dictionary) -> void:
		end_count += 1


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
		calls.append({"rewards": rewards.duplicate(true), "inventory": inventory})
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
	var last_event_id := ""
	var last_choice_id := ""

	func get_event(event_id: String) -> RefCounted:
		var EVENT_BASE = load("res://scripts/rpg/events/event_base.gd")
		var stub = EVENT_BASE.new({"event_id": event_id, "title": "테스트 이벤트"})
		return stub

	func get_visible_choices(event_id: String, _context: Dictionary) -> Array:
		last_event_id = event_id
		return choices.duplicate(true)

	func resolve_choice(event_id: String, choice_id: String, _context: Dictionary) -> Dictionary:
		last_event_id = event_id
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


class _StubEnemyAI extends RefCounted:
	func select_target(_target_type: String, allies: Array, _effect_type: String = ""):
		if allies.is_empty():
			return null
		return allies[0]


func test_init_creates_runners() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	assert_not_null(runner.battle_manager, "runner should create battle_manager")
	assert_not_null(runner.map_manager, "runner should create map_manager")
	assert_not_null(runner.inventory, "runner should create inventory")
	assert_not_null(runner.event_manager, "runner should create event_manager")
	assert_not_null(runner.reward_generator, "runner should create reward_generator")
	assert_not_null(runner.reward_manager, "runner should create reward_manager")
	assert_not_null(runner.shop_manager, "runner should create shop_manager")
	assert_not_null(runner.campfire_manager, "runner should create campfire_manager")
	assert_not_null(runner.content_data, "runner should create content_data")


func test_start_run_generates_map() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run()
	assert_eq(runner.map_manager.act.get("floors", []).size(), 3, "start_run should build three floors")
	assert_eq(runner.party.size(), 3, "start_run should create a three-member party")
	assert_eq(runner.map_manager.current_floor_number, 1, "start_run should begin on floor 1")


func test_start_run_party_state() -> void:
	var runner = GAME_RUNNER_SCRIPT.new({"content_data": _StubContentData.new()})
	runner.start_run()
	assert_eq(String(runner.party[0]["name"]), "리나", "first party member should be 리나")
	assert_eq(int(runner.party[0]["current_hp"]), 120, "리나 HP should match default config")
	assert_eq(int(runner.party[1]["current_hp"]), 150, "카이 HP should match default config")
	assert_eq(int(runner.party[2]["current_mp"]), 60, "세리아 MP should match default config")


func test_start_run_initial_gold() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run()
	assert_eq(int(runner.wallet.get_gold()), 0, "run should start at zero gold")


func test_get_available_nodes_returns_current_floor_nodes() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run()
	var nodes: Array = runner.get_available_nodes()
	assert_eq(nodes.size(), 3, "floor 1 should expose three nodes")
	assert_eq(int(nodes[0].floor_index), 1, "available nodes should belong to current floor")


func test_select_node() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run()
	var node = runner.get_available_nodes()[0]
	var result: Dictionary = runner.select_node(String(node.id))
	assert_true(bool(result.get("ok", false)), "select_node should succeed for a valid id")
	assert_eq(String(runner.current_node.id), String(node.id), "current_node should track selected node")
	assert_eq(String(result.get("node", {}).get("id", "")), String(node.id), "select_node should echo node data")


func test_select_node_invalid_id() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run()
	var result: Dictionary = runner.select_node("bad_id")
	assert_false(bool(result.get("ok", true)), "invalid node selection should fail")
	assert_has(result, "error", "invalid node result should contain an error")


func test_enter_combat_node_initializes_battle() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var content = _StubContentData.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"battle_manager": battle_manager,
		"content_data": content,
	})
	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	var select_result: Dictionary = runner.select_node("floor1_node1")
	assert_true(bool(select_result.get("ok", false)), "combat node should be selectable")
	var enter_result: Dictionary = runner.enter_node()
	assert_eq(String(enter_result.get("type", "")), "combat", "enter_node should route combat node")
	assert_eq(battle_manager.ally_configs.size(), 3, "combat init should receive party configs")
	assert_eq(battle_manager.enemy_configs.size(), 1, "combat init should receive normal enemy configs")
	assert_eq(String(battle_manager.enemy_configs[0]["name"]), "일반 적", "combat init should use content data enemy")


func test_battle_next_turn() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"battle_manager": battle_manager,
		"content_data": _StubContentData.new(),
	})
	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	var ally = battle_manager.allies[0]
	battle_manager.turn_results = [{
		"unit": ally,
		"action_allowed": true,
		"dot_damage": 0,
		"battle_result": null,
	}]
	var result: Dictionary = runner.next_turn()
	assert_not_null(result.get("unit", null), "next_turn should return a unit")
	assert_true(bool(result.get("action_allowed", false)), "ally turn should allow action")


func test_battle_victory() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"battle_manager": battle_manager,
		"content_data": _StubContentData.new(),
	})
	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	battle_manager.battle_end_result = "victory"
	var result: Dictionary = runner.next_turn()
	assert_eq(String(result.get("battle_result", "")), "victory", "victory should propagate from battle manager")


func test_battle_defeat() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"battle_manager": battle_manager,
		"content_data": _StubContentData.new(),
	})
	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	battle_manager.battle_end_result = "defeat"
	var result: Dictionary = runner.next_turn()
	assert_eq(String(result.get("battle_result", "")), "defeat", "defeat should propagate from battle manager")
	assert_true(bool(runner.run_state.get("ended", false)), "defeat should end the run")


func test_battle_enemy_auto_action() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"battle_manager": battle_manager,
		"content_data": _StubContentData.new(),
		"enemy_ai": _StubEnemyAI.new(),
	})
	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	var ally = battle_manager.allies[0]
	ally.def = 0
	var enemy = battle_manager.enemies[0]
	var hp_before := int(ally.current_hp)
	var auto_action: Dictionary = runner._execute_enemy_turn(enemy)
	assert_true(bool(auto_action.get("ok", false)), "enemy helper should execute an action")
	assert_true(int(battle_manager.allies[0].current_hp) < hp_before, "enemy action helper should damage an ally")
	ally.current_hp = ally.max_hp
	ally.alive = true
	battle_manager.turn_results = [
		{"unit": enemy, "action_allowed": true, "dot_damage": 0, "battle_result": null},
		{"unit": ally, "action_allowed": true, "dot_damage": 0, "battle_result": null},
	]
	var result: Dictionary = runner.next_turn()
	# next_turn은 한 턴씩 반환하므로 첫 번째는 적 턴
	assert_false(bool(result.get("unit", null).is_ally), "first result should be enemy turn")
	# 두 번째 호출이 아군 턴
	result = runner.next_turn()
	assert_true(bool(result.get("unit", null).is_ally), "second result should be ally turn")


func test_player_attack_enemy() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"battle_manager": battle_manager,
		"content_data": _StubContentData.new(),
	})
	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	var ally = battle_manager.allies[0]
	var enemy = battle_manager.enemies[0]
	var hp_before := int(enemy.current_hp)
	battle_manager.turn_results = [
		{"unit": ally, "action_allowed": true, "dot_damage": 0, "battle_result": null},
		{"battle_result": null},
	]
	runner.next_turn()
	var result: Dictionary = runner.player_attack(0)
	assert_true(bool(result.get("ok", false)), "player_attack should succeed on an ally turn")
	assert_true(int(enemy.current_hp) < hp_before, "player attack should reduce enemy HP")


func test_player_use_potion_in_battle() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"battle_manager": battle_manager,
		"content_data": _StubContentData.new(),
	})
	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.inventory.add_potion("소형 치료 물약")
	runner.select_node("floor1_node1")
	runner.enter_node()
	var ally = battle_manager.allies[0]
	ally.take_damage(30)
	runner.party[0]["current_hp"] = int(ally.current_hp)
	battle_manager.turn_results = [
		{"unit": ally, "action_allowed": true, "dot_damage": 0, "battle_result": null},
		{"battle_result": null},
	]
	runner.next_turn()
	var hp_before := int(runner.party[0]["current_hp"])
	var result: Dictionary = runner.player_use_potion("소형 치료 물약", 0)
	assert_true(bool(result.get("ok", false)), "player_use_potion should succeed with stock")
	assert_gt(int(runner.party[0]["current_hp"]), hp_before, "potion use should heal the ally")


func test_complete_combat_grants_rewards() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var reward_generator = _FixedRewardGenerator.new()
	var reward_manager = _CaptureRewardManager.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"battle_manager": battle_manager,
		"reward_generator": reward_generator,
		"reward_manager": reward_manager,
		"content_data": _StubContentData.new(),
	})
	runner.start_run({"act": _act_with_single_node("combat", {"tier": "elite"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	battle_manager.battle_end_result = "victory"
	var result: Dictionary = runner.complete_node()
	assert_true(bool(result.get("success", false)), "complete_node should succeed after victory")
	assert_eq(reward_manager.calls.size(), 1, "reward manager should be invoked")
	assert_eq(int(runner.wallet.get_gold()), 25, "gold rewards should be granted through wallet")


func test_enter_event_node_shows_choices() -> void:
	var event_manager = _StubEventManager.new()
	var runner = GAME_RUNNER_SCRIPT.new({"event_manager": event_manager})
	runner.start_run({"act": _act_with_single_node("event", {"event_id": "ruined_altar"})})
	runner.select_node("floor1_node1")
	var result: Dictionary = runner.enter_node()
	assert_eq(String(result.get("type", "")), "event", "event node should route to event entry")
	assert_eq((result.get("data", {}).get("choices", []) as Array).size(), 2, "event entry should return visible choices")


func test_resolve_event_choice() -> void:
	var event_manager = _StubEventManager.new()
	var reward_manager = _CaptureRewardManager.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"event_manager": event_manager,
		"reward_manager": reward_manager,
	})
	runner.start_run({"act": _act_with_single_node("event", {"event_id": "ruined_altar"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	var result: Dictionary = runner.resolve_event_choice("기도")
	assert_true(bool(result.get("event_resolved", false)), "event choice should resolve")
	assert_eq(String(event_manager.last_choice_id), "기도", "event manager should receive the selected choice")
	assert_eq(int(runner.wallet.get_gold()), 12, "event rewards should be granted")


func test_enter_shop_node() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run({"starting_gold": 50, "act": _act_with_single_node("shop")})
	runner.shop_manager = _StubShopManager.new(runner.wallet)
	runner.select_node("floor1_node1")
	var result: Dictionary = runner.enter_node()
	assert_eq(String(result.get("type", "")), "shop", "shop node should route to shop entry")
	assert_gt((result.get("data", {}).get("items", []) as Array).size(), 0, "shop entry should expose items")


func test_shop_purchase() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run({"starting_gold": 50, "act": _act_with_single_node("shop")})
	runner.shop_manager = _StubShopManager.new(runner.wallet)
	runner.select_node("floor1_node1")
	runner.enter_node()
	var gold_before := int(runner.wallet.get_gold())
	var result: Dictionary = runner.shop_purchase(0)
	assert_true(bool(result.get("success", false)), "shop purchase should succeed with enough gold")
	assert_true(int(runner.wallet.get_gold()) < gold_before, "shop purchase should spend gold")


func test_enter_campfire_node() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run({"act": _act_with_single_node("campfire")})
	runner.select_node("floor1_node1")
	var result: Dictionary = runner.enter_node()
	assert_eq(String(result.get("type", "")), "campfire", "campfire node should route correctly")
	assert_eq((result.get("data", {}).get("actions", []) as Array).size(), 3, "campfire should expose three actions")


func test_campfire_rest() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run({"act": _act_with_single_node("campfire")})
	runner.party[0]["current_hp"] = 60
	var result: Dictionary = runner.campfire_rest()
	assert_gt(int(runner.party[0]["current_hp"]), 60, "campfire rest should heal the leader")
	assert_gt(int(result.get("healed", 0)), 0, "campfire rest should report healing")


func test_campfire_invest() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run({"act": _act_with_single_node("campfire")})
	runner.wallet.add_gold(25)
	var atk_before := int(runner.party[0]["atk"])
	var result: Dictionary = runner.campfire_invest("atk")
	assert_true(bool(result.get("success", false)), "campfire invest should succeed with enough gold")
	assert_eq(int(runner.wallet.get_gold()), 0, "campfire invest should spend all 25 gold")
	assert_eq(int(runner.party[0]["atk"]), atk_before + 1, "campfire invest should increase the selected stat")


func test_advance_floor() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run()
	var success := runner.advance_floor()
	assert_true(success, "advance_floor should move from floor 1 to floor 2")
	assert_eq(runner.map_manager.current_floor_number, 2, "current floor should advance")


func test_advance_floor_final() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"battle_manager": battle_manager,
		"reward_generator": _FixedRewardGenerator.new(),
		"reward_manager": _CaptureRewardManager.new(),
		"content_data": _StubContentData.new(),
	})
	runner.start_run({"act": _act_with_single_node("boss", {}, 3)})
	runner.map_manager.set_current_floor(3)
	runner.run_state["current_floor"] = 3
	runner.select_node("floor3_node1")
	runner.enter_node()
	battle_manager.battle_end_result = "victory"
	runner.complete_node()
	assert_true(bool(runner.run_state.get("victory", false)), "boss completion should mark run victory")
	assert_true(bool(runner.run_state.get("ended", false)), "boss completion should end the run")


func test_run_state_tracking() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"battle_manager": battle_manager,
		"reward_generator": _FixedRewardGenerator.new(),
		"reward_manager": _CaptureRewardManager.new(),
		"content_data": _StubContentData.new(),
	})
	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	battle_manager.battle_end_result = "victory"
	runner.complete_node()
	assert_eq(int(runner.run_state.get("current_floor", 0)), 1, "run state should track current floor")
	assert_eq((runner.run_state.get("nodes_visited", []) as Array).size(), 1, "run state should track visited nodes")
	assert_eq(int(runner.run_state.get("combats_won", 0)), 1, "run state should track combat wins")


func test_signals() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var tracker = _SignalTracker.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"battle_manager": battle_manager,
		"reward_generator": _FixedRewardGenerator.new(),
		"reward_manager": _CaptureRewardManager.new(),
		"content_data": _StubContentData.new(),
	})
	runner.battle_state_changed.connect(tracker.on_battle)
	runner.map_state_changed.connect(tracker.on_map)
	runner.player_input_requested.connect(tracker.on_input)
	runner.message_logged.connect(tracker.on_message)
	runner.run_ended.connect(tracker.on_end)
	runner.start_run({"act": _act_with_single_node("boss", {}, 3)})
	runner.map_manager.set_current_floor(3)
	runner.run_state["current_floor"] = 3
	runner.select_node("floor3_node1")
	runner.enter_node()
	var ally = battle_manager.allies[0]
	battle_manager.turn_results = [{
		"unit": ally,
		"action_allowed": true,
		"dot_damage": 0,
		"battle_result": null,
	}]
	runner.next_turn()
	battle_manager.battle_end_result = "victory"
	runner.complete_node()
	assert_gt(tracker.battle_count, 0, "battle_state_changed should fire")
	assert_gt(tracker.map_count, 0, "map_state_changed should fire")
	assert_gt(tracker.input_count, 0, "player_input_requested should fire")
	assert_gt(tracker.message_count, 0, "message_logged should fire")
	assert_eq(tracker.end_count, 1, "run_ended should fire once on boss victory")


func test_get_party_status() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run()
	var status: Array = runner.get_party_status()
	assert_eq(status.size(), 3, "party status should return one entry per member")
	assert_has(status[0], "current_hp", "party status should include HP")
	assert_has(status[0], "current_mp", "party status should include MP")


func test_get_battle_status() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var runner = GAME_RUNNER_SCRIPT.new({
		"battle_manager": battle_manager,
		"content_data": _StubContentData.new(),
	})
	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	var status: Dictionary = runner.get_battle_status()
	assert_eq((status.get("allies", []) as Array).size(), 3, "battle status should include allies")
	assert_eq((status.get("enemies", []) as Array).size(), 1, "battle status should include enemies")
	assert_has((status.get("enemies", []) as Array)[0], "current_hp", "enemy status should include HP")


func test_get_run_summary() -> void:
	var runner = GAME_RUNNER_SCRIPT.new()
	runner.start_run()
	runner.run_state["victory"] = true
	runner.run_state["floors_cleared"] = 3
	runner.run_state["combats_won"] = 4
	runner.run_state["gold_earned"] = 90
	var summary: Dictionary = runner.get_run_summary()
	assert_true(bool(summary.get("victory", false)), "summary should expose victory")
	assert_eq(int(summary.get("floors_cleared", 0)), 3, "summary should expose floors_cleared")
	assert_eq(int(summary.get("combats_won", 0)), 4, "summary should expose combats_won")
	assert_eq(int(summary.get("gold_earned", 0)), 90, "summary should expose gold earned")


func _act_with_single_node(node_type: String, data: Dictionary = {}, floor_number: int = 1) -> Dictionary:
	var floors: Array = []
	for number in [1, 2, 3]:
		var floor = FLOOR_SCRIPT.new(number, {"skip_generation": true})
		floor.nodes = []
		if number == floor_number:
			floor.nodes.append(NODE_SCRIPT.new(node_type, number, 0, _node_data_for_floor(number, data)))
		floors.append(floor)
	return {"floors": floors, "event_catalog": []}


func _node_data_for_floor(floor_number: int, data: Dictionary) -> Dictionary:
	var result := {"id": "floor%d_node1" % floor_number}
	for key in data:
		result[key] = data[key]
	return result
