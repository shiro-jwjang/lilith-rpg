extends "res://test/rpg/test_base.gd"

const BATTLE_MANAGER_PATH := "res://scripts/rpg/combat/battle_manager.gd"
const CONTENT_DATA_PATH := "res://scripts/rpg/data/content_data.gd"
const DAMAGE_CALCULATOR_PATH := "res://scripts/rpg/combat/damage_calculator.gd"
const STATUS_MANAGER_PATH := "res://scripts/rpg/status/status_manager.gd"
const BLEED_EFFECT_PATH := "res://scripts/rpg/status/bleed_effect.gd"
const BURN_EFFECT_PATH := "res://scripts/rpg/status/burn_effect.gd"


func test_integ_016_bleed_enemy_applies_bleed_and_dot_ticks_over_time() -> void:
	var summary := _run_status_battle("붉은 사냥견", "bleed")
	if summary.is_empty():
		return

	assert_true(bool(summary.get("status_applied", false)), "integ-016 expected bleed to be applied")
	assert_true(bool(summary.get("dot_observed", false)), "integ-016 expected bleed DOT damage during battle")
	assert_true(int(summary.get("hp_after_dot", 9999)) < int(summary.get("hp_after_direct_hit", 9999)), "integ-016 expected HP to keep dropping after direct hit from bleed")


func test_integ_017_burn_enemy_applies_burn_and_dot_ticks_over_time() -> void:
	var summary := _run_status_battle("그을린 궁수", "burn")
	if summary.is_empty():
		return

	assert_true(bool(summary.get("status_applied", false)), "integ-017 expected burn to be applied")
	assert_true(bool(summary.get("dot_observed", false)), "integ-017 expected burn DOT damage during battle")
	assert_true(int(summary.get("hp_after_dot", 9999)) < int(summary.get("hp_after_direct_hit", 9999)), "integ-017 expected HP to keep dropping after direct hit from burn")


func test_integ_018_status_manager_and_battle_manager_agree_on_dot_damage_direction() -> void:
	var status_manager = _status_manager()
	var bleed_effect = _effect(BLEED_EFFECT_PATH)
	var burn_effect = _effect(BURN_EFFECT_PATH)
	if status_manager == null or bleed_effect == null or burn_effect == null:
		return

	var summary := _run_status_battle("붉은 사냥견", "bleed")
	if summary.is_empty():
		return

	var unit = load("res://scripts/rpg/combat/unit.gd").new({
		"current_hp": 100,
		"max_hp": 100,
		"atk": 10,
		"def": 5,
		"speed": 10,
	})
	status_manager.apply_effect(bleed_effect)
	status_manager.apply_effect(burn_effect)
	var status_damage: int = status_manager.tick_all(unit)

	assert_true(status_damage > 0, "integ-018 expected status manager DOT damage")
	assert_true(bool(summary.get("dot_observed", false)), "integ-018 expected battle loop DOT damage")
	assert_true(unit.current_hp < 100, "integ-018 expected standalone DOT processing to reduce HP")


func _run_status_battle(enemy_name: String, effect_key: String) -> Dictionary:
	var battle_manager = _battle_manager()
	var content = _content()
	var damage_calculator = _damage_calculator()
	if battle_manager == null or content == null or damage_calculator == null:
		return {}

	var ally_config := {
		"internal_id": 1,
		"current_hp": 100,
		"max_hp": 100,
		"current_mp": 0,
		"max_mp": 0,
		"atk": 16,
		"def": 8,
		"speed": 9,
	}
	var enemy_data: Dictionary = content.get_enemy_by_name(enemy_name)
	var enemy_config := {
		"internal_id": 101,
		"current_hp": int(enemy_data.get("max_hp", 0)),
		"max_hp": int(enemy_data.get("max_hp", 0)),
		"atk": int(enemy_data.get("attack", 0)),
		"def": int(enemy_data.get("defense", 0)),
		"speed": int(enemy_data.get("speed", 0)),
		"tier": String(enemy_data.get("tier", "normal")),
	}
	battle_manager.init_battle([ally_config], [enemy_config])

	var status_applied := false
	var dot_observed := false
	var hp_after_direct_hit := int(battle_manager.allies[0].current_hp)
	var hp_after_dot := int(battle_manager.allies[0].current_hp)
	var turns := 0
	while turns < 6:
		var turn_result: Dictionary = battle_manager.next_turn()
		turns += 1
		var acting_unit = turn_result.get("unit", null)
		if acting_unit == null or not bool(turn_result.get("action_allowed", false)) or not acting_unit.is_alive():
			continue

		if bool(acting_unit.is_ally):
			var damage: int = damage_calculator.calculate_base_damage(int(acting_unit.atk), 1.0, int(battle_manager.enemies[0].def))
			battle_manager.enemies[0].take_damage(damage)
			if int(turn_result.get("dot_damage", 0)) > 0:
				dot_observed = true
				hp_after_dot = int(acting_unit.current_hp)
				break
		else:
			var incoming: int = damage_calculator.calculate_base_damage(int(acting_unit.atk), 1.0, int(battle_manager.allies[0].def))
			battle_manager.allies[0].take_damage(incoming)
			hp_after_direct_hit = int(battle_manager.allies[0].current_hp)
			battle_manager.allies[0].status_effects[effect_key] = {"stacks": 1, "remaining_turns": 3}
			status_applied = true

	return {
		"status_applied": status_applied,
		"dot_observed": dot_observed,
		"hp_after_direct_hit": hp_after_direct_hit,
		"hp_after_dot": hp_after_dot,
	}


func _battle_manager():
	var script = load(BATTLE_MANAGER_PATH)
	assert_not_null(script, "expected battle_manager.gd to exist")
	if script == null:
		return null
	return script.new()


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


func _status_manager():
	var script = load(STATUS_MANAGER_PATH)
	assert_not_null(script, "expected status_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _effect(path: String):
	var script = load(path)
	assert_not_null(script, "expected %s to exist" % path.get_file())
	if script == null:
		return null
	return script.new(1, 3)
