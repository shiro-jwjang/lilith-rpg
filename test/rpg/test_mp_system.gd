extends "res://test/rpg/test_base.gd"

const UNIT_PATH := "res://scripts/rpg/combat/unit.gd"


func test_combat_027_unit_cannot_use_skill_when_mp_is_insufficient() -> void:
	var unit = _make_unit(5)
	if unit == null:
		return
	var success = unit.use_mp(10)
	assert_false(success, "combat-027 expected skill use to fail when MP is insufficient")
	assert_eq(unit.current_mp, 5, "combat-027 expected MP to remain unchanged on failure")


func test_combat_028_unit_uses_skill_and_deducts_mp_when_sufficient() -> void:
	var unit = _make_unit(20)
	if unit == null:
		return
	var success = unit.use_mp(10)
	assert_true(success, "combat-028 expected skill use to succeed with enough MP")
	assert_eq(unit.current_mp, 10, "combat-028 expected MP to decrease by the skill cost")


func test_combat_029_unit_can_use_skill_when_mp_exactly_matches_cost() -> void:
	var unit = _make_unit(10)
	if unit == null:
		return
	var success = unit.use_mp(10)
	assert_true(success, "combat-029 expected exact MP match to be usable")
	assert_eq(unit.current_mp, 0, "combat-029 expected MP to reach zero after exact-cost use")


func _make_unit(current_mp: int):
	var unit_script = load(UNIT_PATH)
	assert_not_null(unit_script, "expected unit.gd to exist")
	if unit_script == null:
		return null
	return unit_script.new({
		"current_hp": 100,
		"max_hp": 100,
		"current_mp": current_mp,
		"max_mp": current_mp,
		"atk": 10,
		"def": 5,
		"speed": 10,
		"internal_id": 1,
		"is_ally": true,
	})
