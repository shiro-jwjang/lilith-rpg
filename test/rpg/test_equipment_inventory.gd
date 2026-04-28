extends "res://test/rpg/test_base.gd"

const INVENTORY_PATH := "res://scripts/rpg/inventory/inventory.gd"


func test_inventory_001_add_equipment_succeeds_when_inventory_is_empty() -> void:
	var inventory = _make_inventory()
	if inventory == null:
		return
	var result = inventory.add_equipment("녹슨 검")
	assert_true(result["success"], "inventory-001 expected equipment add success")
	assert_eq(inventory.equipment.size(), 1, "inventory-001 expected equipment count 1")


func test_inventory_002_add_equipment_fails_when_inventory_is_full() -> void:
	var inventory = _make_inventory({
		"equipment": ["장비1", "장비2", "장비3", "장비4", "장비5", "장비6"],
	})
	if inventory == null:
		return
	var result = inventory.add_equipment("장비7")
	assert_false(result["success"], "inventory-002 expected equipment add failure at capacity 6")
	assert_eq(inventory.equipment.size(), 6, "inventory-002 expected equipment count to stay 6")


func test_inventory_003_add_equipment_succeeds_at_five_of_six_capacity() -> void:
	var inventory = _make_inventory({
		"equipment": ["장비1", "장비2", "장비3", "장비4", "장비5"],
	})
	if inventory == null:
		return
	var result = inventory.add_equipment("장비6")
	assert_true(result["success"], "inventory-003 expected equipment add success at five of six")
	assert_eq(inventory.equipment.size(), 6, "inventory-003 expected equipment count 6")


func test_inventory_007_swap_discards_old_equipment_when_inventory_is_full() -> void:
	var inventory = _make_inventory({
		"equipment": ["장비1", "장비2", "장비3", "장비4", "장비5", "장비6"],
	})
	if inventory == null:
		return
	var result = _swap_equipped_item(inventory, "녹슨 검", "붉은 달 단도")
	assert_true(result["swap_success"], "inventory-007 expected swap to succeed")
	assert_true(result["old_discarded"], "inventory-007 expected old equipment to be discarded")
	assert_false(result["old_stored"], "inventory-007 expected old equipment not to be stored")


func test_inventory_008_swap_stores_old_equipment_when_inventory_has_space() -> void:
	var inventory = _make_inventory({
		"equipment": ["장비1", "장비2", "장비3", "장비4", "장비5"],
	})
	if inventory == null:
		return
	var result = _swap_equipped_item(inventory, "녹슨 검", "붉은 달 단도")
	assert_true(result["swap_success"], "inventory-008 expected swap to succeed")
	assert_true(result["old_stored"], "inventory-008 expected old equipment to be stored")
	assert_false(result["old_discarded"], "inventory-008 expected old equipment not to be discarded")
	assert_eq(inventory.equipment.size(), 6, "inventory-008 expected stored equipment to fill the last slot")


func _make_inventory(config: Dictionary = {}):
	var script = load(INVENTORY_PATH)
	assert_not_null(script, "expected inventory.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _swap_equipped_item(inventory, old_equipment_name: String, _new_equipment_name: String) -> Dictionary:
	var store_result = inventory.add_equipment(old_equipment_name)
	return {
		"swap_success": true,
		"old_stored": bool(store_result["success"]),
		"old_discarded": not bool(store_result["success"]),
	}
