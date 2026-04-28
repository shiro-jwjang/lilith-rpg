extends "res://test/rpg/test_base.gd"

const TURN_MANAGER_PATH := "res://scripts/rpg/combat/turn_manager.gd"
const UNIT_PATH := "res://scripts/rpg/combat/unit.gd"
const BATTLE_MANAGER_PATH := "res://scripts/rpg/combat/battle_manager.gd"


func test_combat_022_on_turn_start_decrements_and_removes_expired_effects() -> void:
	var manager = _make_turn_manager()
	if manager == null:
		return
	var unit = _make_unit({
		"status_effects": {
			"buff_attack_up": {"remaining_turns": 1},
			"debuff_def_down": {"remaining_turns": 2},
		},
	})
	if unit == null:
		return
	var can_act = manager.on_turn_start(unit)
	assert_true(can_act, "combat-022 expected unit to act when not stunned")
	assert_false(unit.status_effects.has("buff_attack_up"), "combat-022 expected 1-turn buff to expire")
	assert_true(unit.status_effects.has("debuff_def_down"), "combat-022 expected 2-turn debuff to remain")
	assert_eq(unit.status_effects["debuff_def_down"]["remaining_turns"], 1, "combat-022 expected debuff duration to decrement")


func test_combat_023_on_turn_start_skips_action_when_stunned() -> void:
	var manager = _make_turn_manager()
	if manager == null:
		return
	var unit = _make_unit({
		"status_effects": {
			"stun": {"remaining_turns": 1},
		},
	})
	if unit == null:
		return
	var can_act = manager.on_turn_start(unit)
	assert_false(can_act, "combat-023 expected stunned unit to skip its action")
	assert_false(unit.status_effects.has("stun"), "combat-023 expected stun to expire after processing")


func test_combat_024_on_turn_end_applies_burn_dot_and_can_kill() -> void:
	var manager = _make_turn_manager()
	if manager == null:
		return
	var unit = _make_unit({
		"max_hp": 100,
		"current_hp": 3,
		"status_effects": {
			"burn": {"stacks": 1},
		},
	})
	if unit == null:
		return
	var dot_damage = manager.on_turn_end(unit)
	assert_eq(dot_damage, 6, "combat-024 expected burn to deal floor(100 * 0.06) = 6")
	assert_eq(unit.current_hp, 0, "combat-024 expected HP to clamp at zero")
	assert_false(unit.is_alive(), "combat-024 expected unit to die from DOT")


func test_combat_025_battle_manager_reports_defeat_when_all_allies_are_dead() -> void:
	var manager = _make_battle_manager()
	if manager == null:
		return
	manager.init_battle([
		{"internal_id": 1, "is_ally": true, "current_hp": 0, "max_hp": 100},
		{"internal_id": 2, "is_ally": true, "current_hp": 0, "max_hp": 100},
		{"internal_id": 3, "is_ally": true, "current_hp": 0, "max_hp": 100},
	], [
		{"internal_id": 101, "is_ally": false, "current_hp": 50, "max_hp": 100},
	])
	assert_eq(manager.check_battle_end(), "defeat", "combat-025 expected defeat when all allies are dead")
	assert_true(manager.run_terminate(), "combat-025 expected defeat to terminate the run")


func test_combat_026_battle_manager_reports_victory_when_all_enemies_are_dead() -> void:
	var manager = _make_battle_manager()
	if manager == null:
		return
	manager.init_battle([
		{"internal_id": 1, "is_ally": true, "current_hp": 30, "max_hp": 100},
	], [
		{"internal_id": 101, "is_ally": false, "current_hp": 0, "max_hp": 100},
		{"internal_id": 102, "is_ally": false, "current_hp": 0, "max_hp": 100},
	])
	assert_eq(manager.check_battle_end(), "victory", "combat-026 expected victory when all enemies are dead")
	assert_false(manager.run_terminate(), "combat-026 expected victory not to terminate the run")


func _make_unit(overrides: Dictionary = {}):
	var unit_script = load(UNIT_PATH)
	assert_not_null(unit_script, "expected unit.gd to exist")
	if unit_script == null:
		return null
	var config := {
		"current_hp": 100,
		"max_hp": 100,
		"current_mp": 20,
		"max_mp": 20,
		"atk": 10,
		"def": 5,
		"speed": 10,
		"internal_id": 1,
		"is_ally": true,
		"status_effects": {},
	}
	for key in overrides:
		config[key] = overrides[key]
	return unit_script.new(config)


func _make_turn_manager():
	var script = load(TURN_MANAGER_PATH)
	assert_not_null(script, "expected turn_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _make_battle_manager():
	var script = load(BATTLE_MANAGER_PATH)
	assert_not_null(script, "expected battle_manager.gd to exist")
	if script == null:
		return null
	return script.new()
