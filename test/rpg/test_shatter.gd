extends "res://test/rpg/test_base.gd"

const STATUS_MANAGER_PATH := "res://scripts/rpg/status/status_manager.gd"
const SHATTER_EFFECT_PATH := "res://scripts/rpg/status/shatter_effect.gd"
const DAMAGE_CALCULATOR_PATH := "res://scripts/rpg/combat/damage_calculator.gd"


func test_status_012_shatter_reduces_def_by_twenty_five_percent_for_two_turns() -> void:
	var manager = _make_status_manager()
	var effect = _make_shatter_effect()
	if manager == null or effect == null:
		return
	manager.apply_effect(effect)
	assert_eq(manager.get_effective_stat("def", 100), 75, "status-012 expected def 100 to become 75")
	assert_eq(manager.effects["shatter"].remaining_turns, 2, "status-012 expected shatter to last 2 turns")


func test_status_013_shatter_reapply_refreshes_duration_without_stacking() -> void:
	var manager = _make_status_manager()
	var first = _make_shatter_effect(1)
	var second = _make_shatter_effect(2)
	if manager == null or first == null or second == null:
		return
	manager.apply_effect(first)
	manager.apply_effect(second)
	var applied = manager.effects["shatter"]
	assert_eq(manager.get_effective_stat("def", 100), 75, "status-013 expected shatter effect magnitude to remain unchanged")
	assert_eq(applied.remaining_turns, 2, "status-013 expected shatter duration to refresh to 2 turns")


func test_status_014_shatter_effective_def_integrates_with_base_damage_formula() -> void:
	var manager = _make_status_manager()
	var effect = _make_shatter_effect()
	var calculator = _load_calculator()
	if manager == null or effect == null or calculator == null:
		return
	manager.apply_effect(effect)
	var effective_def = manager.get_effective_stat("def", 100)
	var damage = calculator.calculate_base_damage(100, 1.0, effective_def)
	assert_eq(effective_def, 75, "status-014 expected shatter to reduce DEF to 75 before damage calculation")
	assert_eq(damage, 25, "status-014 expected damage 25 with shatter-adjusted defense")


func _make_status_manager():
	var script = load(STATUS_MANAGER_PATH)
	assert_not_null(script, "expected status_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _make_shatter_effect(remaining_turns := 2):
	var script = load(SHATTER_EFFECT_PATH)
	assert_not_null(script, "expected shatter_effect.gd to exist")
	if script == null:
		return null
	return script.new(remaining_turns)


func _load_calculator():
	var calculator = load(DAMAGE_CALCULATOR_PATH)
	assert_not_null(calculator, "expected damage_calculator.gd to exist")
	return calculator
