extends "res://test/rpg/test_base.gd"

const STATUS_MANAGER_PATH := "res://scripts/rpg/status/status_manager.gd"
const BLEED_EFFECT_PATH := "res://scripts/rpg/status/bleed_effect.gd"
const BURN_EFFECT_PATH := "res://scripts/rpg/status/burn_effect.gd"
const UNIT_PATH := "res://scripts/rpg/combat/unit.gd"


func test_status_033_bleed_and_burn_apply_combined_dot_damage() -> void:
	var manager = _make_status_manager()
	var bleed = _make_effect(BLEED_EFFECT_PATH, 3, 3)
	var burn = _make_effect(BURN_EFFECT_PATH, 3, 3)
	var unit = _make_unit({"max_hp": 1000, "current_hp": 700})
	if manager == null or bleed == null or burn == null or unit == null:
		return
	manager.apply_effect(bleed)
	manager.apply_effect(burn)
	var total_damage = manager.tick_all(unit)
	assert_eq(total_damage, 330, "status-033 expected combined DOT damage of 330")
	assert_eq(unit.current_hp, 370, "status-033 expected HP to drop from 700 to 370")


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
