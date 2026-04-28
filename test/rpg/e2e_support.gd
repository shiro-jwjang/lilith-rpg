extends "res://test/rpg/test_base.gd"

const BATTLE_MANAGER_PATH := "res://scripts/rpg/combat/battle_manager.gd"
const CAMPFIRE_MANAGER_PATH := "res://scripts/rpg/campfire/campfire_manager.gd"
const CONTENT_DATA_PATH := "res://scripts/rpg/data/content_data.gd"
const DAMAGE_CALCULATOR_PATH := "res://scripts/rpg/combat/damage_calculator.gd"
const EQUIPMENT_INSTANCE_PATH := "res://scripts/rpg/equipment/equipment_instance.gd"
const EQUIPMENT_MANAGER_PATH := "res://scripts/rpg/equipment/equipment_manager.gd"
const EVENT_MANAGER_PATH := "res://scripts/rpg/events/event_manager.gd"
const INVENTORY_PATH := "res://scripts/rpg/inventory/inventory.gd"
const MAP_GENERATOR_PATH := "res://scripts/rpg/map/map_generator.gd"
const MAP_MANAGER_PATH := "res://scripts/rpg/map/map_manager.gd"
const MAP_PIPELINE_PATH := "res://scripts/rpg/map/map_pipeline.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"
const POTION_REGISTRY_PATH := "res://scripts/rpg/inventory/potion_registry.gd"
const REWARD_GENERATOR_PATH := "res://scripts/rpg/rewards/reward_generator.gd"
const REWARD_MANAGER_PATH := "res://scripts/rpg/rewards/reward_manager.gd"
const RELIC_MANAGER_PATH := "res://scripts/rpg/relics/relic_manager.gd"
const SHOP_MANAGER_PATH := "res://scripts/rpg/shop/shop_manager.gd"


func _generate_act(config: Dictionary = {}) -> Dictionary:
	var script = load(MAP_GENERATOR_PATH)
	assert_not_null(script, "expected map_generator.gd to exist")
	if script == null:
		return {}
	return script.new(config).generate_act()


func _make_map_manager(act: Dictionary):
	var script = load(MAP_MANAGER_PATH)
	assert_not_null(script, "expected map_manager.gd to exist")
	if script == null:
		return null
	return script.new(act)


func _make_map_pipeline(manager):
	var script = load(MAP_PIPELINE_PATH)
	assert_not_null(script, "expected map_pipeline.gd to exist")
	if script == null:
		return null
	return script.new(manager)


func _battle_manager():
	var script = load(BATTLE_MANAGER_PATH)
	assert_not_null(script, "expected battle_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _campfire_manager(config: Dictionary = {}):
	var script = load(CAMPFIRE_MANAGER_PATH)
	assert_not_null(script, "expected campfire_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _content():
	var script = load(CONTENT_DATA_PATH)
	assert_not_null(script, "expected content_data.gd to exist")
	if script == null:
		return null
	return script.new()


func _damage_calculator():
	var script = load(DAMAGE_CALCULATOR_PATH)
	assert_not_null(script, "expected damage_calculator.gd to exist")
	return script


func _equipment_manager(config: Dictionary = {}):
	var script = load(EQUIPMENT_MANAGER_PATH)
	assert_not_null(script, "expected equipment_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _event_manager(config: Dictionary = {}):
	var script = load(EVENT_MANAGER_PATH)
	assert_not_null(script, "expected event_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _reward_generator(config: Dictionary = {}):
	var script = load(REWARD_GENERATOR_PATH)
	assert_not_null(script, "expected reward_generator.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _reward_manager(config: Dictionary = {}):
	var script = load(REWARD_MANAGER_PATH)
	assert_not_null(script, "expected reward_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _relic_manager(config: Dictionary = {}):
	var script = load(RELIC_MANAGER_PATH)
	assert_not_null(script, "expected relic_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _shop_manager(config: Dictionary = {}):
	var script = load(SHOP_MANAGER_PATH)
	assert_not_null(script, "expected shop_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _equipment_item(item_name: String, upgrade_level := 0):
	var script = load(EQUIPMENT_INSTANCE_PATH)
	assert_not_null(script, "expected equipment_instance.gd to exist")
	if script == null:
		return null
	return script.new(item_name, upgrade_level)


func _make_player(overrides: Dictionary = {}) -> Dictionary:
	var starting_gold := int(overrides.get("gold", 80))
	var wallet = _make_wallet(starting_gold)
	var player := {
		"hp": 60.0,
		"max_hp": 100.0,
		"hp_max": 100.0,
		"mp": 30.0,
		"max_mp": 50.0,
		"mp_max": 50.0,
		"wallet": wallet,
		"strength": 6,
		"defense": 8,
		"speed": 12,
		"visit_count": 0,
		"battle_wins": 0,
	}
	for key in overrides:
		if key == "gold":
			continue
		player[key] = overrides[key]
	_sync_player_aliases(player)
	return player


func _sync_player_aliases(player: Dictionary) -> void:
	player["hp"] = float(player.get("hp", player.get("max_hp", 0.0)))
	player["max_hp"] = float(player.get("max_hp", player.get("hp", 0.0)))
	player["hp_max"] = float(player.get("max_hp", player.get("hp_max", 0.0)))
	player["mp"] = float(player.get("mp", player.get("max_mp", 0.0)))
	player["max_mp"] = float(player.get("max_mp", player.get("mp", 0.0)))
	player["mp_max"] = float(player.get("max_mp", player.get("mp_max", 0.0)))


func _make_wallet(gold: int = 0):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})


func _build_allies_from_player(player: Dictionary) -> Array:
	return [
		{
			"internal_id": 1,
			"current_hp": int(player.get("hp", 0.0)),
			"max_hp": int(player.get("max_hp", 0.0)),
			"current_mp": int(player.get("mp", 0.0)),
			"max_mp": int(player.get("max_mp", 0.0)),
			"atk": 12 + int(player.get("strength", 0)),
			"def": int(player.get("defense", 0)),
			"speed": int(player.get("speed", 0)),
			"status_effects": {
				"role": "front",
				"skill_name": "돌진베기",
			},
		},
		{
			"internal_id": 2,
			"current_hp": max(1, int(player.get("hp", 0.0)) - 10),
			"max_hp": max(1, int(player.get("max_hp", 0.0)) - 10),
			"current_mp": 18,
			"max_mp": 18,
			"atk": 14,
			"def": int(player.get("defense", 0)) + 4,
			"speed": max(1, int(player.get("speed", 0)) - 2),
			"status_effects": {
				"role": "guardian",
				"skill_name": "기본공격",
			},
		},
		{
			"internal_id": 3,
			"current_hp": max(1, int(player.get("hp", 0.0)) - 15),
			"max_hp": max(1, int(player.get("max_hp", 0.0)) - 15),
			"current_mp": 24,
			"max_mp": 24,
			"atk": 16,
			"def": max(1, int(player.get("defense", 0)) - 1),
			"speed": max(1, int(player.get("speed", 0)) - 1),
			"status_effects": {
				"role": "support",
				"skill_name": "화염",
			},
		},
	]


func _enemy_config(enemy_data: Dictionary, internal_id: int) -> Dictionary:
	return {
		"internal_id": internal_id,
		"current_hp": int(enemy_data.get("max_hp", 0)),
		"max_hp": int(enemy_data.get("max_hp", 0)),
		"current_mp": 0,
		"max_mp": 0,
		"atk": int(enemy_data.get("attack", 0)),
		"def": int(enemy_data.get("defense", 0)),
		"speed": int(enemy_data.get("speed", 0)),
		"tier": String(enemy_data.get("tier", "normal")),
		"status_effects": {
			"enemy_status_names": (enemy_data.get("status_effects", []) as Array).duplicate(true),
		},
	}


func _run_battle(allies: Array, enemies: Array) -> Dictionary:
	var battle_manager = _battle_manager()
	var damage_calculator = _damage_calculator()
	var content = _content()
	if battle_manager == null or damage_calculator == null or content == null:
		return {}

	battle_manager.init_battle(allies, enemies)
	var winner = battle_manager.check_battle_end()
	var turns := 0
	var status_applied_count := 0
	var dot_observed := false
	var hp_after_direct_hit := -1
	var hp_after_dot := -1
	var last_direct_hp_by_ally: Dictionary = {}

	while winner == null and turns < 200:
		var turn_result: Dictionary = battle_manager.next_turn()
		turns += 1
		var acting_unit = turn_result.get("unit", null)
		if acting_unit == null or not bool(turn_result.get("action_allowed", false)) or not acting_unit.is_alive():
			winner = battle_manager.check_battle_end()
			continue

		if bool(acting_unit.is_ally):
			if int(turn_result.get("dot_damage", 0)) > 0 and last_direct_hp_by_ally.has(acting_unit.internal_id):
				dot_observed = true
				hp_after_dot = int(acting_unit.current_hp)
			var enemy_target = _first_living_unit(battle_manager.enemies)
			if enemy_target != null:
				var role_name := _role_name_for_unit(acting_unit)
				var skill_name := _skill_name_for_unit(acting_unit)
				var skill: Dictionary = content.get_skill(role_name, skill_name)
				var multiplier := float(skill.get("multiplier", 1.0))
				var damage: int = damage_calculator.calculate_base_damage(int(acting_unit.atk), multiplier, int(enemy_target.def))
				enemy_target.take_damage(damage)
		else:
			var ally_target = _highest_hp_ally(battle_manager.allies)
			if ally_target != null:
				var incoming: int = damage_calculator.calculate_base_damage(int(acting_unit.atk), 1.0, int(ally_target.def))
				ally_target.take_damage(incoming)
				hp_after_direct_hit = int(ally_target.current_hp)
				last_direct_hp_by_ally[ally_target.internal_id] = hp_after_direct_hit
				status_applied_count += _apply_enemy_statuses(acting_unit, ally_target)

		winner = battle_manager.check_battle_end()

	return {
		"winner": winner if winner != null else "",
		"turns": turns,
		"status_applied_count": status_applied_count,
		"dot_observed": dot_observed,
		"hp_after_direct_hit": hp_after_direct_hit,
		"hp_after_dot": hp_after_dot,
		"front_ally_final_hp": _front_ally_final_hp(battle_manager.allies),
		"remaining_allies": _count_living_units(battle_manager.allies),
		"remaining_enemies": _count_living_units(battle_manager.enemies),
	}


func _front_ally_final_hp(allies: Array) -> int:
	for ally in allies:
		if int(ally.internal_id) == 1:
			return int(ally.current_hp)
	return -1


func _apply_enemy_statuses(enemy_unit, ally_unit) -> int:
	var applied := 0
	var statuses: Array = enemy_unit.status_effects.get("enemy_status_names", [])
	for status_name in statuses:
		var normalized := String(status_name)
		if normalized == "출혈":
			ally_unit.status_effects["bleed"] = {"stacks": 1, "remaining_turns": 3}
			applied += 1
		elif normalized == "화상":
			ally_unit.status_effects["burn"] = {"stacks": 1, "remaining_turns": 3}
			applied += 1
	return applied


func _role_name_for_unit(unit) -> String:
	var role := String(unit.status_effects.get("role", ""))
	if role == "guardian":
		return "수호자"
	if role == "support":
		return "마법지원가"
	return "전위딜러"


func _skill_name_for_unit(unit) -> String:
	return String(unit.status_effects.get("skill_name", "기본공격"))


func _highest_hp_ally(allies: Array):
	var best = null
	for ally in allies:
		if not ally.is_alive():
			continue
		if best == null or int(ally.current_hp) > int(best.current_hp):
			best = ally
	return best


func _first_living_unit(units: Array):
	for unit in units:
		if unit.is_alive():
			return unit
	return null


func _count_living_units(units: Array) -> int:
	var count := 0
	for unit in units:
		if unit.is_alive():
			count += 1
	return count


func _event_context(event_id: String, player: Dictionary) -> Dictionary:
	_sync_player_aliases(player)
	return {
		"current_node": {"id": "event_node_%s" % event_id, "type": "event", "event_id": event_id},
		"player": {
			"hp_max": float(player.get("hp_max", 0.0)),
			"hp": float(player.get("hp", 0.0)),
			"mp_max": float(player.get("mp_max", 0.0)),
			"mp": float(player.get("mp", 0.0)),
			"wallet": player.get("wallet", null),
			"status_effects": (player.get("status_effects", []) as Array).duplicate(true),
		},
		"visit_count": int(player.get("visit_count", 0)),
		"battle_wins": int(player.get("battle_wins", 0)),
	}


func _apply_event_result_to_player(player: Dictionary, result: Dictionary) -> void:
	var event_player: Dictionary = result.get("player", {})
	player["hp"] = float(event_player.get("hp", player.get("hp", 0.0)))
	player["hp_max"] = float(event_player.get("hp_max", player.get("hp_max", player.get("max_hp", 0.0))))
	player["max_hp"] = float(player.get("hp_max", player.get("max_hp", 0.0)))
	player["mp"] = float(event_player.get("mp", player.get("mp", 0.0)))
	player["mp_max"] = float(event_player.get("mp_max", player.get("mp_max", player.get("max_mp", 0.0))))
	player["max_mp"] = float(player.get("mp_max", player.get("max_mp", 0.0)))
	player["wallet"] = event_player.get("wallet", player.get("wallet", null))
	player["status_effects"] = (event_player.get("status_effects", []) as Array).duplicate(true)
	_sync_player_aliases(player)


func _map_event_id(event_id: String) -> String:
	match event_id:
		"evt_a":
			return "ruined_altar"
		"evt_b":
			return "ruin_merchant"
		"evt_c":
			return "sealed_ward"
		"evt_d":
			return "moonlight_rift"
		_:
			return event_id


func _assign_real_event_ids(act: Dictionary) -> void:
	for floor in act.get("floors", []):
		for node in floor.nodes:
			if String(node.type) == "event":
				node.event_id = _map_event_id(String(node.event_id))


func _find_node_by_type(floor, node_type: String):
	for node in floor.nodes:
		if String(node.type) == node_type:
			return node
	return null


func _grant_rewards_to_run(reward_manager, inventory_wrapper, rewards: Dictionary, player: Dictionary) -> Dictionary:
	var result: Dictionary = reward_manager.grant_rewards(rewards, inventory_wrapper)
	player["wallet"] = inventory_wrapper.wallet
	return result


func _apply_event_reward_to_run(result: Dictionary, inventory_wrapper, relic_manager) -> void:
	var reward: Dictionary = result.get("reward", {})
	var reward_type := String(reward.get("type", ""))
	if reward_type == "relic_candidate":
		relic_manager.add_relic("붉은 달의 파편")
	elif reward_type == "potion":
		inventory_wrapper.add_potion("소형 치료 물약")
	elif reward_type == "equipment" or reward_type == "high_equipment" or reward_type == "upgrade_material":
		inventory_wrapper.add_equipment("녹슨 검")


class _SequenceRng extends RefCounted:
	var _values: Array = []
	var _index := 0

	func _init(values: Array) -> void:
		_values = values.duplicate(true)

	func randf() -> float:
		if _values.is_empty():
			return 0.0
		var read_index := mini(_index, _values.size() - 1)
		var value := float(_values[read_index])
		_index += 1
		return value

	func randi_range(from_value: int, to_value: int) -> int:
		if _values.is_empty():
			return from_value
		var read_index := mini(_index, _values.size() - 1)
		var raw_value = _values[read_index]
		_index += 1
		if raw_value is int:
			return clampi(int(raw_value), from_value, to_value)
		var span := to_value - from_value + 1
		var offset := clampi(int(floor(float(raw_value) * float(span))), 0, span - 1)
		return from_value + offset


class _RunInventory extends RefCounted:
	var wallet = null
	var inventory = null

	func _init(start_gold: int = 0, config: Dictionary = {}) -> void:
		wallet = config.get("wallet", null)
		if wallet == null:
			var wallet_script = load(WALLET_PATH)
			if wallet_script != null:
				wallet = wallet_script.new({"gold": start_gold})
		var inventory_script = load(INVENTORY_PATH)
		if inventory_script != null:
			inventory = inventory_script.new(config)

	func add_equipment(item):
		if inventory == null:
			return {"success": false}
		return inventory.add_equipment(item)

	func add_potion(potion_name: String):
		if inventory == null:
			return {"success": false}
		return inventory.add_potion(potion_name)

	func add_relic(relic_id: String):
		if inventory == null:
			return {"success": false}
		return inventory.add_relic(relic_id)

	func potion_count(potion_name: String) -> int:
		if inventory == null:
			return 0
		return int(inventory.potions.get(potion_name, 0))

	func equipment_count() -> int:
		if inventory == null:
			return 0
		return inventory.equipment.size()

	func relic_count() -> int:
		if inventory == null:
			return 0
		return inventory.relics.size()
