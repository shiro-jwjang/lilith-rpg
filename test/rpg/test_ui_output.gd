extends "res://test/rpg/test_base.gd"

const GAME_RUNNER_SCRIPT := preload("res://scripts/rpg/game_runner.gd")
const FLOOR_SCRIPT := preload("res://scripts/rpg/map/floor.gd")
const NODE_SCRIPT := preload("res://scripts/rpg/map/node.gd")
const UNIT_SCRIPT := preload("res://scripts/rpg/combat/unit.gd")


class _DeterministicRng extends RefCounted:
	func randf() -> float:
		return 0.0

	func randi_range(min_value: int, _max_value: int) -> int:
		return min_value


class _MessageLogCapture extends RefCounted:
	var messages: Array = []
	var battle_states: Array = []
	var map_states: Array = []

	func on_message(text: String) -> void:
		messages.append(text)

	func on_battle(state: Dictionary) -> void:
		battle_states.append(state.duplicate(true))

	func on_map(state: Dictionary) -> void:
		map_states.append(state.duplicate(true))
		messages.append("[color=yellow]═══ %d층 ═══[/color]" % int(state.get("current_floor", 1)))

	func has_text(needle: String) -> bool:
		for msg in messages:
			if String(msg).find(needle) >= 0:
				return true
		return false

	func count_text(needle: String) -> int:
		var count := 0
		for msg in messages:
			if String(msg).find(needle) >= 0:
				count += 1
		return count

	func clear() -> void:
		messages.clear()
		battle_states.clear()
		map_states.clear()


class _StubContentData extends RefCounted:
	var normal_enemies: Array
	var elite_enemies: Array
	var unique_enemies: Array
	var boss_enemy: Dictionary
	var skill_map: Dictionary

	func _init() -> void:
		normal_enemies = [_enemy_template("일반 적", "normal", 40, 10, 4, 9, [])]
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
	func generate_rewards(_battle_type: String) -> Dictionary:
		return {"gold": 25, "items": [], "relics": []}

	func generate_treasure_rewards() -> Dictionary:
		return {"gold": 0, "items": [], "relics": []}

	func generate_event_reward(_choice: String) -> Dictionary:
		return {"gold": 15, "items": [], "relics": []}


class _CaptureRewardManager extends RefCounted:
	var calls: Array = []

	func grant_rewards(rewards: Dictionary, inventory) -> Dictionary:
		calls.append(rewards.duplicate(true))
		if rewards.has("gold"):
			inventory.wallet.add_gold(int(rewards.get("gold", 0)))
		return {"granted": rewards}


class _StubEventManager extends RefCounted:
	var last_choice_id: String = ""

	func get_event(_event_id: String, _context: Dictionary = {}) -> Dictionary:
		return {
			"title": "테스트 이벤트",
			"choices": [
				{"id": "기도", "label": "기도하기", "effects": {"gold": 10}},
				{"id": "무시", "label": "무시하기", "effects": {}},
			],
		}

	func get_visible_choices(_event_id: String, _context: Dictionary = {}) -> Array:
		return [
			{"id": "기도", "label": "기도하기", "effects": {"gold": 10}},
			{"id": "무시", "label": "무시하기", "effects": {}},
		]

	func resolve_choice(_event_id: String, choice_id: String, _context: Dictionary) -> Dictionary:
		last_choice_id = choice_id
		return {
			"event_resolved": true,
			"choice_id": choice_id,
			"granted_rewards": {"gold": 15, "items": [], "relics": []},
			"combat_triggered": false,
		}


func test_no_raw_english_in_messages() -> void:
	var battle_manager = _CaptureBattleManager.new()
	var capture = _MessageLogCapture.new()
	var runner = _make_runner({
		"battle_manager": battle_manager,
		"content_data": _MpCostContentData.new(),
		"rng": _DeterministicRng.new(),
		"act": _act_with_single_node("combat", {"tier": "normal"}),
	})

	runner.message_logged.connect(capture.on_message)
	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.select_node("floor1_node1")
	runner.enter_node()

	assert_false(capture.has_text("Combat started"), "ui output should not contain raw English combat intro text")

	var mage = battle_manager.allies[2]
	mage.current_mp = 0
	battle_manager.turn_results = [{
		"unit": mage,
		"action_allowed": true,
		"dot_damage": 0,
		"battle_result": null,
	}]
	var turn_result: Dictionary = runner.next_turn()
	assert_eq(turn_result.get("unit"), mage, "insufficient MP test should advance to the mage turn")

	var attack_result: Dictionary = runner.player_attack(0)
	assert_false(bool(attack_result.get("ok", true)), "insufficient MP should reject the player action")
	assert_eq(String(attack_result.get("error", "")), "MP가 부족합니다", "insufficient MP should use localized Korean text")
	assert_true(String(attack_result.get("error", "")).find("Not enough MP") == -1, "insufficient MP error should not contain raw English text")
	assert_false(capture.has_text("Not enough MP"), "logged UI messages should not contain raw English MP error text")


func test_no_duplicate_map_on_floor_advance() -> void:
	var capture = _MessageLogCapture.new()
	var runner = _make_runner({
		"event_manager": _StubEventManager.new(),
		"act": _act_with_single_node("event", {"event_id": "test_event"}),
	})

	runner.message_logged.connect(capture.on_message)
	runner.map_state_changed.connect(capture.on_map)
	runner.start_run({"act": _act_with_single_node("event", {"event_id": "test_event"})})
	runner.select_node("floor1_node1")
	runner.enter_node()
	var resolve_result: Dictionary = runner.resolve_event_choice("기도")
	assert_true(bool(resolve_result.get("event_resolved", false)), "event node should resolve before completion")

	capture.clear()
	var complete_result: Dictionary = runner.complete_node()
	assert_true(bool(complete_result.get("success", false)), "event node should complete successfully")
	assert_eq(capture.count_text("═══"), 1, "floor advance should append the next floor header exactly once")
	assert_eq(capture.map_states.size(), 1, "floor advance should emit exactly one map state change")


func test_no_duplicate_battle_intro() -> void:
	var capture = _MessageLogCapture.new()
	var runner = _make_runner({
		"battle_manager": _CaptureBattleManager.new(),
		"rng": _DeterministicRng.new(),
		"act": _act_with_single_node("combat", {"tier": "normal"}),
	})

	runner.message_logged.connect(capture.on_message)
	runner.battle_state_changed.connect(capture.on_battle)
	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.select_node("floor1_node1")

	capture.clear()
	var enter_result: Dictionary = runner.enter_node()
	assert_eq(String(enter_result.get("type", "")), "combat", "combat node should enter combat")
	assert_eq(capture.count_text("전투가 시작되었다"), 0, "combat intro message should not be emitted from game_runner (UI handles it)")
	assert_eq(capture.count_text("전투 승리"), 0, "victory message should not be emitted from game_runner (UI handles it)")
	assert_eq(capture.battle_states.size(), 1, "enter_combat should emit battle_state_changed exactly once")


func test_dead_ally_not_targeted() -> void:
	var runner = _make_runner({
		"rng": _DeterministicRng.new(),
		"act": _act_with_single_node("combat", {"tier": "normal"}),
	})

	runner.start_run({"act": _act_with_single_node("combat", {"tier": "normal"})})
	runner.select_node("floor1_node1")
	runner.enter_node()

	var dead_ally = runner.battle_manager.allies[1]
	dead_ally.take_damage(999)
	var dead_internal_id := int(dead_ally.internal_id)

	var seen_targets: Array = []
	for _index in range(12):
		var turn_result: Dictionary = runner.next_turn()
		var auto_action = turn_result.get("auto_action", null)
		if auto_action is Dictionary and not auto_action.is_empty():
			var target_internal_id := int(auto_action.get("target_internal_id", -1))
			seen_targets.append(target_internal_id)
			assert_ne(target_internal_id, dead_internal_id, "enemy auto actions should never target a dead ally")
		if turn_result.get("battle_result", null) != null:
			break

	assert_gt(seen_targets.size(), 0, "dead ally targeting regression test should observe at least one enemy auto action")


func _make_runner(config: Dictionary) -> RefCounted:
	var merged := {
		"content_data": _StubContentData.new(),
		"reward_generator": _FixedRewardGenerator.new(),
		"reward_manager": _CaptureRewardManager.new(),
	}
	for key in config:
		merged[key] = config[key]
	return GAME_RUNNER_SCRIPT.new(merged)


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
