extends "res://test/rpg/test_base.gd"

const INVENTORY_PATH := "res://scripts/rpg/inventory/inventory.gd"


func test_inventory_029_inventory_snapshot_can_hold_max_equipment_relics_and_all_potions() -> void:
	var inventory = _make_inventory({
		"equipment": ["장비1", "장비2", "장비3", "장비4", "장비5", "장비6"],
		"relics": ["유물1", "유물2", "유물3", "유물4"],
		"potions": {
			"소형 치료 물약": 5,
			"소형 마나 물약": 5,
			"정화 물약": 5,
			"전투 집중 물약": 5,
		},
	})
	if inventory == null:
		return
	assert_eq(inventory.equipment.size(), 6, "inventory-029 expected equipment to be full")
	assert_eq(inventory.relics.size(), 4, "inventory-029 expected relics to be full")
	for potion_name in inventory.potions:
		assert_eq(inventory.potions[potion_name], 5, "inventory-029 expected all potion types to be maxed")


func test_inventory_030_reset_for_new_run_clears_only_relics() -> void:
	var inventory = _make_inventory({
		"equipment": ["장비1", "장비2", "장비3", "장비4"],
		"relics": ["유물1", "유물2", "유물3"],
		"potions": {"소형 치료 물약": 2},
	})
	if inventory == null:
		return
	inventory.reset_for_new_run()
	assert_eq(inventory.equipment.size(), 4, "inventory-030 expected equipment to be preserved")
	assert_eq(inventory.relics.size(), 0, "inventory-030 expected relics to be cleared")
	assert_eq(inventory.potions["소형 치료 물약"], 2, "inventory-030 expected potions to be preserved")


func _make_inventory(config: Dictionary = {}):
	var script = load(INVENTORY_PATH)
	assert_not_null(script, "expected inventory.gd to exist")
	if script == null:
		return null
	return script.new(config)
