extends "res://test/rpg/test_base.gd"

const SHOP_POOL_GENERATOR_PATH := "res://scripts/rpg/shop/shop_pool_generator.gd"


func test_shop_002_normal_equipment_prices_stay_within_range() -> void:
	var generator = _make_generator()
	if generator == null:
		return
	for _index in range(1000):
		var equipment_list: Array = generator.generate_equipment_pool({
			"count": 4,
			"tier": "normal",
		})
		for equipment in equipment_list:
			assert_eq(String(equipment.get("tier", "")), "normal", "shop-002 expected normal tier equipment")
			assert_ge(int(equipment.get("price", -1)), 30, "shop-002 expected normal price >= 30")
			assert_true(int(equipment.get("price", -1)) <= 45, "shop-002 expected normal price <= 45")


func test_shop_003_high_equipment_prices_stay_within_range() -> void:
	var generator = _make_generator()
	if generator == null:
		return
	for _index in range(1000):
		var equipment_list: Array = generator.generate_equipment_pool({
			"count": 4,
			"tier": "high",
		})
		for equipment in equipment_list:
			assert_eq(String(equipment.get("tier", "")), "high", "shop-003 expected high tier equipment")
			assert_ge(int(equipment.get("price", -1)), 50, "shop-003 expected high price >= 50")
			assert_true(int(equipment.get("price", -1)) <= 70, "shop-003 expected high price <= 70")


func test_shop_005_relic_prices_stay_within_range() -> void:
	var generator = _make_generator()
	if generator == null:
		return
	for _index in range(1000):
		var relic_list: Array = generator.generate_relic_pool()
		assert_eq(relic_list.size(), 2, "shop-005 expected exactly two relics per pool")
		for relic in relic_list:
			assert_ge(int(relic.get("price", -1)), 60, "shop-005 expected relic price >= 60")
			assert_true(int(relic.get("price", -1)) <= 90, "shop-005 expected relic price <= 90")


func _make_generator(config: Dictionary = {}):
	var script = load(SHOP_POOL_GENERATOR_PATH)
	assert_not_null(script, "expected shop_pool_generator.gd to exist")
	if script == null:
		return null
	return script.new(config)
