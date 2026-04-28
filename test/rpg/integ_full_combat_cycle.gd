extends "res://test/rpg/test_base.gd"

const BATTLE_MANAGER_PATH := "res://scripts/rpg/combat/battle_manager.gd"
const CONTENT_DATA_PATH := "res://scripts/rpg/data/content_data.gd"
const DAMAGE_CALCULATOR_PATH := "res://scripts/rpg/combat/damage_calculator.gd"


func test_integ_001_three_allies_defeat_one_normal_enemy_and_survive() -> void:
	var summary := _run_battle(_default_allies(), [_enemy_config(_content().get_enemy_by_name("녹슨 검병"), 101)])
	if summary.is_empty():
		return

	assert_eq(summary.get("winner", ""), "victory", "integ-001 expected normal battle victory")
	assert_gt(int(summary.get("turns", 0)), 0, "integ-001 expected at least one processed turn")
	assert_true(bool(summary.get("allies_took_damage", false)), "integ-001 expected allies to take damage")
	assert_true(bool(summary.get("all_allies_survived", false)), "integ-001 expected all allies to survive")


func test_integ_002_boss_battle_takes_more_turns_than_normal_enemy_battle() -> void:
	var content = _content()
	if content == null:
		return

	var normal_summary := _run_battle(_default_allies(), [_enemy_config(content.get_enemy_by_name("녹슨 검병"), 101)])
	var boss_summary := _run_battle(_default_allies(), [_enemy_config(content.get_boss(), 201)])
	if normal_summary.is_empty() or boss_summary.is_empty():
		return

	assert_eq(boss_summary.get("winner", ""), "victory", "integ-002 expected boss battle victory")
	assert_gt(int(boss_summary.get("turns", 0)), int(normal_summary.get("turns", 0)), "integ-002 expected boss battle to take more turns")
	assert_eq(int(boss_summary.get("enemy_max_hp", 0)), 450, "integ-002 expected boss HP 450 from content data")


func test_integ_003_one_hp_ally_loses_to_strong_enemy() -> void:
	var ally := {
		"internal_id": 1,
		"current_hp": 1,
		"max_hp": 100,
		"current_mp": 0,
		"max_mp": 0,
		"atk": 8,
		"def": 3,
		"speed": 1,
		"role": "front",
		"skill_name": "기본공격",
	}
	var enemy := {
		"internal_id": 301,
		"current_hp": 120,
		"max_hp": 120,
		"current_mp": 0,
		"max_mp": 0,
		"atk": 25,
		"def": 6,
		"speed": 20,
		"tier": "elite",
		"enemy_status_names": [],
	}
	var summary := _run_battle([ally], [enemy])
	if summary.is_empty():
		return

	assert_eq(summary.get("winner", ""), "defeat", "integ-003 expected defeat for 1 HP ally")
	assert_true(int(summary.get("remaining_allies", 1)) == 0, "integ-003 expected no surviving allies")
	assert_true(int(summary.get("turns", 0)) <= 2, "integ-003 expected the defeat to happen quickly")


func _run_battle(allies: Array, enemies: Array) -> Dictionary:
	var battle_manager = _battle_manager()
	var damage_calculator = _damage_calculator()
	var content = _content()
	if battle_manager == null or damage_calculator == null or content == null:
		return {}

	battle_manager.init_battle(allies, enemies)
	var initial_ally_hp: Array = []
	for ally in battle_manager.allies:
		initial_ally_hp.append(int(ally.current_hp))

	var turns := 0
	var winner = battle_manager.check_battle_end()
	while winner == null and turns < 100:
		var turn_result: Dictionary = battle_manager.next_turn()
		turns += 1
		var acting_unit = turn_result.get("unit", null)
		if acting_unit != null and bool(turn_result.get("action_allowed", false)) and acting_unit.is_alive():
			if bool(acting_unit.is_ally):
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
					var enemy_damage: int = damage_calculator.calculate_base_damage(int(acting_unit.atk), 1.0, int(ally_target.def))
					ally_target.take_damage(enemy_damage)
					_apply_enemy_statuses(acting_unit, ally_target)

		winner = battle_manager.check_battle_end()

	var allies_took_damage := false
	var all_allies_survived := true
	for index in range(battle_manager.allies.size()):
		var ally = battle_manager.allies[index]
		if int(ally.current_hp) < int(initial_ally_hp[index]):
			allies_took_damage = true
		if not ally.is_alive():
			all_allies_survived = false

	return {
		"winner": winner if winner != null else "",
		"turns": turns,
		"allies_took_damage": allies_took_damage,
		"all_allies_survived": all_allies_survived,
		"remaining_allies": _count_living_units(battle_manager.allies),
		"enemy_max_hp": int(enemies[0].get("max_hp", 0)),
	}


func _default_allies() -> Array:
	return [
		{
			"internal_id": 1,
			"current_hp": 120,
			"max_hp": 120,
			"current_mp": 20,
			"max_mp": 20,
			"atk": 18,
			"def": 8,
			"speed": 13,
			"status_effects": {
				"role": "front",
				"skill_name": "돌진베기",
			},
		},
		{
			"internal_id": 2,
			"current_hp": 145,
			"max_hp": 145,
			"current_mp": 18,
			"max_mp": 18,
			"atk": 14,
			"def": 12,
			"speed": 9,
			"status_effects": {
				"role": "guardian",
				"skill_name": "기본공격",
			},
		},
		{
			"internal_id": 3,
			"current_hp": 100,
			"max_hp": 100,
			"current_mp": 24,
			"max_mp": 24,
			"atk": 16,
			"def": 7,
			"speed": 11,
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


func _apply_enemy_statuses(enemy_unit, ally_unit) -> void:
	var statuses: Array = enemy_unit.status_effects.get("enemy_status_names", [])
	for status_name in statuses:
		if String(status_name) == "출혈":
			ally_unit.status_effects["bleed"] = {"stacks": 1, "remaining_turns": 3}
		elif String(status_name) == "화상":
			ally_unit.status_effects["burn"] = {"stacks": 1, "remaining_turns": 3}


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


func _battle_manager():
	var script = load(BATTLE_MANAGER_PATH)
	assert_not_null(script, "expected battle_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _damage_calculator():
	var script = load(DAMAGE_CALCULATOR_PATH)
	assert_not_null(script, "expected damage_calculator.gd to exist")
	return script


func _content():
	var script = load(CONTENT_DATA_PATH)
	assert_not_null(script, "expected content_data.gd to exist")
	if script == null:
		return null
	return script.new()
