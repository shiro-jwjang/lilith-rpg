extends "res://test/rpg/e2e_support.gd"


func test_e2e_009_shop_campfire_combat_chain_preserves_expected_gold_formula() -> void:
	var player := _make_player({"hp": 60.0, "gold": 80, "strength": 5})
	var run_inventory = _RunInventory.new(0, {"wallet": player["wallet"]})
	var shop = _shop_manager({"wallet": player["wallet"], "seed": 9})
	var campfire = _campfire_manager()
	var reward_manager = _reward_manager()
	var reward_generator = _reward_generator({"rng": _SequenceRng.new([20, 0.10])})
	if shop == null or campfire == null or reward_manager == null or reward_generator == null:
		return

	var visit: Dictionary = shop.visit_shop()
	var potion = _find_item_by_name(visit.get("potion_list", []), "소형 치료 물약")
	assert_not_null(potion, "e2e-009 expected potion to exist in shop")
	if potion == null:
		return
	var potion_cost := int(potion.get("price", 0))
	var purchase: Dictionary = shop.purchase_item(potion)
	assert_true(bool(purchase.get("success", false)), "e2e-009 expected potion purchase")
	run_inventory.add_potion("소형 치료 물약")
		
	var rested: Dictionary = campfire.rest(player)
	player = rested.get("player", {}).duplicate(true)
	var invested: Dictionary = campfire.invest_stat(player, "strength")
	assert_true(bool(invested.get("success", false)), "e2e-009 expected invest success")
	player = invested.get("player", {}).duplicate(true)
	var content = _content()
	if content == null:
		return
	var enemy_data: Dictionary = content.get_enemy_by_name("녹슨 검병")
	var combat_summary: Dictionary = _run_battle(_build_allies_from_player(player), [_enemy_config(enemy_data, 501)])
	assert_eq(String(combat_summary.get("winner", "")), "victory", "e2e-009 expected combat victory")
	var rewards: Dictionary = reward_generator.generate_rewards("normal")
	var reward_amount := int(rewards.get("gold", 0))
	_grant_rewards_to_run(reward_manager, run_inventory, rewards, player)

	var expected_gold := 80 - potion_cost - 25 + reward_amount
	assert_eq(int(player["wallet"].get_gold()), expected_gold, "e2e-009 expected exact end gold formula")
	assert_eq(run_inventory.potion_count("소형 치료 물약"), 1, "e2e-009 expected potion kept in inventory")


func test_e2e_010_shop_campfire_combat_chain_ends_with_hp_between_rest_and_max() -> void:
	var player := _make_player({"hp": 60.0, "gold": 80})
	var shop = _shop_manager({"wallet": player["wallet"], "seed": 9})
	var campfire = _campfire_manager()
	if shop == null or campfire == null:
		return

	var potion = _find_item_by_name(shop.visit_shop().get("potion_list", []), "소형 치료 물약")
	assert_not_null(potion, "e2e-010 expected potion in shop")
	if potion == null:
		return
	shop.purchase_item(potion)
	player = campfire.rest(player).get("player", {}).duplicate(true)
	player = campfire.invest_stat(player, "strength").get("player", {}).duplicate(true)

	var content = _content()
	if content == null:
		return
	var enemy_data: Dictionary = content.get_enemy_by_name("녹슨 검병")
	var summary: Dictionary = _run_battle(_build_allies_from_player(player), [_enemy_config(enemy_data, 502)])
	if summary.is_empty():
		return

	assert_true(int(summary.get("front_ally_final_hp", 0)) < 100, "e2e-010 expected combat damage after rest")
	assert_true(int(summary.get("front_ally_final_hp", 0)) > 60, "e2e-010 expected campfire healing to matter")


func test_e2e_011_shop_campfire_combat_chain_rest_heals_exactly_thirty_five_hp_before_battle() -> void:
	var player := _make_player({"hp": 60.0, "gold": 80})
	var campfire = _campfire_manager()
	if campfire == null:
		return

	var rested: Dictionary = campfire.rest(player)
	assert_eq(int(rested.get("healed", 0)), 35, "e2e-011 expected 35 HP heal at campfire")
	assert_true(abs(float(rested.get("player", {}).get("hp", 0.0)) - 95.0) < 0.001, "e2e-011 expected HP 95 after rest")


func _find_item_by_name(items: Array, item_name: String):
	for item in items:
		if String(item.get("name", "")) == item_name:
			return item
	return null
