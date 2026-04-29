extends RefCounted

const BATTLE_MANAGER_SCRIPT := preload("res://scripts/rpg/combat/battle_manager.gd")
const CAMPFIRE_MANAGER_SCRIPT := preload("res://scripts/rpg/campfire/campfire_manager.gd")
const CONTENT_DATA_SCRIPT := preload("res://scripts/rpg/data/content_data.gd")
const DAMAGE_CALCULATOR_SCRIPT := preload("res://scripts/rpg/combat/damage_calculator.gd")
const ENEMY_AI_SCRIPT := preload("res://scripts/rpg/ai/enemy_ai.gd")
const EFFECT_CHANCE_CALCULATOR_SCRIPT := preload("res://scripts/rpg/status/effect_chance_calculator.gd")
const EVENT_MANAGER_SCRIPT := preload("res://scripts/rpg/events/event_manager.gd")
const INVENTORY_SCRIPT := preload("res://scripts/rpg/inventory/inventory.gd")
const MAP_MANAGER_SCRIPT := preload("res://scripts/rpg/map/map_manager.gd")
const NORMAL_AI_SCRIPT := preload("res://scripts/rpg/ai/normal_ai.gd")
const REWARD_GENERATOR_SCRIPT := preload("res://scripts/rpg/rewards/reward_generator.gd")
const REWARD_MANAGER_SCRIPT := preload("res://scripts/rpg/rewards/reward_manager.gd")
const SHOP_MANAGER_SCRIPT := preload("res://scripts/rpg/shop/shop_manager.gd")
const WALLET_SCRIPT := preload("res://scripts/rpg/economy/wallet.gd")

signal battle_state_changed(state: Dictionary)
signal map_state_changed(state: Dictionary)
signal player_input_requested(choices: Array)
signal message_logged(text: String)
signal run_ended(result: Dictionary)


func _get_run_state() -> Node:
	var main_loop = Engine.get_main_loop()
	if main_loop != null and main_loop is SceneTree:
		var run_state = main_loop.root.get_node_or_null("RunState")
		if run_state != null:
			return run_state
	return Engine.get_meta("_run_state_instance", null)


func _sync_run_state_from_dict() -> void:
	var rs = _get_run_state()
	if rs == null:
		return
	rs.victory = bool(run_state.get("victory", false))
	rs.defeat = bool(run_state.get("defeat", false))
	rs.ended = bool(run_state.get("ended", false))
	rs.current_floor = int(run_state.get("current_floor", 1))
	rs.floors_cleared = int(run_state.get("floors_cleared", 0))
	rs.nodes_visited = run_state.get("nodes_visited", []).duplicate(true)
	rs.combats_won = int(run_state.get("combats_won", 0))
	rs.gold_earned = int(run_state.get("gold_earned", 0))
	rs.current_node_id = String(run_state.get("current_node_id", ""))


func _emit_presentation(sig_name: StringName, arg) -> void:
	var bus = null
	var main_loop = Engine.get_main_loop()
	if main_loop != null and main_loop is SceneTree:
		bus = main_loop.root.get_node_or_null("EventBus")
	if bus == null:
		bus = Engine.get_meta("_event_bus_instance", null)
	if bus != null and bus.has_signal(sig_name):
		bus.emit_signal(sig_name, arg)
	emit_signal(sig_name, arg)

const PARTY_CONFIGS := [
	{"name": "리나", "hp": 120, "mp": 30, "atk": 14, "def": 8, "speed": 12, "class": "warrior"},
	{"name": "카이", "hp": 150, "mp": 20, "atk": 10, "def": 14, "speed": 8, "class": "guardian"},
	{"name": "세리아", "hp": 80, "mp": 60, "atk": 16, "def": 5, "speed": 15, "class": "mage"},
]

const PARTY_SKILL_SOURCES := {
	"warrior": "전위딜러",
	"guardian": "수호자",
	"mage": "마법지원가",
}

const STATUS_DURATIONS := {
	"출혈": 3,
	"화상": 3,
	"둔화": 2,
	"약화": 2,
	"파쇄": 2,
	"기절": 1,
}

var battle_manager = null
var map_manager = null
var inventory = null
var wallet = null
var event_manager = null
var reward_generator = null
var reward_manager = null
var shop_manager = null
var campfire_manager = null
var content_data = null
var party: Array = []
var current_node = null
var run_state: Dictionary = {}
var rng = null

var _config: Dictionary = {}
var _normal_ai = null
var _enemy_ai = null
var _current_turn = null
var _pending_taunt_expire_unit = null
var _current_battle_type: String = "normal"
var _last_shop_visit: Dictionary = {}
var _last_treasure_result: Dictionary = {}


func _init(config: Dictionary = {}) -> void:
	_config = config.duplicate(true)
	rng = _config.get("rng", null)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	wallet = _config.get("wallet", null)
	if wallet == null:
		wallet = WALLET_SCRIPT.new({"gold": int(_config.get("starting_gold", 0))})

	inventory = _config.get("inventory", null)
	if inventory == null:
		inventory = INVENTORY_SCRIPT.new({"wallet": wallet})
	else:
		if inventory.get("wallet") == null:
			inventory.wallet = wallet

	battle_manager = _config.get("battle_manager", null)
	if battle_manager == null:
		battle_manager = BATTLE_MANAGER_SCRIPT.new()

	content_data = _config.get("content_data", null)
	if content_data == null:
		content_data = CONTENT_DATA_SCRIPT.new()

	map_manager = _config.get("map_manager", null)
	if map_manager == null:
		map_manager = MAP_MANAGER_SCRIPT.new(_config.get("act", {}))

	event_manager = _config.get("event_manager", null)
	if event_manager == null:
		event_manager = EVENT_MANAGER_SCRIPT.new({"rng": rng})

	reward_generator = _config.get("reward_generator", null)
	if reward_generator == null:
		reward_generator = REWARD_GENERATOR_SCRIPT.new({"rng": rng})

	reward_manager = _config.get("reward_manager", null)
	if reward_manager == null:
		reward_manager = REWARD_MANAGER_SCRIPT.new()

	shop_manager = _config.get("shop_manager", null)
	if shop_manager == null:
		shop_manager = SHOP_MANAGER_SCRIPT.new({"wallet": wallet, "rng": rng})

	campfire_manager = _config.get("campfire_manager", null)
	if campfire_manager == null:
		campfire_manager = CAMPFIRE_MANAGER_SCRIPT.new()

	_normal_ai = _config.get("normal_ai", null)
	if _normal_ai == null:
		_normal_ai = NORMAL_AI_SCRIPT.new()

	_enemy_ai = _config.get("enemy_ai", null)
	if _enemy_ai == null:
		_enemy_ai = ENEMY_AI_SCRIPT.new()


func start_run(config: Dictionary = {}) -> void:
	if config.has("wallet"):
		wallet = config["wallet"]
	if config.has("inventory"):
		inventory = config["inventory"]
		if inventory != null:
			inventory.wallet = wallet
	if inventory == null:
		inventory = INVENTORY_SCRIPT.new({"wallet": wallet})
	else:
		inventory.wallet = wallet

	var start_gold := int(config.get("starting_gold", 0))
	wallet = WALLET_SCRIPT.new({"gold": start_gold})
	inventory = INVENTORY_SCRIPT.new({"wallet": wallet})
	_rebuild_managers_for_run(config)

	party = _build_default_party(config.get("party_configs", PARTY_CONFIGS))
	current_node = null
	_current_turn = null
	_pending_taunt_expire_unit = null
	_current_battle_type = "normal"
	_last_shop_visit = {}
	_last_treasure_result = {}

	var rs = _get_run_state()
	if rs != null:
		rs.start_new_run()

	run_state = {
		"victory": false,
		"defeat": false,
		"ended": false,
		"current_floor": 1,
		"floors_cleared": 0,
		"nodes_visited": [],
		"combats_won": 0,
		"gold_earned": 0,
		"current_node_id": "",
	}

	var act: Dictionary = config.get("act", _config.get("act", {}))
	map_manager = MAP_MANAGER_SCRIPT.new(act)
	run_state["current_floor"] = map_manager.current_floor_number
	_sync_run_state_from_dict()
	_emit_map_state()


func get_available_nodes() -> Array:
	var floor = map_manager.get_current_floor()
	if floor == null:
		return []
	return floor.nodes


func select_node(node_id: String) -> Dictionary:
	if bool(run_state.get("ended", false)):
		return {"ok": false, "error": "Run already ended"}
	var result: Dictionary = map_manager.select_node(node_id)
	if not bool(result.get("ok", false)):
		return result

	current_node = result.get("node", null)
	run_state["current_node_id"] = String(node_id)
	_sync_run_state_from_dict()
	_emit_map_state()
	return {
		"ok": true,
		"node": _node_to_dict(current_node),
	}


func enter_node() -> Dictionary:
	if bool(run_state.get("ended", false)):
		return {"ok": false, "error": "Run already ended"}
	if current_node == null:
		return {"ok": false, "error": "No node selected"}

	match String(current_node.type):
		"combat":
			var enemies := _get_enemy_configs_for_tier(String(current_node.tier))
			enter_combat(enemies)
			return {"type": "combat", "data": get_battle_status()}
		"unique":
			var unique_enemies := _get_enemy_configs_for_tier("unique")
			enter_combat(unique_enemies)
			return {"type": "unique", "data": get_battle_status()}
		"boss":
			var boss_enemy := _get_enemy_configs_for_tier("boss")
			enter_combat(boss_enemy)
			return {"type": "boss", "data": get_battle_status()}
		"event":
			return {"type": "event", "data": enter_event(String(current_node.event_id))}
		"shop":
			return {"type": "shop", "data": enter_shop()}
		"campfire":
			return {"type": "campfire", "data": enter_campfire()}
		"treasure":
			_last_treasure_result = enter_treasure()
			return {"type": "treasure", "data": _last_treasure_result}
		_:
			return {"ok": false, "error": "Unsupported node type"}


func enter_combat(enemy_configs: Array) -> void:
	_current_battle_type = _resolve_battle_type(enemy_configs)
	battle_manager.init_battle(_build_party_battle_configs(), enemy_configs)
	if battle_manager != null and battle_manager.has_method("set_boss_phase_transition_checker"):
		battle_manager.set_boss_phase_transition_checker(Callable(content_data, "should_boss_transition_phase"))
	_current_turn = null
	_pending_taunt_expire_unit = null
	_emit_presentation("battle_state_changed", get_battle_status())


func next_turn() -> Dictionary:
	if bool(run_state.get("ended", false)):
		return {"ok": false, "error": "Run already ended"}
	while true:
		var turn_result: Dictionary = battle_manager.next_turn()
		if turn_result.is_empty():
			return turn_result

		var battle_result = turn_result.get("battle_result", null)
		var acting_unit = turn_result.get("unit", null)
		if acting_unit != null and bool(acting_unit.is_ally):
			_expire_pending_taunt()
		_process_active_status_turn(acting_unit, turn_result)
		battle_result = turn_result.get("battle_result", battle_result)
		_sync_party_from_battle()

		if battle_result != null and acting_unit == null:
			_current_turn = null
			_pending_taunt_expire_unit = null
			_emit_presentation("battle_state_changed", get_battle_status())
			if battle_result == "victory":
				pass
			elif battle_result == "defeat":
				run_state["defeat"] = true
				run_state["ended"] = true
				_sync_run_state_from_dict()
				_emit_presentation("run_ended", {"victory": false, "reason": "defeat"})
			return turn_result

		if acting_unit == null:
			_emit_presentation("battle_state_changed", get_battle_status())
			return turn_result

		if battle_result != null:
			_current_turn = null
			_pending_taunt_expire_unit = null
			_emit_presentation("battle_state_changed", get_battle_status())
			if battle_result == "defeat":
				run_state["defeat"] = true
				run_state["ended"] = true
				_sync_run_state_from_dict()
				_emit_presentation("run_ended", {"victory": false, "reason": "defeat"})
			return turn_result

		if not bool(turn_result.get("action_allowed", false)) or not acting_unit.is_alive():
			_emit_presentation("battle_state_changed", get_battle_status())
			return turn_result

		if bool(acting_unit.is_ally):
			_current_turn = acting_unit
			var choices := _choices_for_unit(acting_unit)
			_emit_presentation("battle_state_changed", get_battle_status())
			_emit_presentation("player_input_requested", choices)
			return turn_result

		# 적 턴 — 한 턴만 처리하고 결과 반환
		var auto_action := _execute_enemy_turn(acting_unit)
		_sync_party_from_battle()
		var battle_end = battle_manager.check_battle_end()
		if battle_end != null:
			turn_result["battle_result"] = battle_end
			if battle_end == "defeat":
				run_state["defeat"] = true
				run_state["ended"] = true
				_sync_run_state_from_dict()
				_emit_presentation("run_ended", {"victory": false, "reason": "defeat"})
			_emit_presentation("battle_state_changed", get_battle_status())
			return turn_result
		turn_result["auto_action"] = auto_action
		_emit_presentation("battle_state_changed", get_battle_status())
		return turn_result
	return {}


func player_attack(skill_index: int) -> Dictionary:
	if _current_turn == null or not bool(_current_turn.is_ally):
		return {"ok": false, "error": "No ally turn"}

	var actor_index := _find_party_index_for_unit(_current_turn)
	if actor_index == -1:
		return {"ok": false, "error": "Unknown actor"}

	var actor: Dictionary = party[actor_index]
	var skills: Array = actor.get("skills", [])
	if skill_index < 0 or skill_index >= skills.size():
		return {"ok": false, "error": "Invalid skill index"}

	var skill: Dictionary = skills[skill_index]
	var mp_cost := int(skill.get("mp_cost", 0))
	if int(_current_turn.current_mp) < mp_cost:
		return {"ok": false, "error": "MP가 부족합니다"}
	_current_turn.use_mp(mp_cost)

	var effect := String(skill.get("effect", ""))
	match effect:
		"heal_max_hp_percent":
			var heal_target = _find_ally_needing_heal()
			if heal_target == null:
				return {"ok": false, "error": "No living ally"}
			var heal_percent := float(skill.get("value", 0.0))
			var heal_amount := int(floor(float(heal_target.max_hp) * heal_percent))
			var hp_before := int(heal_target.current_hp)
			heal_target.heal(heal_amount)
			var actual_heal := int(heal_target.current_hp) - hp_before
			return _finalize_player_action({
				"ok": true,
				"effect_type": "heal",
				"heal_amount": actual_heal,
				"target_name": String(heal_target.name),
				"skill": skill,
			})
		"def_boost":
			var actor_name := String(_current_turn.name)
			var boost_value := float(skill.get("value", 0.0))
			_current_turn.def = int(floor(float(_current_turn.def) * (1.0 + boost_value)))
			return _finalize_player_action({
				"ok": true,
				"effect_type": "buff",
				"buff_type": "def_boost",
				"target_name": actor_name,
				"skill": skill,
			})
		"taunt":
			_current_turn.apply_taunt(1)
			_pending_taunt_expire_unit = _current_turn
			return _finalize_player_action({
				"ok": true,
				"effect_type": "taunt",
				"target_name": "전체 적",
				"skill": skill,
			})
		_:
			var target = _first_living_enemy()
			if target == null:
				return {"ok": false, "error": "No living enemy"}
			var multiplier := float(skill.get("multiplier", 1.0))
			var damage := DAMAGE_CALCULATOR_SCRIPT.calculate_base_damage(_current_turn.atk, multiplier, target.def)
			target.take_damage(damage)
			var status_result := _apply_skill_statuses(_current_turn, target, skill)
			if battle_manager != null and battle_manager.has_method("check_boss_phase_transition"):
				battle_manager.check_boss_phase_transition()
			return _finalize_player_action({
				"ok": true,
				"effect_type": "damage",
				"damage": damage,
				"skill": skill,
				"target_name": String(target.name),
				"target_hp": int(target.current_hp),
				"statuses_applied": status_result.get("statuses_applied", []).duplicate(true),
				"statuses_missed": status_result.get("statuses_missed", []).duplicate(true),
			})


func player_use_potion(potion_name: String, target_index: int) -> Dictionary:
	if target_index < 0 or target_index >= party.size():
		return {"ok": false, "error": "Invalid target"}
	if _current_turn == null or not bool(_current_turn.is_ally):
		return {"ok": false, "error": "No ally turn"}

	var party_member: Dictionary = party[target_index]
	var potion_target := {
		"current_hp": int(party_member.get("current_hp", 0)),
		"max_hp": int(party_member.get("max_hp", 0)),
		"current_mp": int(party_member.get("current_mp", 0)),
		"max_mp": int(party_member.get("max_mp", 0)),
		"debuffs": (party_member.get("debuffs", []) as Array).duplicate(true),
		"temporary_effects": (party_member.get("temporary_effects", []) as Array).duplicate(true),
		"crit_rate": float(party_member.get("crit_rate", 0.0)),
		"effect_hit": float(party_member.get("effect_hit", 0.0)),
	}
	var result: Dictionary = inventory.use_potion(potion_name, potion_target)
	if not bool(result.get("success", false)):
		return result

	party_member["current_hp"] = int(potion_target.get("current_hp", party_member.get("current_hp", 0)))
	party_member["current_mp"] = int(potion_target.get("current_mp", party_member.get("current_mp", 0)))
	party_member["debuffs"] = (potion_target.get("debuffs", []) as Array).duplicate(true)
	party_member["temporary_effects"] = (potion_target.get("temporary_effects", []) as Array).duplicate(true)
	party[target_index] = party_member

	var unit_index := _find_battle_unit_index_for_party_index(target_index)
	if unit_index != -1:
		var unit = battle_manager.allies[unit_index]
		unit.current_hp = int(party_member["current_hp"])
		unit.current_mp = int(party_member["current_mp"])
		unit.alive = unit.current_hp > 0

	_current_turn = null
	var follow_up := next_turn()
	return {
		"ok": true,
		"use_result": result,
		"next_turn": follow_up,
	}


func complete_combat() -> Dictionary:
	var rewards: Dictionary = reward_generator.generate_rewards(_current_battle_type)
	var grant_result: Dictionary = reward_manager.grant_rewards(rewards, inventory)
	var gold_earned := int(rewards.get("gold", 0))
	run_state["combats_won"] = int(run_state.get("combats_won", 0)) + 1
	run_state["gold_earned"] = int(run_state.get("gold_earned", 0)) + gold_earned
	_sync_run_state_from_dict()
	return {
		"rewards": rewards,
		"grant_result": grant_result,
		"gold_earned": gold_earned,
	}


func enter_event(event_id: String) -> Dictionary:
	var event = event_manager.get_event(event_id)
	var event_title := ""
	if event != null:
		event_title = String(event.title)
	var choices: Array = event_manager.get_visible_choices(event_id, _event_context())
	_emit_presentation("player_input_requested", choices)
	return {"event_id": event_id, "title": event_title, "choices": choices}


func resolve_event_choice(choice_id: String) -> Dictionary:
	if bool(run_state.get("ended", false)):
		return {"event_resolved": false, "error": "Run already ended"}
	if current_node == null:
		return {"event_resolved": false, "error": "No current node"}
	var result: Dictionary = event_manager.resolve_choice(String(current_node.event_id), choice_id, _event_context())
	var reward: Dictionary = result.get("reward", {})
	if reward is Dictionary and not reward.is_empty():
		var rewards := _normalize_event_reward(reward, choice_id)
		if not rewards.is_empty():
			reward_manager.grant_rewards(rewards, inventory)
			run_state["gold_earned"] = int(run_state.get("gold_earned", 0)) + int(rewards.get("gold", 0))
			_sync_run_state_from_dict()
			result["granted_rewards"] = rewards
	return result


func enter_shop() -> Dictionary:
	_last_shop_visit = shop_manager.visit_shop()
	return {
		"items": _flatten_shop_items(_last_shop_visit),
		"gold": int(wallet.get_gold()),
	}


func shop_purchase(item_index: int) -> Dictionary:
	if _last_shop_visit.is_empty():
		_last_shop_visit = shop_manager.visit_shop()
	var items := _flatten_shop_items(_last_shop_visit)
	if item_index < 0 or item_index >= items.size():
		return {"success": false, "error": "Invalid item index"}
	var item: Dictionary = items[item_index]
	var result: Dictionary = shop_manager.purchase_item(item)
	if not bool(result.get("success", false)):
		return result

	var item_type := String(item.get("type", ""))
	if item_type == "equipment":
		inventory.add_equipment(String(item.get("name", "")))
	elif item_type == "relic":
		inventory.add_relic(String(item.get("id", item.get("name", ""))))
	elif item_type == "potion":
		inventory.add_potion(String(item.get("name", "")))
	return result


func enter_campfire() -> Dictionary:
	return {"actions": ["rest", "invest_atk", "invest_def"]}


func campfire_rest() -> Dictionary:
	if party.is_empty():
		return {"success": false, "error": "No party"}
	var healed_party: Array = []
	var total_healed := 0
	var leader_result: Dictionary = {}
	for index in range(party.size()):
		var member: Dictionary = party[index]
		var result: Dictionary = campfire_manager.rest({
			"hp": int(member.get("current_hp", 0)),
			"max_hp": int(member.get("max_hp", 0)),
		})
		if index == 0:
			leader_result = result
		var player_after: Dictionary = result.get("player", {})
		member["current_hp"] = int(player_after.get("hp", member.get("current_hp", 0)))
		party[index] = member
		total_healed += int(result.get("healed", 0))
		healed_party.append({
			"name": String(member.get("name", "")),
			"current_hp": int(member.get("current_hp", 0)),
			"max_hp": int(member.get("max_hp", 0)),
			"healed": int(result.get("healed", 0)),
		})
	leader_result["party"] = healed_party
	leader_result["total_healed"] = total_healed
	return leader_result


func campfire_invest(stat_name: String) -> Dictionary:
	if party.is_empty():
		return {"success": false, "error": "No party"}
	var leader: Dictionary = party[0]
	var result: Dictionary = campfire_manager.invest_stat({
		"atk": int(leader.get("atk", 0)),
		"def": int(leader.get("def", 0)),
		"speed": int(leader.get("speed", 0)),
		"wallet": wallet,
	}, stat_name)
	if bool(result.get("success", false)):
		var player_after: Dictionary = result.get("player", {})
		if player_after.has("atk"):
			leader["atk"] = int(player_after.get("atk", leader.get("atk", 0)))
		if player_after.has("def"):
			leader["def"] = int(player_after.get("def", leader.get("def", 0)))
		if player_after.has("speed"):
			leader["speed"] = int(player_after.get("speed", leader.get("speed", 0)))
		party[0] = leader
	return result


func advance_floor() -> bool:
	if map_manager.current_floor_number >= 3:
		return false
	var next_floor: int = map_manager.current_floor_number + 1
	if not map_manager.advance_to_floor(next_floor):
		return false
	run_state["floors_cleared"] = int(run_state.get("floors_cleared", 0)) + 1
	run_state["current_floor"] = map_manager.current_floor_number
	current_node = null
	run_state["current_node_id"] = ""
	_sync_run_state_from_dict()
	_last_treasure_result = {}
	_emit_map_state()
	return true


func complete_node(defer_floor_advance: bool = false) -> Dictionary:
	if bool(run_state.get("ended", false)):
		return {"success": false, "error": "Run already ended"}
	if current_node == null:
		return {"success": false, "error": "No current node"}

	var result := {"success": true, "node_id": String(current_node.id)}
	match String(current_node.type):
		"combat", "unique", "boss":
			var combat_result = battle_manager.check_battle_end()
			if combat_result != "victory":
				return {"success": false, "error": "Combat not won"}
			var rewards_result: Dictionary = complete_combat()
			result["combat"] = rewards_result
		"treasure":
			result["treasure"] = _last_treasure_result if not _last_treasure_result.is_empty() else enter_treasure()
			_last_treasure_result = {}
		_:
			pass

	current_node.visited = true
	var visited: Array = run_state.get("nodes_visited", [])
	visited.append(String(current_node.id))
	run_state["nodes_visited"] = visited
	_sync_run_state_from_dict()

	if String(current_node.type) == "boss":
		run_state["victory"] = true
		run_state["ended"] = true
		run_state["floors_cleared"] = 3
		current_node = null
		run_state["current_node_id"] = ""
		_sync_run_state_from_dict()
		_current_turn = null
		_emit_presentation("run_ended", get_run_summary())

	# 보스가 아니면 다음 층으로 이동
	if not bool(run_state.get("ended", false)):
		if defer_floor_advance:
			result["needs_advance"] = true
		else:
			advance_floor()

	run_state["current_floor"] = map_manager.current_floor_number
	_sync_run_state_from_dict()
	return result


func get_party_status() -> Array:
	var result: Array = []
	for member in party:
		result.append({
			"name": String(member.get("name", "")),
			"current_hp": int(member.get("current_hp", 0)),
			"max_hp": int(member.get("max_hp", 0)),
			"current_mp": int(member.get("current_mp", 0)),
			"max_mp": int(member.get("max_mp", 0)),
			"atk": int(member.get("atk", 0)),
			"def": int(member.get("def", 0)),
			"speed": int(member.get("speed", 0)),
			"alive": bool(member.get("current_hp", 0) > 0),
		})
	return result


func get_battle_status() -> Dictionary:
	return {
		"allies": _units_to_status_array(battle_manager.allies if battle_manager != null else []),
		"enemies": _units_to_status_array(battle_manager.enemies if battle_manager != null else []),
	}


func get_run_summary() -> Dictionary:
	return {
		"victory": bool(run_state.get("victory", false)),
		"floors_cleared": int(run_state.get("floors_cleared", 0)),
		"combats_won": int(run_state.get("combats_won", 0)),
		"gold_earned": int(run_state.get("gold_earned", 0)),
	}


func enter_treasure() -> Dictionary:
	var rewards: Dictionary = reward_generator.generate_treasure_rewards()
	var grant_result: Dictionary = reward_manager.grant_rewards(rewards, inventory)
	run_state["gold_earned"] = int(run_state.get("gold_earned", 0)) + int(rewards.get("gold", 0))
	_sync_run_state_from_dict()
	return {"rewards": rewards, "grant_result": grant_result}


func _rebuild_managers_for_run(config: Dictionary) -> void:
	var merged_act: Dictionary = config.get("act", _config.get("act", {}))
	map_manager = MAP_MANAGER_SCRIPT.new(merged_act)
	event_manager = config.get("event_manager", _config.get("event_manager", null))
	if event_manager == null:
		event_manager = EVENT_MANAGER_SCRIPT.new({"rng": rng})
	reward_generator = config.get("reward_generator", _config.get("reward_generator", null))
	if reward_generator == null:
		reward_generator = REWARD_GENERATOR_SCRIPT.new({"rng": rng})
	reward_manager = config.get("reward_manager", _config.get("reward_manager", null))
	if reward_manager == null:
		reward_manager = REWARD_MANAGER_SCRIPT.new()
	shop_manager = config.get("shop_manager", _config.get("shop_manager", null))
	if shop_manager == null:
		shop_manager = SHOP_MANAGER_SCRIPT.new({"wallet": wallet, "rng": rng})
	campfire_manager = config.get("campfire_manager", _config.get("campfire_manager", null))
	if campfire_manager == null:
		campfire_manager = CAMPFIRE_MANAGER_SCRIPT.new()
	battle_manager = config.get("battle_manager", _config.get("battle_manager", null))
	if battle_manager == null:
		battle_manager = BATTLE_MANAGER_SCRIPT.new()
	content_data = config.get("content_data", _config.get("content_data", null))
	if content_data == null:
		content_data = CONTENT_DATA_SCRIPT.new()


func _build_default_party(party_configs: Array) -> Array:
	var built: Array = []
	for config_value in party_configs:
		var class_id := String(config_value.get("class", ""))
		var skill_source: String = String(PARTY_SKILL_SOURCES.get(class_id, ""))
		built.append({
			"name": String(config_value.get("name", "")),
			"class": class_id,
			"current_hp": int(config_value.get("hp", 0)),
			"max_hp": int(config_value.get("hp", 0)),
			"current_mp": int(config_value.get("mp", 0)),
			"max_mp": int(config_value.get("mp", 0)),
			"atk": int(config_value.get("atk", 0)),
			"def": int(config_value.get("def", 0)),
			"speed": int(config_value.get("speed", 0)),
			"taunt_turns": int(config_value.get("taunt_turns", 0)),
			"skills": content_data.get_skills_for_character(skill_source),
		})
	return built


func _build_party_battle_configs() -> Array:
	var configs: Array = []
	for index in range(party.size()):
		var member: Dictionary = party[index]
		configs.append({
			"name": String(member.get("name", "")),
			"max_hp": int(member.get("max_hp", 0)),
			"current_hp": int(member.get("current_hp", 0)),
			"max_mp": int(member.get("max_mp", 0)),
			"current_mp": int(member.get("current_mp", 0)),
			"atk": int(member.get("atk", 0)),
			"def": int(member.get("def", 0)),
			"speed": int(member.get("speed", 0)),
			"taunt_turns": int(member.get("taunt_turns", 0)),
			"internal_id": index + 1,
			"skills": (member.get("skills", []) as Array).duplicate(true),
		})
	return configs


func _choices_for_unit(unit) -> Array:
	var index := _find_party_index_for_unit(unit)
	if index == -1:
		return []
	return (party[index].get("skills", []) as Array).duplicate(true)


func _execute_enemy_turn(unit) -> Dictionary:
	var skills := _build_enemy_skills(unit)
	var skill: Dictionary = _normal_ai.select_skill(skills)
	if skill.is_empty():
		skill = skills[0]
	var ally_candidates: Array = []
	for ally in battle_manager.allies:
		if not ally.is_alive():
			continue
		ally_candidates.append({
			"unit": ally,
			"internal_id": int(ally.internal_id),
			"current_hp": int(ally.current_hp),
			"max_hp": int(ally.max_hp),
			"statuses": [],
			"taunt_turns": int(ally.taunt_turns),
		})
	var target_choice = _enemy_ai.select_target(String(skill.get("target", "single")), ally_candidates, String(skill.get("effect", "")))
	var target = null
	if target_choice is Dictionary:
		target = target_choice.get("unit", null)
	if target == null:
		target = _first_living_ally()
	if target == null:
		return {"ok": false, "error": "No target"}
	var damage := DAMAGE_CALCULATOR_SCRIPT.calculate_base_damage(unit.atk, float(skill.get("multiplier", 1.0)), target.def)
	target.take_damage(damage)
	_sync_party_from_battle()
	return {
		"ok": true,
		"skill": skill,
		"damage": damage,
		"target_internal_id": int(target.internal_id),
	}


func _apply_skill_statuses(attacker, target, skill: Dictionary) -> Dictionary:
	var statuses_applied: Array = []
	var statuses_missed: Array = []
	var raw_statuses = skill.get("status_effects", [])
	if not (raw_statuses is Array):
		return {
			"statuses_applied": statuses_applied,
			"statuses_missed": statuses_missed,
		}

	for status_name in raw_statuses:
		var status_type := String(status_name)
		if status_type.is_empty():
			continue
		var hit_chance := EFFECT_CHANCE_CALCULATOR_SCRIPT.calculate_final_chance(
			float(skill.get("status_chance", 0.0)),
			float(attacker.effect_hit),
			float(target.effect_resist)
		)
		if hit_chance >= 1.0 or rng.randf() < hit_chance:
			target.apply_status(status_type, 1, _status_duration_for(status_type))
			statuses_applied.append(status_type)
		else:
			statuses_missed.append(status_type)

	return {
		"statuses_applied": statuses_applied,
		"statuses_missed": statuses_missed,
	}


func _process_active_status_turn(acting_unit, turn_result: Dictionary) -> void:
	if acting_unit == null or not acting_unit.is_alive():
		return

	var was_stunned: bool = bool(acting_unit.has_status("기절"))
	var status_result: Dictionary = acting_unit.process_turn_end_status()
	var tick_damage := int(status_result.get("tick_damage", 0))
	turn_result["status_result"] = status_result
	turn_result["dot_damage"] = int(turn_result.get("dot_damage", 0)) + tick_damage

	if was_stunned:
		turn_result["action_allowed"] = false
		turn_result["status_skipped"] = true

	if not acting_unit.is_alive():
		turn_result["action_allowed"] = false
		if battle_manager != null and battle_manager.has_method("check_battle_end"):
			turn_result["battle_result"] = battle_manager.check_battle_end()


func _status_duration_for(status_type: String) -> int:
	return int(STATUS_DURATIONS.get(status_type, 2))


func _build_enemy_skills(unit) -> Array:
	var status_names: Array = []
	var effect_data = unit.status_effects
	if effect_data is Dictionary:
		status_names = effect_data.get("enemy_status_names", [])
	var skills := [{
		"name": "basic_attack",
		"type": "basic_attack",
		"multiplier": 1.0,
		"target": "single",
		"condition_met": true,
	}]
	if status_names.size() > 0:
		skills.append({
			"name": "status_attack",
			"type": "status_effect",
			"multiplier": 1.2,
			"target": "single",
			"effect": String(status_names[0]),
			"condition_met": true,
		})
	return skills


func _sync_party_from_battle() -> void:
	if battle_manager == null:
		return
	for index in range(mini(party.size(), battle_manager.allies.size())):
		var member: Dictionary = party[index]
		var unit = battle_manager.allies[index]
		member["current_hp"] = int(unit.current_hp)
		member["current_mp"] = int(unit.current_mp)
		member["taunt_turns"] = int(unit.taunt_turns)
		party[index] = member


func _find_party_index_for_unit(unit) -> int:
	for index in range(battle_manager.allies.size()):
		if battle_manager.allies[index] == unit:
			return index
	return -1


func _find_battle_unit_index_for_party_index(index: int) -> int:
	if battle_manager == null or index < 0 or index >= battle_manager.allies.size():
		return -1
	return index


func _first_living_enemy():
	if battle_manager == null:
		return null
	for enemy in battle_manager.enemies:
		if enemy.is_alive():
			return enemy
	return null


func _first_living_ally():
	if battle_manager == null:
		return null
	for ally in battle_manager.allies:
		if ally.is_alive():
			return ally
	return null


func _find_ally_needing_heal():
	if battle_manager == null:
		return null
	var selected = null
	var lowest_ratio := 2.0
	for ally in battle_manager.allies:
		if not ally.is_alive():
			continue
		var ratio := 1.0
		if int(ally.max_hp) > 0:
			ratio = float(ally.current_hp) / float(ally.max_hp)
		if selected == null or ratio < lowest_ratio:
			selected = ally
			lowest_ratio = ratio
	return selected


func _finalize_player_action(result: Dictionary) -> Dictionary:
	_sync_party_from_battle()
	_current_turn = null
	var follow_up := next_turn()
	var finalized := result.duplicate(true)
	finalized["next_turn"] = follow_up
	return finalized


func _get_enemy_configs_for_tier(tier: String) -> Array:
	match tier:
		"elite":
			return _normalize_enemy_array(content_data.get_elite_enemies())
		"boss":
			return [ _normalize_enemy_config(content_data.get_boss()) ]
		"unique":
			return _normalize_enemy_array(content_data.get_unique_enemies())
		_:
			var pool = content_data.get_normal_enemies()
			var count = rng.randi_range(2, 4)
			return _random_pick_enemies(pool, count)


func _random_pick_enemies(pool: Array, count: int) -> Array:
	if pool.is_empty():
		return []
	var shuffled := _shuffle_with_rng(pool)
	var picked_count := mini(count, shuffled.size())
	var result: Array = []
	for i in range(picked_count):
		result.append(_normalize_enemy_config(shuffled[i]))
	return result


func _shuffle_with_rng(pool: Array) -> Array:
	var shuffled := pool.duplicate(true)
	for index in range(shuffled.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var value = shuffled[index]
		shuffled[index] = shuffled[swap_index]
		shuffled[swap_index] = value
	return shuffled


func _normalize_enemy_array(source: Array) -> Array:
	var result: Array = []
	for enemy in source:
		result.append(_normalize_enemy_config(enemy))
	return result


func _normalize_enemy_config(enemy: Dictionary) -> Dictionary:
	var max_hp := int(enemy.get("max_hp", enemy.get("hp", 0)))
	var phase_transition_hp := int(enemy.get("phase_transition_hp", 0))
	if String(enemy.get("tier", "normal")) == "boss" and phase_transition_hp <= 0:
		phase_transition_hp = max_hp / 2
	return {
		"name": String(enemy.get("name", "")),
		"max_hp": max_hp,
		"current_hp": max_hp,
		"max_mp": int(enemy.get("max_mp", enemy.get("mp", 0))),
		"current_mp": int(enemy.get("max_mp", enemy.get("mp", 0))),
		"atk": int(enemy.get("atk", enemy.get("attack", 0))),
		"def": int(enemy.get("def", enemy.get("defense", 0))),
		"speed": int(enemy.get("speed", 0)),
		"tier": String(enemy.get("tier", "normal")),
		"phases": int(enemy.get("phases", 1)),
		"phase_transition_hp": phase_transition_hp,
		"skills": (enemy.get("skills", []) as Array).duplicate(true),
		"status_effects": {"enemy_status_names": (enemy.get("status_effects", []) as Array).duplicate(true)},
	}


func _resolve_battle_type(enemy_configs: Array) -> String:
	if current_node != null and String(current_node.type) == "boss":
		return "boss"
	if current_node != null and String(current_node.type) == "unique":
		return "unique"
	for enemy in enemy_configs:
		var tier := String(enemy.get("tier", "normal"))
		if tier == "boss":
			return "boss"
		if tier == "unique":
			return "unique"
		if tier == "elite":
			return "elite"
	return "normal"


func _event_context() -> Dictionary:
	return {
		"current_node": current_node,
		"player": {
			"wallet": wallet,
			"hp": int(party[0].get("current_hp", 0)) if party.size() > 0 else 0,
			"max_hp": int(party[0].get("max_hp", 0)) if party.size() > 0 else 0,
			"status_effects": [],
		},
		"inventory": inventory,
	}


func _normalize_event_reward(reward: Dictionary, choice_id: String) -> Dictionary:
	if reward.has("gold") or reward.has("items") or reward.has("relics"):
		return {
			"gold": int(reward.get("gold", 0)),
			"items": (reward.get("items", []) as Array).duplicate(true),
			"relics": (reward.get("relics", []) as Array).duplicate(true),
		}

	var reward_type := String(reward.get("type", ""))
	match reward_type:
		"gold":
			return {"gold": int(reward.get("amount", 0)), "items": [], "relics": []}
		"equipment":
			return {"gold": 0, "items": [{"category": "equipment", "id": String(reward.get("id", "event_equipment"))}], "relics": []}
		"relic_candidate":
			return reward_generator.generate_event_reward(choice_id)
		_:
			return {}


func _flatten_shop_items(visit: Dictionary) -> Array:
	var items: Array = []
	items.append_array((visit.get("equipment_list", []) as Array).duplicate(true))
	items.append_array((visit.get("relic_list", []) as Array).duplicate(true))
	items.append_array((visit.get("potion_list", []) as Array).duplicate(true))
	return items


func _node_to_dict(node) -> Dictionary:
	if node == null:
		return {}
	return {
		"id": String(node.id),
		"type": String(node.type),
		"floor_index": int(node.floor_index),
		"position": int(node.position),
		"visited": bool(node.visited),
		"tier": String(node.tier),
		"event_id": String(node.event_id),
	}


func _units_to_status_array(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		result.append({
			"internal_id": int(unit.internal_id),
			"name": String(unit.name),
			"is_ally": bool(unit.is_ally),
			"current_hp": int(unit.current_hp),
			"max_hp": int(unit.max_hp),
			"current_mp": int(unit.current_mp),
			"max_mp": int(unit.max_mp),
			"atk": int(unit.atk),
			"def": int(unit.def),
			"speed": int(unit.speed),
			"taunt_turns": int(unit.taunt_turns),
			"alive": bool(unit.is_alive()),
		})
	return result


func _expire_pending_taunt() -> void:
	if _pending_taunt_expire_unit == null:
		return
	if is_instance_valid(_pending_taunt_expire_unit):
		_pending_taunt_expire_unit.decrement_taunt()
	_pending_taunt_expire_unit = null


func _emit_map_state() -> void:
	_emit_presentation("map_state_changed", _map_state())


func _map_state() -> Dictionary:
	return {
		"current_floor": int(map_manager.current_floor_number),
		"current_node_id": String(run_state.get("current_node_id", "")),
		"available_nodes": get_available_nodes(),
		"run_state": run_state.duplicate(true),
	}
