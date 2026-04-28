extends "res://test/rpg/test_base.gd"

const STATUS_MANAGER_PATH := "res://scripts/rpg/status/status_manager.gd"
const WEAKEN_EFFECT_PATH := "res://scripts/rpg/status/weaken_effect.gd"


func test_status_010_weaken_reduces_atk_by_twenty_percent_for_two_turns() -> void:
	var manager = _make_status_manager()
	var effect = _make_weaken_effect()
	if manager == null or effect == null:
		return
	manager.apply_effect(effect)
	assert_eq(manager.get_effective_stat("atk", 100), 80, "status-010 expected atk 100 to become 80")
	assert_eq(manager.effects["weaken"].remaining_turns, 2, "status-010 expected weaken to last 2 turns")


func test_status_011_weaken_reapply_refreshes_duration_without_stacking() -> void:
	var manager = _make_status_manager()
	var first = _make_weaken_effect(1)
	var second = _make_weaken_effect(2)
	if manager == null or first == null or second == null:
		return
	manager.apply_effect(first)
	manager.apply_effect(second)
	var applied = manager.effects["weaken"]
	assert_eq(manager.get_effective_stat("atk", 100), 80, "status-011 expected weaken effect magnitude to remain unchanged")
	assert_eq(applied.remaining_turns, 2, "status-011 expected weaken duration to refresh to 2 turns")


func _make_status_manager():
	var script = load(STATUS_MANAGER_PATH)
	assert_not_null(script, "expected status_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _make_weaken_effect(remaining_turns := 2):
	var script = load(WEAKEN_EFFECT_PATH)
	assert_not_null(script, "expected weaken_effect.gd to exist")
	if script == null:
		return null
	return script.new(remaining_turns)
