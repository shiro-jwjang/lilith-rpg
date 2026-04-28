extends "res://test/rpg/test_base.gd"

const STATUS_MANAGER_PATH := "res://scripts/rpg/status/status_manager.gd"
const SLOW_EFFECT_PATH := "res://scripts/rpg/status/slow_effect.gd"
const WEAKEN_EFFECT_PATH := "res://scripts/rpg/status/weaken_effect.gd"
const SHATTER_EFFECT_PATH := "res://scripts/rpg/status/shatter_effect.gd"


func test_status_027_slow_weaken_and_shatter_apply_together() -> void:
	var manager = _make_status_manager()
	if manager == null:
		return
	manager.apply_effect(_make_effect(SLOW_EFFECT_PATH))
	manager.apply_effect(_make_effect(WEAKEN_EFFECT_PATH))
	manager.apply_effect(_make_effect(SHATTER_EFFECT_PATH))
	assert_eq(manager.get_effective_stat("speed", 100), 80, "status-027 expected speed to become 80")
	assert_eq(manager.get_effective_stat("atk", 100), 80, "status-027 expected atk to become 80")
	assert_eq(manager.get_effective_stat("def", 100), 75, "status-027 expected def to become 75")


func test_status_028_expired_debuffs_restore_original_stats() -> void:
	var manager = _make_status_manager()
	if manager == null:
		return
	manager.apply_effect(_make_effect(SLOW_EFFECT_PATH, 1))
	manager.apply_effect(_make_effect(WEAKEN_EFFECT_PATH, 1))
	manager.apply_effect(_make_effect(SHATTER_EFFECT_PATH, 1))
	manager.tick_all()
	assert_false(manager.has_effect("slow"), "status-028 expected slow to be removed after expiry")
	assert_false(manager.has_effect("weaken"), "status-028 expected weaken to be removed after expiry")
	assert_false(manager.has_effect("shatter"), "status-028 expected shatter to be removed after expiry")
	assert_eq(manager.get_effective_stat("speed", 100), 100, "status-028 expected speed to restore to 100")
	assert_eq(manager.get_effective_stat("atk", 100), 100, "status-028 expected atk to restore to 100")
	assert_eq(manager.get_effective_stat("def", 100), 100, "status-028 expected def to restore to 100")


func _make_status_manager():
	var script = load(STATUS_MANAGER_PATH)
	assert_not_null(script, "expected status_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _make_effect(path: String, remaining_turns := 2):
	var script = load(path)
	assert_not_null(script, "expected %s to exist" % path.get_file())
	if script == null:
		return null
	return script.new(remaining_turns)
