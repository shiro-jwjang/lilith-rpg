extends "res://test/rpg/test_base.gd"

const STATUS_MANAGER_PATH := "res://scripts/rpg/status/status_manager.gd"
const BURN_EFFECT_PATH := "res://scripts/rpg/status/burn_effect.gd"
const UNIT_PATH := "res://scripts/rpg/combat/unit.gd"


func test_status_005_burn_new_application_sets_one_stack_and_three_turns() -> void:
	var manager = _make_status_manager()
	var effect = _make_burn_effect()
	if manager == null or effect == null:
		return
	manager.apply_effect(effect)
	assert_true(manager.has_effect("burn"), "status-005 expected burn to be applied")
	var applied = manager.effects["burn"]
	assert_eq(applied.stacks, 1, "status-005 expected new burn to start at 1 stack")
	assert_eq(applied.remaining_turns, 3, "status-005 expected new burn to last 3 turns")


func test_status_006_burn_reapply_increments_stack_and_refreshes_duration() -> void:
	var manager = _make_status_manager()
	var first = _make_burn_effect(1, 2)
	var second = _make_burn_effect()
	if manager == null or first == null or second == null:
		return
	manager.apply_effect(first)
	manager.apply_effect(second)
	var applied = manager.effects["burn"]
	assert_eq(applied.stacks, 2, "status-006 expected burn stacks to increase from 1 to 2")
	assert_eq(applied.remaining_turns, 3, "status-006 expected burn duration to refresh to 3")


func test_status_007_burn_reapply_at_max_only_refreshes_duration() -> void:
	var manager = _make_status_manager()
	var first = _make_burn_effect(3, 1)
	var second = _make_burn_effect()
	if manager == null or first == null or second == null:
		return
	manager.apply_effect(first)
	manager.apply_effect(second)
	var applied = manager.effects["burn"]
	assert_eq(applied.stacks, 3, "status-007 expected burn stacks to remain capped at 3")
	assert_eq(applied.remaining_turns, 3, "status-007 expected capped burn to refresh to 3 turns")


func test_status_030_burn_damage_floors_decimal_result() -> void:
	var effect = _make_burn_effect(1, 3)
	var unit = _make_unit({"max_hp": 33, "current_hp": 33})
	if effect == null or unit == null:
		return
	var damage = effect.on_tick(unit)
	assert_eq(damage, 1, "status-030 expected floor(33 * 0.06 * 1) = 1")


func test_status_032_burn_three_stacks_on_1000_hp_deals_180_damage() -> void:
	var effect = _make_burn_effect(3, 3)
	var unit = _make_unit({"max_hp": 1000, "current_hp": 1000})
	if effect == null or unit == null:
		return
	var damage = effect.on_tick(unit)
	assert_eq(damage, 180, "status-032 expected floor(1000 * 0.06 * 3) = 180")


func _make_status_manager():
	var script = load(STATUS_MANAGER_PATH)
	assert_not_null(script, "expected status_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _make_burn_effect(stacks := 1, remaining_turns := 3):
	var script = load(BURN_EFFECT_PATH)
	assert_not_null(script, "expected burn_effect.gd to exist")
	if script == null:
		return null
	return script.new(stacks, remaining_turns)


func _make_unit(overrides: Dictionary = {}):
	var unit_script = load(UNIT_PATH)
	assert_not_null(unit_script, "expected unit.gd to exist")
	if unit_script == null:
		return null
	var config := {
		"current_hp": 100,
		"max_hp": 100,
		"current_mp": 0,
		"max_mp": 0,
		"atk": 10,
		"def": 10,
		"speed": 10,
		"internal_id": 1,
		"is_ally": true,
		"status_effects": {},
	}
	for key in overrides:
		config[key] = overrides[key]
	return unit_script.new(config)
