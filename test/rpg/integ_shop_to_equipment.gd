extends "res://test/rpg/test_base.gd"

const EQUIPMENT_INSTANCE_PATH := "res://scripts/rpg/equipment/equipment_instance.gd"
const EQUIPMENT_MANAGER_PATH := "res://scripts/rpg/equipment/equipment_manager.gd"
const SHOP_MANAGER_PATH := "res://scripts/rpg/shop/shop_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_integ_010_shop_purchase_reduces_gold_for_equipment_item() -> void:
	var wallet = _make_wallet(100)
	var shop = _shop_manager(wallet, 7)
	if shop == null:
		return

	var visit: Dictionary = shop.visit_shop({"forced_equipment_count": 3})
	var item: Dictionary = (visit.get("equipment_list", []) as Array)[0]
	var purchase: Dictionary = shop.purchase_item(item)
	assert_true(bool(purchase.get("success", false)), "integ-010 expected equipment purchase success")
	assert_true(int(wallet.get_gold()) < 100, "integ-010 expected shop gold to decrease")
	assert_eq(String(purchase.get("item", {}).get("name", "")), String(item.get("name", "")), "integ-010 expected purchased item to echo the selected equipment")


func test_integ_011_purchased_equipment_can_be_added_to_inventory_manager() -> void:
	var wallet = _make_wallet(100)
	var shop = _shop_manager(wallet, 7)
	var equipment_manager = _equipment_manager()
	if shop == null or equipment_manager == null:
		return

	var visit: Dictionary = shop.visit_shop({"forced_equipment_count": 3})
	var item_data: Dictionary = (visit.get("equipment_list", []) as Array)[0]
	var purchase: Dictionary = shop.purchase_item(item_data)
	assert_true(bool(purchase.get("success", false)), "integ-011 expected purchase success")

	var item = _equipment_item(String(item_data.get("name", "")))
	var add_result: Dictionary = equipment_manager.add_to_inventory(item)
	assert_true(bool(add_result.get("success", false)), "integ-011 expected item add success")
	assert_eq(equipment_manager.get_inventory().size(), 1, "integ-011 expected inventory size 1 after add")


func test_integ_012_purchased_equipment_can_be_equipped_and_changes_stats() -> void:
	var wallet = _make_wallet(100)
	var shop = _shop_manager(wallet, 11)
	var equipment_manager = _equipment_manager()
	if shop == null or equipment_manager == null:
		return

	var visit: Dictionary = shop.visit_shop({"forced_equipment_count": 4})
	var equipment_list: Array = visit.get("equipment_list", [])
	var chosen_item: Dictionary = _first_item_with_slot(equipment_list, "weapon")
	assert_true(not chosen_item.is_empty(), "integ-012 expected at least one weapon in the shop")
	if chosen_item.is_empty():
		return

	var purchase: Dictionary = shop.purchase_item(chosen_item)
	assert_true(bool(purchase.get("success", false)), "integ-012 expected purchase success")
	var item = _equipment_item(String(chosen_item.get("name", "")))
	var stats_before: Dictionary = {}
	var add_result: Dictionary = equipment_manager.add_to_inventory(item)
	assert_true(bool(add_result.get("success", false)), "integ-012 expected add success before equip")
	var equip_result: Dictionary = equipment_manager.equip_item(item)
	var equipped_stats: Dictionary = equipment_manager.get_equipped()["weapon"].get_stats()

	assert_true(bool(equip_result.get("success", false)), "integ-012 expected equip success")
	assert_eq(String(equipment_manager.get_equipped()["weapon"].get_name()), String(chosen_item.get("name", "")), "integ-012 expected selected item to be equipped")
	assert_true(equipped_stats.size() > stats_before.size(), "integ-012 expected equipped item stats to be populated")
	assert_true(_sum_numeric_stats(equipped_stats) > 0.0, "integ-012 expected equipped stats to change player state")


func _shop_manager(wallet, seed: int):
	var script = load(SHOP_MANAGER_PATH)
	assert_not_null(script, "expected shop_manager.gd to exist")
	if script == null:
		return null
	return script.new({
		"wallet": wallet,
		"seed": seed,
	})


func _equipment_manager():
	var script = load(EQUIPMENT_MANAGER_PATH)
	assert_not_null(script, "expected equipment_manager.gd to exist")
	if script == null:
		return null
	return script.new({"wallet": _make_wallet(9999)})


func _equipment_item(item_name: String):
	var script = load(EQUIPMENT_INSTANCE_PATH)
	assert_not_null(script, "expected equipment_instance.gd to exist")
	if script == null:
		return null
	return script.new(item_name, 0)


func _first_item_with_slot(items: Array, slot_name: String) -> Dictionary:
	for item in items:
		var instance = _equipment_item(String(item.get("name", "")))
		if instance != null and instance.get_slot() == slot_name:
			return item.duplicate(true)
	return {}


func _sum_numeric_stats(stats: Dictionary) -> float:
	var total := 0.0
	for key in stats:
		var value = stats[key]
		if value is int or value is float:
			total += float(value)
	return total


func _make_wallet(gold: int):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})
