extends "res://test/rpg/test_base.gd"

const INVENTORY_PATH := "res://scripts/rpg/inventory/inventory.gd"
const REGISTRY_PATH := "res://scripts/rpg/inventory/potion_registry.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_inventory_009_buy_small_healing_potion_spends_15_gold() -> void:
	var inventory = _make_inventory()
	if inventory == null:
		return
	var wallet = _make_wallet(50)
	inventory.wallet = wallet
	var result = inventory.add_potion("소형 치료 물약", true)
	assert_true(result["success"], "inventory-009 expected potion purchase success")
	assert_eq(result["cost"], 15, "inventory-009 expected cost 15")
	assert_eq(int(wallet.get_gold()), 35, "inventory-009 expected gold after purchase 35")
	assert_eq(inventory.potions["소형 치료 물약"], 1, "inventory-009 expected potion count 1")


func test_inventory_010_buy_small_mana_potion_spends_20_gold() -> void:
	var inventory = _make_inventory()
	if inventory == null:
		return
	var wallet = _make_wallet(50)
	inventory.wallet = wallet
	var result = inventory.add_potion("소형 마나 물약", true)
	assert_true(result["success"], "inventory-010 expected potion purchase success")
	assert_eq(result["cost"], 20, "inventory-010 expected cost 20")
	assert_eq(int(wallet.get_gold()), 30, "inventory-010 expected gold after purchase 30")
	assert_eq(inventory.potions["소형 마나 물약"], 1, "inventory-010 expected potion count 1")


func test_inventory_011_buy_purification_potion_spends_20_gold() -> void:
	var inventory = _make_inventory()
	if inventory == null:
		return
	var wallet = _make_wallet(50)
	inventory.wallet = wallet
	var result = inventory.add_potion("정화 물약", true)
	assert_true(result["success"], "inventory-011 expected potion purchase success")
	assert_eq(result["cost"], 20, "inventory-011 expected cost 20")
	assert_eq(int(wallet.get_gold()), 30, "inventory-011 expected gold after purchase 30")
	assert_eq(inventory.potions["정화 물약"], 1, "inventory-011 expected potion count 1")


func test_inventory_012_buy_focus_potion_spends_25_gold() -> void:
	var inventory = _make_inventory()
	if inventory == null:
		return
	var wallet = _make_wallet(50)
	inventory.wallet = wallet
	var result = inventory.add_potion("전투 집중 물약", true)
	assert_true(result["success"], "inventory-012 expected potion purchase success")
	assert_eq(result["cost"], 25, "inventory-012 expected cost 25")
	assert_eq(int(wallet.get_gold()), 25, "inventory-012 expected gold after purchase 25")
	assert_eq(inventory.potions["전투 집중 물약"], 1, "inventory-012 expected potion count 1")


func test_inventory_013_registry_exposes_only_four_supported_potions() -> void:
	var registry = _make_registry()
	if registry == null:
		return
	var all_potions = registry.get_all_potions()
	assert_eq(all_potions.size(), 4, "inventory-013 expected exactly four supported potion definitions")
	assert_has(all_potions, "소형 치료 물약", "inventory-013 expected healing potion in registry")
	assert_has(all_potions, "소형 마나 물약", "inventory-013 expected mana potion in registry")
	assert_has(all_potions, "정화 물약", "inventory-013 expected purification potion in registry")
	assert_has(all_potions, "전투 집중 물약", "inventory-013 expected focus potion in registry")


func test_inventory_014_registry_omits_removed_potion_definitions() -> void:
	var registry = _make_registry()
	if registry == null:
		return
	assert_null(registry.get_potion("중형 체력 물약"), "inventory-014 expected removed medium heal potion to be absent")
	assert_null(registry.get_potion("중형 마나 물약"), "inventory-014 expected removed medium mana potion to be absent")


func test_inventory_026_buy_fails_when_gold_is_one_short_of_cost() -> void:
	var inventory = _make_inventory()
	if inventory == null:
		return
	var wallet = _make_wallet(14)
	inventory.wallet = wallet
	var result = inventory.add_potion("소형 치료 물약", true)
	assert_false(result["success"], "inventory-026 expected purchase to fail with 14 gold")
	assert_eq(int(wallet.get_gold()), 14, "inventory-026 expected gold to remain unchanged")
	assert_false(inventory.potions.has("소형 치료 물약"), "inventory-026 expected no potion to be added")


func test_inventory_027_buy_succeeds_when_gold_exactly_matches_cost() -> void:
	var inventory = _make_inventory()
	if inventory == null:
		return
	var wallet = _make_wallet(15)
	inventory.wallet = wallet
	var result = inventory.add_potion("소형 치료 물약", true)
	assert_true(result["success"], "inventory-027 expected exact-gold purchase success")
	assert_eq(int(wallet.get_gold()), 0, "inventory-027 expected gold after purchase 0")
	assert_eq(inventory.potions["소형 치료 물약"], 1, "inventory-027 expected potion count 1")


func _make_inventory(config: Dictionary = {}):
	var script = load(INVENTORY_PATH)
	assert_not_null(script, "expected inventory.gd to exist")
	if script == null:
		return null
	return script.new(config)


func _make_registry():
	var script = load(REGISTRY_PATH)
	assert_not_null(script, "expected potion_registry.gd to exist")
	if script == null:
		return null
	return script.new()


func _make_wallet(gold: int):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})
