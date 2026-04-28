extends "res://test/rpg/test_base.gd"

const STATUS_MANAGER_PATH := "res://scripts/rpg/status/status_manager.gd"
const STUN_EFFECT_PATH := "res://scripts/rpg/status/stun_effect.gd"


func test_status_015_stun_blocks_action_for_one_turn() -> void:
	var manager = _make_status_manager()
	var effect = _make_stun_effect()
	if manager == null or effect == null:
		return
	manager.apply_effect(effect)
	assert_true(manager.has_effect("stun"), "status-015 expected stun to be applied")
	assert_eq(manager.effects["stun"].remaining_turns, 1, "status-015 expected stun to last 1 turn")
	assert_true(manager.is_action_blocked(), "status-015 expected stun to block actions")


func test_status_016_stun_reapply_refreshes_to_one_turn_without_stacking() -> void:
	var manager = _make_status_manager()
	var first = _make_stun_effect(1)
	var second = _make_stun_effect(1)
	if manager == null or first == null or second == null:
		return
	manager.apply_effect(first)
	manager.apply_effect(second)
	var applied = manager.effects["stun"]
	assert_eq(applied.remaining_turns, 1, "status-016 expected stun duration to remain fixed at 1 turn")


func test_status_034_stun_expires_after_one_tick_and_next_turn_allows_normal_action() -> void:
	var manager = _make_status_manager()
	var effect = _make_stun_effect()
	if manager == null or effect == null:
		return
	manager.apply_effect(effect)
	assert_true(manager.is_action_blocked(), "status-034 expected first turn action to be blocked")
	manager.tick_all()
	assert_false(manager.has_effect("stun"), "status-034 expected stun to expire after one tick")
	assert_false(manager.is_action_blocked(), "status-034 expected next turn action to be available")


func _make_status_manager():
	var script = load(STATUS_MANAGER_PATH)
	assert_not_null(script, "expected status_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _make_stun_effect(remaining_turns := 1):
	var script = load(STUN_EFFECT_PATH)
	assert_not_null(script, "expected stun_effect.gd to exist")
	if script == null:
		return null
	return script.new(remaining_turns)
