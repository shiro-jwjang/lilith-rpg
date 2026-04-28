extends "res://test/rpg/test_base.gd"

const SHOP_MANAGER_PATH := "res://scripts/rpg/shop/shop_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_shop_006_relics_are_only_shown_once_per_run() -> void:
	var manager = _make_manager({"wallet": _make_wallet(9999)})
	if manager == null:
		return
	var visit_1: Dictionary = manager.visit_shop()
	var visit_2: Dictionary = manager.visit_shop()
	var visit_3: Dictionary = manager.visit_shop()
	assert_true(bool(visit_1.get("relic_pool_visible", false)), "shop-006 expected relic pool on first visit")
	assert_eq((visit_1.get("relic_list", []) as Array).size(), 2, "shop-006 expected two relics on first visit")
	assert_false(bool(visit_2.get("relic_pool_visible", true)), "shop-006 expected relic pool hidden on second visit")
	assert_false(bool(visit_3.get("relic_pool_visible", true)), "shop-006 expected relic pool hidden on third visit")
	assert_eq((visit_2.get("relic_list", []) as Array).size(), 0, "shop-006 expected no relics on second visit")
	assert_eq((visit_3.get("relic_list", []) as Array).size(), 0, "shop-006 expected no relics on third visit")


func test_shop_007_relic_purchase_returns_preview_signal() -> void:
	var wallet = _make_wallet(100)
	var manager = _make_manager({"wallet": wallet})
	if manager == null:
		return
	var visit: Dictionary = manager.visit_shop()
	var relic_list: Array = visit.get("relic_list", [])
	assert_eq(relic_list.size(), 2, "shop-007 expected relics to be available on first visit")
	var result: Dictionary = manager.purchase_item(relic_list[0])
	assert_true(bool(result.get("success", false)), "shop-007 expected relic purchase success")
	assert_true(bool(result.get("relic_preview_displayed", false)), "shop-007 expected relic preview to be displayed")


func test_shop_009_potions_can_be_purchased_without_stock_limit() -> void:
	var wallet = _make_wallet(9999)
	var manager = _make_manager({"wallet": wallet})
	if manager == null:
		return
	var visit: Dictionary = manager.visit_shop()
	var potion = _find_item_by_name(visit.get("potion_list", []), "소형 치료 물약")
	assert_not_null(potion, "shop-009 expected small healing potion to exist")
	if potion == null:
		return
	var purchase_result: Dictionary = {}
	for _index in range(99):
		purchase_result = manager.purchase_item(potion)
		assert_true(bool(purchase_result.get("success", false)), "shop-009 expected unlimited potion purchases")
	assert_eq(int(purchase_result.get("purchased_count", -1)), 99, "shop-009 expected 99 successful potion purchases")
	assert_false(bool(purchase_result.get("stock_limit_reached", false)), "shop-009 expected no stock limit")


func test_shop_011_purchase_fails_when_gold_is_below_price() -> void:
	var wallet = _make_wallet(30)
	var manager = _make_manager({"wallet": wallet})
	if manager == null:
		return
	var result: Dictionary = manager.purchase_item({
		"type": "equipment",
		"name": "테스트 장비",
		"price": 50,
	})
	assert_false(bool(result.get("success", false)), "shop-011 expected purchase failure")
	assert_eq(String(result.get("reason", "")), "insufficient_gold", "shop-011 expected insufficient_gold reason")
	assert_eq(int(wallet.get_gold()), 30, "shop-011 expected gold to remain unchanged")


func test_shop_012_purchase_succeeds_when_gold_exactly_matches_price() -> void:
	var wallet = _make_wallet(45)
	var manager = _make_manager({"wallet": wallet})
	if manager == null:
		return
	var result: Dictionary = manager.purchase_item({
		"type": "equipment",
		"name": "테스트 장비",
		"price": 45,
	})
	assert_true(bool(result.get("success", false)), "shop-012 expected exact-gold purchase success")
	assert_eq(int(wallet.get_gold()), 0, "shop-012 expected gold after purchase 0")


func _make_manager(config: Dictionary = {}):
	var script = load(SHOP_MANAGER_PATH)
	assert_not_null(script, "expected shop_manager.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _find_item_by_name(items: Array, item_name: String):
	for item in items:
		if String(item.get("name", "")) == item_name:
			return item
	return null


func _make_wallet(gold: int):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})
