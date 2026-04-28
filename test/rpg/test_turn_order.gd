extends "res://test/rpg/test_base.gd"

const TURN_ORDER_PATH := "res://scripts/rpg/combat/turn_order.gd"
const UNIT_PATH := "res://scripts/rpg/combat/unit.gd"


func test_combat_019_turn_order_prefers_ally_on_speed_tie() -> void:
	var enemy = _make_unit({"internal_id": 2, "is_ally": false, "speed": 100})
	var ally = _make_unit({"internal_id": 1, "is_ally": true, "speed": 100})
	if enemy == null or ally == null:
		return
	var ordered = _resolve_units([enemy, ally])
	if ordered.is_empty():
		return
	assert_eq(ordered[0].is_ally, true, "combat-019 expected ally to act first on speed tie")


func test_combat_020_turn_order_prefers_lower_hp_ratio_within_same_side() -> void:
	var ally_a = _make_unit({
		"internal_id": 1,
		"is_ally": true,
		"speed": 100,
		"current_hp": 50,
		"max_hp": 100,
	})
	var ally_b = _make_unit({
		"internal_id": 2,
		"is_ally": true,
		"speed": 100,
		"current_hp": 80,
		"max_hp": 100,
	})
	if ally_a == null or ally_b == null:
		return
	var ordered = _resolve_units([ally_b, ally_a])
	if ordered.is_empty():
		return
	assert_eq(ordered[0].internal_id, 1, "combat-020 expected lower HP ratio to act first")


func test_combat_021_turn_order_prefers_lower_internal_id_after_ratio_tie() -> void:
	var ally_a = _make_unit({
		"internal_id": 3,
		"is_ally": true,
		"speed": 100,
		"current_hp": 80,
		"max_hp": 100,
	})
	var ally_b = _make_unit({
		"internal_id": 1,
		"is_ally": true,
		"speed": 100,
		"current_hp": 80,
		"max_hp": 100,
	})
	if ally_a == null or ally_b == null:
		return
	var ordered = _resolve_units([ally_a, ally_b])
	if ordered.is_empty():
		return
	assert_eq(ordered[0].internal_id, 1, "combat-021 expected lower internal ID to act first")


func _resolve_units(units: Array) -> Array:
	var turn_order = load(TURN_ORDER_PATH)
	assert_not_null(turn_order, "expected turn_order.gd to exist")
	if turn_order == null:
		return []
	return turn_order.resolve_turn_order(units)


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
		"def": 5,
		"speed": 10,
		"internal_id": 1,
		"is_ally": true,
	}
	for key in overrides:
		config[key] = overrides[key]
	return unit_script.new(config)
