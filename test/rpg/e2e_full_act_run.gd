extends "res://test/rpg/e2e_support.gd"


func test_e2e_001_complete_three_floor_act_run_tracks_gold_hp_and_floor_completion() -> void:
	var act := _generate_act()
	if act.is_empty():
		return
	_assign_real_event_ids(act)

	var manager = _make_map_manager(act)
	var pipeline = _make_map_pipeline(manager)
	var reward_manager = _reward_manager()
	var reward_generator = _reward_generator({"rng": _SequenceRng.new([120, 0.10])})
	if manager == null or pipeline == null or reward_manager == null or reward_generator == null:
		return

	var player := _make_player({"hp": 60.0, "gold": 80})
	var run_inventory = _RunInventory.new(0, {"wallet": player["wallet"]})
	var campfire = _campfire_manager()
	var shop = _shop_manager({"wallet": player["wallet"], "seed": 7})
	if campfire == null or shop == null:
		return

	var floor_one = manager.get_current_floor()
	var campfire_node = _find_node_by_type(floor_one, "campfire")
	assert_not_null(campfire_node, "e2e-001 expected campfire node on floor 1")
	if campfire_node == null:
		return
	var select_one: Dictionary = pipeline.select_node(campfire_node.id)
	assert_true(bool(select_one.get("ok", false)), "e2e-001 expected floor 1 campfire selection")
	var rested: Dictionary = campfire.rest(player)
	player = rested.get("player", {}).duplicate(true)
	var rested_hp := float(player.get("hp", 0.0))
	var invested: Dictionary = campfire.invest_stat(player, "strength")
	assert_true(bool(invested.get("success", false)), "e2e-001 expected campfire invest success")
	player = invested.get("player", {}).duplicate(true)
	pipeline.complete_node({"result": "campfire", "rewards": []})
	assert_true(pipeline.advance(), "e2e-001 expected advance to floor 2")

	var floor_two = manager.get_current_floor()
	var shop_node = _find_node_by_type(floor_two, "shop")
	assert_not_null(shop_node, "e2e-001 expected shop node on floor 2")
	if shop_node == null:
		return
	var select_two: Dictionary = pipeline.select_node(shop_node.id)
	assert_true(bool(select_two.get("ok", false)), "e2e-001 expected floor 2 shop selection")
	var visit: Dictionary = shop.visit_shop()
	var potion = _find_item_by_name(visit.get("potion_list", []), "소형 치료 물약")
	assert_not_null(potion, "e2e-001 expected shop potion to exist")
	if potion == null:
		return
	var purchase: Dictionary = shop.purchase_item(potion)
	assert_true(bool(purchase.get("success", false)), "e2e-001 expected potion purchase success")
	run_inventory.add_potion("소형 치료 물약")
	pipeline.complete_node({"result": "shop", "rewards": [purchase.get("item", {})]})
	assert_true(pipeline.advance(), "e2e-001 expected advance to floor 3")

	var floor_three = manager.get_current_floor()
	var boss_node = _find_node_by_type(floor_three, "boss")
	assert_not_null(boss_node, "e2e-001 expected boss node on floor 3")
	if boss_node == null:
		return
	var select_three: Dictionary = pipeline.select_node(boss_node.id)
	assert_true(bool(select_three.get("ok", false)), "e2e-001 expected floor 3 boss selection")
	var content = _content()
	if content == null:
		return
	var boss_data: Dictionary = content.get_boss()
	var boss_summary: Dictionary = _run_battle(_build_allies_from_player(player), [_enemy_config(boss_data, 301)])
	if boss_summary.is_empty():
		return
	assert_eq(String(boss_summary.get("winner", "")), "victory", "e2e-001 expected boss victory")
	var boss_rewards: Dictionary = reward_generator.generate_rewards("boss")
	var grant_result: Dictionary = _grant_rewards_to_run(reward_manager, run_inventory, boss_rewards, player)
	assert_true(bool(grant_result.get("success", false)), "e2e-001 expected boss rewards to grant")
	pipeline.complete_node({"result": "victory", "rewards": [boss_rewards]})

	assert_gt(int(player["wallet"].get_gold()), 80, "e2e-001 expected total gold to end above starting gold")
	assert_gt(rested_hp, 60.0, "e2e-001 expected campfire to heal HP")
	assert_eq(manager.current_floor_number, 3, "e2e-001 expected current floor 3 after run")
	assert_eq(pipeline.displayed_floor, 3, "e2e-001 expected displayed floor 3 after run")
	assert_false(pipeline.advance(), "e2e-001 expected no floor after boss floor")


func test_e2e_002_full_route_can_chain_combat_event_and_treasure_nodes() -> void:
	var act := _generate_act()
	if act.is_empty():
		return
	_assign_real_event_ids(act)

	var manager = _make_map_manager(act)
	var pipeline = _make_map_pipeline(manager)
	var reward_manager = _reward_manager()
	var reward_generator = _reward_generator({"rng": _SequenceRng.new([20, 0.10, 40])})
	var event_manager = _event_manager({"rng": _SequenceRng.new([0.10])})
	var relic_manager = _relic_manager()
	if manager == null or pipeline == null or reward_manager == null or reward_generator == null or event_manager == null or relic_manager == null:
		return

	var player := _make_player({"hp": 90.0, "gold": 80})
	var run_inventory = _RunInventory.new(0, {"wallet": player["wallet"]})

	var floor_one = manager.get_current_floor()
	var combat_node = _find_node_by_type(floor_one, "combat")
	assert_not_null(combat_node, "e2e-002 expected combat node on floor 1")
	if combat_node == null:
		return
	assert_true(bool(pipeline.select_node(combat_node.id).get("ok", false)), "e2e-002 expected combat selection")
	var content = _content()
	if content == null:
		return
	var normal_enemy: Dictionary = content.get_enemy_by_name("녹슨 검병")
	var combat_summary: Dictionary = _run_battle(_build_allies_from_player(player), [_enemy_config(normal_enemy, 101)])
	assert_eq(String(combat_summary.get("winner", "")), "victory", "e2e-002 expected floor 1 victory")
	var combat_rewards: Dictionary = reward_generator.generate_rewards("normal")
	_grant_rewards_to_run(reward_manager, run_inventory, combat_rewards, player)
	player["battle_wins"] = int(player.get("battle_wins", 0)) + 1
	pipeline.complete_node({"result": "victory", "rewards": [combat_rewards]})
	assert_true(pipeline.advance(), "e2e-002 expected advance to floor 2")

	var floor_two = manager.get_current_floor()
	var event_node = _find_node_by_type(floor_two, "event")
	assert_not_null(event_node, "e2e-002 expected event node on floor 2")
	if event_node == null:
		return
	assert_true(bool(pipeline.select_node(event_node.id).get("ok", false)), "e2e-002 expected event selection")
	player["visit_count"] = int(player.get("visit_count", 0)) + 1
	var event_result: Dictionary = event_manager.resolve_choice(String(event_node.event_id), "구매", _event_context(String(event_node.event_id), player))
	_apply_event_result_to_player(player, event_result)
	_apply_event_reward_to_run(event_result, run_inventory, relic_manager)
	pipeline.complete_node({"result": "event", "rewards": [event_result.get("reward", {})]})
	assert_true(pipeline.advance(), "e2e-002 expected advance to floor 3")

	var floor_three = manager.get_current_floor()
	var treasure_node = _find_node_by_type(floor_three, "treasure")
	assert_not_null(treasure_node, "e2e-002 expected treasure node on floor 3")
	if treasure_node == null:
		return
	assert_true(bool(pipeline.select_node(treasure_node.id).get("ok", false)), "e2e-002 expected treasure selection")
	var treasure_rewards := {"gold": 40, "items": [], "relics": []}
	var treasure_grant: Dictionary = _grant_rewards_to_run(reward_manager, run_inventory, treasure_rewards, player)
	assert_true(bool(treasure_grant.get("success", false)), "e2e-002 expected treasure grant success")
	pipeline.complete_node({"result": "treasure", "rewards": [treasure_rewards]})

	assert_gt(int(player["wallet"].get_gold()), 80, "e2e-002 expected gold gain across route")
	assert_true(run_inventory.equipment_count() + run_inventory.potion_count("소형 치료 물약") >= 1, "e2e-002 expected event reward to persist")
	assert_eq(manager.current_floor_number, 3, "e2e-002 expected floor 3 completion")


func test_e2e_003_generated_act_contains_all_e2e_interaction_node_types() -> void:
	var act := _generate_act()
	if act.is_empty():
		return

	var found_types := {}
	for floor in act.get("floors", []):
		for node in floor.nodes:
			found_types[String(node.type)] = true

	for required_type in ["combat", "event", "campfire", "shop", "treasure", "boss"]:
		assert_true(bool(found_types.get(required_type, false)), "e2e-003 expected node type %s in generated act" % required_type)


func _find_item_by_name(items: Array, item_name: String):
	for item in items:
		if String(item.get("name", "")) == item_name:
			return item
	return null
