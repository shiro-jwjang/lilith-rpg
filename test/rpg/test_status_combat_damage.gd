extends "res://test/rpg/test_base.gd"

const STATUS_MANAGER_PATH := "res://scripts/rpg/status/status_manager.gd"
const BLEED_EFFECT_PATH := "res://scripts/rpg/status/bleed_effect.gd"
const BURN_EFFECT_PATH := "res://scripts/rpg/status/burn_effect.gd"
const UNIT_PATH := "res://scripts/rpg/combat/unit.gd"


func test_combat_011_bleed_one_stack_deals_five_percent_max_hp_at_turn_end() -> void:
	var manager = _make_status_manager()
	var bleed = _make_effect(BLEED_EFFECT_PATH, 1, 3)
	var unit = _make_unit({"max_hp": 200, "current_hp": 200})
	if manager == null or bleed == null or unit == null:
		return
	manager.apply_effect(bleed)
	var damage = manager.tick_all(unit)
	assert_eq(damage, 10, "combat-011 expected bleed 1 stack to deal 10 DOT damage")
	assert_eq(unit.current_hp, 190, "combat-011 expected HP to drop from 200 to 190")


func test_combat_012_bleed_three_stacks_deals_fifteen_percent_max_hp_at_turn_end() -> void:
	var manager = _make_status_manager()
	var bleed = _make_effect(BLEED_EFFECT_PATH, 3, 3)
	var unit = _make_unit({"max_hp": 200, "current_hp": 200})
	if manager == null or bleed == null or unit == null:
		return
	manager.apply_effect(bleed)
	var damage = manager.tick_all(unit)
	assert_eq(damage, 30, "combat-012 expected bleed 3 stacks to deal 30 DOT damage")
	assert_eq(unit.current_hp, 170, "combat-012 expected HP to drop from 200 to 170")


func test_combat_013_bleed_damage_ignores_defense() -> void:
	var manager = _make_status_manager()
	var bleed = _make_effect(BLEED_EFFECT_PATH, 2, 3)
	var unit = _make_unit({"max_hp": 200, "current_hp": 200, "def": 999})
	if manager == null or bleed == null or unit == null:
		return
	manager.apply_effect(bleed)
	var damage = manager.tick_all(unit)
	assert_eq(damage, 20, "combat-013 expected bleed damage to ignore defense")
	assert_eq(unit.current_hp, 180, "combat-013 expected HP to drop by full bleed damage")


func test_combat_014_bleed_damage_can_kill_unit() -> void:
	var manager = _make_status_manager()
	var bleed = _make_effect(BLEED_EFFECT_PATH, 1, 3)
	var unit = _make_unit({"max_hp": 100, "current_hp": 5})
	if manager == null or bleed == null or unit == null:
		return
	manager.apply_effect(bleed)
	var damage = manager.tick_all(unit)
	assert_eq(damage, 5, "combat-014 expected bleed 1 stack to deal 5 DOT damage")
	assert_eq(unit.current_hp, 0, "combat-014 expected HP to reach 0 from bleed damage")
	assert_false(unit.is_alive(), "combat-014 expected unit to die from bleed damage")


func test_combat_015_burn_one_stack_deals_six_percent_max_hp_at_turn_end() -> void:
	var manager = _make_status_manager()
	var burn = _make_effect(BURN_EFFECT_PATH, 1, 3)
	var unit = _make_unit({"max_hp": 200, "current_hp": 200})
	if manager == null or burn == null or unit == null:
		return
	manager.apply_effect(burn)
	var damage = manager.tick_all(unit)
	assert_eq(damage, 12, "combat-015 expected burn 1 stack to deal 12 DOT damage")
	assert_eq(unit.current_hp, 188, "combat-015 expected HP to drop from 200 to 188")


func test_combat_016_burn_three_stacks_deals_eighteen_percent_max_hp_at_turn_end() -> void:
	var manager = _make_status_manager()
	var burn = _make_effect(BURN_EFFECT_PATH, 3, 3)
	var unit = _make_unit({"max_hp": 200, "current_hp": 200})
	if manager == null or burn == null or unit == null:
		return
	manager.apply_effect(burn)
	var damage = manager.tick_all(unit)
	assert_eq(damage, 36, "combat-016 expected burn 3 stacks to deal 36 DOT damage")
	assert_eq(unit.current_hp, 164, "combat-016 expected HP to drop from 200 to 164")


func test_combat_017_burn_damage_ignores_defense() -> void:
	var manager = _make_status_manager()
	var burn = _make_effect(BURN_EFFECT_PATH, 2, 3)
	var unit = _make_unit({"max_hp": 200, "current_hp": 200, "def": 999})
	if manager == null or burn == null or unit == null:
		return
	manager.apply_effect(burn)
	var damage = manager.tick_all(unit)
	assert_eq(damage, 24, "combat-017 expected burn damage to ignore defense")
	assert_eq(unit.current_hp, 176, "combat-017 expected HP to drop by full burn damage")


func test_combat_018_bleed_and_burn_damage_stack_together() -> void:
	var manager = _make_status_manager()
	var bleed = _make_effect(BLEED_EFFECT_PATH, 2, 3)
	var burn = _make_effect(BURN_EFFECT_PATH, 1, 3)
	var unit = _make_unit({"max_hp": 200, "current_hp": 100})
	if manager == null or bleed == null or burn == null or unit == null:
		return
	manager.apply_effect(bleed)
	manager.apply_effect(burn)
	var total_damage = manager.tick_all(unit)
	assert_eq(total_damage, 32, "combat-018 expected combined DOT damage of 32")
	assert_eq(unit.current_hp, 68, "combat-018 expected HP to drop from 100 to 68")


func _make_status_manager():
	var script = load(STATUS_MANAGER_PATH)
	assert_not_null(script, "expected status_manager.gd to exist")
	if script == null:
		return null
	return script.new()


func _make_effect(path: String, stacks := 1, remaining_turns := 3):
	var script = load(path)
	assert_not_null(script, "expected %s to exist" % path.get_file())
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
