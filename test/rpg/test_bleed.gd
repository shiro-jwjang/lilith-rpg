extends "res://test/rpg/test_base.gd"

const STATUS_MANAGER_PATH := "res://scripts/rpg/status/status_manager.gd"
const BLEED_EFFECT_PATH := "res://scripts/rpg/status/bleed_effect.gd"
const UNIT_PATH := "res://scripts/rpg/combat/unit.gd"


func test_status_001_bleed_new_application_sets_one_stack_and_three_turns() -> void:
	var manager = _make_status_manager()
	var effect = _make_bleed_effect()
	if manager == null or effect == null:
		return
	manager.apply_effect(effect)
	assert_true(manager.has_effect("bleed"), "status-001 expected bleed to be applied")
	var applied = manager.effects["bleed"]
	assert_eq(applied.stacks, 1, "status-001 expected new bleed to start at 1 stack")
	assert_eq(applied.remaining_turns, 3, "status-001 expected new bleed to last 3 turns")


func test_status_002_bleed_reapply_increments_stack_and_refreshes_duration() -> void:
	var manager = _make_status_manager()
	var first = _make_bleed_effect(2, 1)
	var second = _make_bleed_effect()
	if manager == null or first == null or second == null:
		return
	manager.apply_effect(first)
	manager.apply_effect(second)
	var applied = manager.effects["bleed"]
	assert_eq(applied.stacks, 3, "status-002 expected bleed stacks to increase from 2 to 3")
	assert_eq(applied.remaining_turns, 3, "status-002 expected bleed duration to refresh to 3")


func test_status_003_bleed_reapply_at_max_only_refreshes_duration() -> void:
	var manager = _make_status_manager()
	var first = _make_bleed_effect(3, 1)
	var second = _make_bleed_effect()
	if manager == null or first == null or second == null:
		return
	manager.apply_effect(first)
	manager.apply_effect(second)
	var applied = manager.effects["bleed"]
	assert_eq(applied.stacks, 3, "status-003 expected bleed stacks to remain capped at 3")
	assert_eq(applied.remaining_turns, 3, "status-003 expected capped bleed to refresh to 3 turns")


func test_status_004_bleed_tick_removes_effect_at_zero_duration() -> void:
	var manager = _make_status_manager()
	var effect = _make_bleed_effect(2, 1)
	if manager == null or effect == null:
		return
	manager.apply_effect(effect)
	manager.tick_all(_make_unit())
	assert_false(manager.has_effect("bleed"), "status-004 expected bleed to expire when duration reaches zero")


func test_status_029_bleed_damage_floors_decimal_result() -> void:
	var effect = _make_bleed_effect(1, 3)
	var unit = _make_unit({"max_hp": 33, "current_hp": 33})
	if effect == null or unit == null:
		return
	var damage = effect.on_tick(unit)
	assert_eq(damage, 1, "status-029 expected floor(33 * 0.05 * 1) = 1")


func test_status_031_bleed_three_stacks_on_1000_hp_deals_150_damage() -> void:
	var effect = _make_bleed_effect(3, 3)
	var unit = _make_unit({"max_hp": 1000, "current_hp": 1000})
	if effect == null or unit == null:
		return
	var damage = effect.on_tick(unit)
	assert_eq(damage, 150, "status-031 expected floor(1000 * 0.05 * 3) = 150")


func _make_status_manager():
	var script = load(STATUS_MANAGER_PATH)
	assert_not_null(script, "expected status_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _make_bleed_effect(stacks := 1, remaining_turns := 3):
	var script = load(BLEED_EFFECT_PATH)
	assert_not_null(script, "expected bleed_effect.gd to exist")
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
