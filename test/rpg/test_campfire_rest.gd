extends "res://test/rpg/test_base.gd"

const CAMPFIRE_MANAGER_PATH := "res://scripts/rpg/campfire/campfire_manager.gd"


func test_campfire_001_rest_heals_thirty_five_percent_of_max_hp() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var result: Dictionary = manager.rest({
		"hp": 20,
		"max_hp": 100,
	})
	var player_after: Dictionary = result.get("player", {})
	assert_eq(int(player_after.get("hp", -1)), 55, "campfire-001 expected hp 55")
	assert_eq(int(result.get("healed", -1)), 35, "campfire-001 expected healed 35")


func test_campfire_002_rest_does_not_overheal_when_hp_is_full() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var result: Dictionary = manager.rest({
		"hp": 100,
		"max_hp": 100,
	})
	var player_after: Dictionary = result.get("player", {})
	assert_eq(int(player_after.get("hp", -1)), 100, "campfire-002 expected hp to remain full")


func test_campfire_003_rest_caps_hp_at_max_after_healing() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var result: Dictionary = manager.rest({
		"hp": 80,
		"max_hp": 100,
	})
	var player_after: Dictionary = result.get("player", {})
	assert_eq(int(player_after.get("hp", -1)), 100, "campfire-003 expected hp capped at max")


func test_campfire_004_rest_uses_floor_on_thirty_five_percent_heal() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var result: Dictionary = manager.rest({
		"hp": 0,
		"max_hp": 200,
	})
	var player_after: Dictionary = result.get("player", {})
	assert_eq(int(player_after.get("hp", -1)), 70, "campfire-004 expected hp 70")
	assert_eq(int(result.get("healed", -1)), 70, "campfire-004 expected healed 70")


func _make_manager(config: Dictionary = {}):
	var script = load(CAMPFIRE_MANAGER_PATH)
	assert_not_null(script, "expected campfire_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)
