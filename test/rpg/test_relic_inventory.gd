extends "res://test/rpg/test_base.gd"

const INVENTORY_PATH := "res://scripts/rpg/inventory/inventory.gd"


func test_inventory_004_add_relic_succeeds_when_inventory_is_empty() -> void:
	var inventory = _make_inventory()
	if inventory == null:
		return
	var result = inventory.add_relic("붉은 눈동자")
	assert_true(result["success"], "inventory-004 expected relic add success")
	assert_eq(inventory.relics.size(), 1, "inventory-004 expected relic count 1")


func test_inventory_005_add_relic_fails_when_inventory_is_full() -> void:
	var inventory = _make_inventory({
		"relics": ["유물1", "유물2", "유물3", "유물4"],
	})
	if inventory == null:
		return
	var result = inventory.add_relic("유물5")
	assert_false(result["success"], "inventory-005 expected relic add failure at capacity 4")
	assert_eq(inventory.relics.size(), 4, "inventory-005 expected relic count to stay 4")


func test_inventory_006_add_relic_succeeds_at_three_of_four_capacity() -> void:
	var inventory = _make_inventory({
		"relics": ["유물1", "유물2", "유물3"],
	})
	if inventory == null:
		return
	var result = inventory.add_relic("유물4")
	assert_true(result["success"], "inventory-006 expected relic add success at three of four")
	assert_eq(inventory.relics.size(), 4, "inventory-006 expected relic count 4")


func _make_inventory(config: Dictionary = {}):
	var script = load(INVENTORY_PATH)
	assert_not_null(script, "expected inventory.gd to exist")
	if script == null:
		return null
	return script.new(config)
