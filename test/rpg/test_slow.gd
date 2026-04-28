extends "res://test/rpg/test_base.gd"

const STATUS_MANAGER_PATH := "res://scripts/rpg/status/status_manager.gd"
const SLOW_EFFECT_PATH := "res://scripts/rpg/status/slow_effect.gd"


func test_status_008_slow_reduces_speed_by_twenty_percent_for_two_turns() -> void:
	var manager = _make_status_manager()
	var effect = _make_slow_effect()
	if manager == null or effect == null:
		return
	manager.apply_effect(effect)
	assert_eq(manager.get_effective_stat("speed", 100), 80, "status-008 expected speed 100 to become 80")
	assert_eq(manager.effects["slow"].remaining_turns, 2, "status-008 expected slow to last 2 turns")


func test_status_009_slow_reapply_refreshes_duration_without_stacking() -> void:
	var manager = _make_status_manager()
	var first = _make_slow_effect(1)
	var second = _make_slow_effect(2)
	if manager == null or first == null or second == null:
		return
	manager.apply_effect(first)
	manager.apply_effect(second)
	var applied = manager.effects["slow"]
	assert_eq(manager.get_effective_stat("speed", 100), 80, "status-009 expected slow effect magnitude to remain unchanged")
	assert_eq(applied.remaining_turns, 2, "status-009 expected slow duration to refresh to 2 turns")
	assert_eq(applied.stacks, 1, "status-009 expected slow to remain non-stacking")


func _make_status_manager():
	var script = load(STATUS_MANAGER_PATH)
	assert_not_null(script, "expected status_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _make_slow_effect(remaining_turns := 2):
	var script = load(SLOW_EFFECT_PATH)
	assert_not_null(script, "expected slow_effect.gd to exist")
	if script == null:
		return null
	return script.new(remaining_turns)
