extends "res://test/rpg/test_base.gd"

const BATTLE_MANAGER_PATH := "res://scripts/rpg/combat/battle_manager.gd"


func test_combat_039_normal_battle_target_turns_are_2_to_4() -> void:
	var manager = _make_battle_manager()
	if manager == null:
		return
	manager.init_battle([], [{"tier": "normal"}])
	assert_eq(manager.target_turn_range["min"], 2, "combat-039 expected normal battle minimum target turns to be 2")
	assert_eq(manager.target_turn_range["max"], 4, "combat-039 expected normal battle maximum target turns to be 4")


func test_combat_040_elite_battle_target_turns_are_4_to_6() -> void:
	var manager = _make_battle_manager()
	if manager == null:
		return
	manager.init_battle([], [{"tier": "elite"}])
	assert_eq(manager.target_turn_range["min"], 4, "combat-040 expected elite battle minimum target turns to be 4")
	assert_eq(manager.target_turn_range["max"], 6, "combat-040 expected elite battle maximum target turns to be 6")


func test_combat_041_boss_battle_target_turns_are_6_to_8() -> void:
	var manager = _make_battle_manager()
	if manager == null:
		return
	manager.init_battle([], [{"tier": "boss"}])
	assert_eq(manager.target_turn_range["min"], 6, "combat-041 expected boss battle minimum target turns to be 6")
	assert_eq(manager.target_turn_range["max"], 8, "combat-041 expected boss battle maximum target turns to be 8")


func _make_battle_manager():
	var script = load(BATTLE_MANAGER_PATH)
	assert_not_null(script, "expected battle_manager.gd to exist")
	if script == null:
		return null
	return script.new()
