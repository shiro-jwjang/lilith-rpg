extends "res://test/rpg/test_base.gd"

const INVENTORY_PATH := "res://scripts/rpg/inventory/inventory.gd"


func test_inventory_015_same_potion_type_stacks_from_four_to_five() -> void:
	var inventory = _make_inventory({
		"potions": {"소형 치료 물약": 4},
	})
	if inventory == null:
		return
	var result = inventory.add_potion("소형 치료 물약")
	assert_true(result["success"], "inventory-015 expected stack success at four")
	assert_eq(inventory.potions["소형 치료 물약"], 5, "inventory-015 expected stack count 5")


func test_inventory_016_same_potion_type_cannot_exceed_five() -> void:
	var inventory = _make_inventory({
		"potions": {"소형 치료 물약": 5},
	})
	if inventory == null:
		return
	var result = inventory.add_potion("소형 치료 물약")
	assert_false(result["success"], "inventory-016 expected stack failure at five")
	assert_eq(inventory.potions["소형 치료 물약"], 5, "inventory-016 expected stack count to stay 5")


func test_inventory_017_different_potion_types_track_independent_counts() -> void:
	var inventory = _make_inventory({
		"potions": {
			"소형 치료 물약": 5,
			"소형 마나 물약": 2,
			"정화 물약": 3,
		},
	})
	if inventory == null:
		return
	var result = inventory.add_potion("전투 집중 물약")
	assert_true(result["success"], "inventory-017 expected different potion type to add successfully")
	assert_eq(inventory.potions["소형 치료 물약"], 5, "inventory-017 expected heal potion count unchanged")
	assert_eq(inventory.potions["소형 마나 물약"], 2, "inventory-017 expected mana potion count unchanged")
	assert_eq(inventory.potions["정화 물약"], 3, "inventory-017 expected purification potion count unchanged")
	assert_eq(inventory.potions["전투 집중 물약"], 1, "inventory-017 expected focus potion count 1")


func _make_inventory(config: Dictionary = {}):
	var script = load(INVENTORY_PATH)
	assert_not_null(script, "expected inventory.gd to exist")
	if script == null:
		return null
	return script.new(config)
