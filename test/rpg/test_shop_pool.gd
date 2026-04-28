extends "res://test/rpg/test_base.gd"

const SHOP_MANAGER_PATH := "res://scripts/rpg/shop/shop_manager.gd"
const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_shop_001_equipment_pool_count_stays_between_three_and_four() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	for _index in range(1000):
		var visit: Dictionary = manager.visit_shop()
		var equipment_list: Array = visit.get("equipment_list", [])
		assert_ge(equipment_list.size(), 3, "shop-001 expected equipment count >= 3")
		assert_true(equipment_list.size() <= 4, "shop-001 expected equipment count <= 4")


func test_shop_004_relic_pool_always_shows_exactly_two_items_on_first_visit() -> void:
	for _index in range(1000):
		var manager = _make_manager()
		if manager == null:
			return
		var visit: Dictionary = manager.visit_shop()
		var relic_list: Array = visit.get("relic_list", [])
		assert_eq(relic_list.size(), 2, "shop-004 expected exactly two relics on first visit")


func test_shop_008_shop_exposes_all_supported_potion_types() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var visit: Dictionary = manager.visit_shop()
	var potion_list: Array = visit.get("potion_list", [])
	var potion_names := {}
	for potion in potion_list:
		potion_names[String(potion.get("name", ""))] = true
	assert_eq(potion_list.size(), 4, "shop-008 expected exactly four potion entries")
	assert_has(potion_names, "소형 치료 물약", "shop-008 expected healing potion")
	assert_has(potion_names, "소형 마나 물약", "shop-008 expected mana potion")
	assert_has(potion_names, "정화 물약", "shop-008 expected purification potion")
	assert_has(potion_names, "전투 집중 물약", "shop-008 expected focus potion")


func test_shop_010_each_shop_visit_re_rolls_the_equipment_pool() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var first_visit: Dictionary = manager.visit_shop()
	var second_visit: Dictionary = manager.visit_shop()
	assert_ne(
		String(first_visit.get("equipment_roll_id", "")),
		String(second_visit.get("equipment_roll_id", "")),
		"shop-010 expected a new equipment roll id per visit"
	)


func test_shop_013_equipment_pool_can_hit_minimum_boundary_of_three() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var visit: Dictionary = manager.visit_shop({"forced_equipment_count": 3})
	var equipment_list: Array = visit.get("equipment_list", [])
	assert_eq(equipment_list.size(), 3, "shop-013 expected forced minimum equipment count 3")


func test_shop_014_equipment_pool_can_hit_maximum_boundary_of_four() -> void:
	var manager = _make_manager()
	if manager == null:
		return
	var visit: Dictionary = manager.visit_shop({"forced_equipment_count": 4})
	var equipment_list: Array = visit.get("equipment_list", [])
	assert_eq(equipment_list.size(), 4, "shop-014 expected forced maximum equipment count 4")


func _make_manager(config: Dictionary = {}):
	var script = load(SHOP_MANAGER_PATH)
	assert_not_null(script, "expected shop_manager.gd to exist")
	if script == null:
		return null
	if not config.has("wallet"):
		config["wallet"] = _make_wallet(9999)
	return script.new(config)


func _make_wallet(gold: int):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new({"gold": gold})
