extends "res://test/rpg/e2e_support.gd"


func test_e2e_012_generated_act_places_boss_node_on_floor_three() -> void:
	var act := _generate_act()
	if act.is_empty():
		return

	var floor_three = act.get("floors", [])[2]
	var boss_node = _find_node_by_type(floor_three, "boss")
	assert_not_null(boss_node, "e2e-012 expected boss node on floor 3")


func test_e2e_013_full_act_culminates_in_boss_battle_longer_than_floor_one_combat() -> void:
	var act := _generate_act()
	if act.is_empty():
		return
	var manager = _make_map_manager(act)
	var pipeline = _make_map_pipeline(manager)
	var reward_manager = _reward_manager()
	var reward_generator = _reward_generator({"rng": _SequenceRng.new([20, 25, 120, 0.10])})
	if manager == null or pipeline == null or reward_manager == null or reward_generator == null:
		return

	var player := _make_player({"hp": 100.0, "gold": 50})
	var run_inventory = _RunInventory.new(0, {"wallet": player["wallet"]})
	var floor_one_normal_turns := 0

	for floor_number in [1, 2]:
		var floor = manager.get_current_floor()
		var combat_node = _find_node_by_type(floor, "combat")
		assert_not_null(combat_node, "e2e-013 expected combat node on floor %d" % floor_number)
		if combat_node == null:
			return
		assert_true(bool(pipeline.select_node(combat_node.id).get("ok", false)), "e2e-013 expected combat selection on floor %d" % floor_number)
		var enemy_name := "녹슨 검병"
		if floor_number == 2:
			enemy_name = "철갑 감시자"
		var content = _content()
		if content == null:
			return
		var enemy_data: Dictionary = content.get_enemy_by_name(enemy_name)
		var summary: Dictionary = _run_battle(_build_allies_from_player(player), [_enemy_config(enemy_data, 600 + floor_number)])
		assert_eq(String(summary.get("winner", "")), "victory", "e2e-013 expected floor %d victory" % floor_number)
		if floor_number == 1:
			floor_one_normal_turns = int(summary.get("turns", 0))
		var battle_type := "normal"
		if floor_number == 2:
			battle_type = "elite"
		var rewards: Dictionary = reward_generator.generate_rewards(battle_type)
		_grant_rewards_to_run(reward_manager, run_inventory, rewards, player)
		player["battle_wins"] = int(player.get("battle_wins", 0)) + 1
		pipeline.complete_node({"result": "victory", "rewards": [rewards]})
		assert_true(pipeline.advance(), "e2e-013 expected floor advance from floor %d" % floor_number)

	var floor_three = manager.get_current_floor()
	var boss_node = _find_node_by_type(floor_three, "boss")
	assert_not_null(boss_node, "e2e-013 expected boss node on floor 3")
	if boss_node == null:
		return
	assert_true(bool(pipeline.select_node(boss_node.id).get("ok", false)), "e2e-013 expected boss selection")
	var boss_content = _content()
	if boss_content == null:
		return
	var boss_data: Dictionary = boss_content.get_boss()
	var boss_summary: Dictionary = _run_battle(_build_allies_from_player(player), [_enemy_config(boss_data, 603)])
	if boss_summary.is_empty():
		return
	assert_eq(String(boss_summary.get("winner", "")), "victory", "e2e-013 expected boss victory")
	assert_eq(int(boss_data.get("max_hp", 0)), 450, "e2e-013 expected boss HP 450")
	assert_gt(int(boss_summary.get("turns", 0)), floor_one_normal_turns, "e2e-013 expected boss fight to take longer than floor 1")


func test_e2e_014_full_boss_act_accumulates_gold_across_all_floors() -> void:
	var act := _generate_act()
	if act.is_empty():
		return
	var manager = _make_map_manager(act)
	var pipeline = _make_map_pipeline(manager)
	var reward_manager = _reward_manager()
	var reward_generator = _reward_generator({"rng": _SequenceRng.new([20, 60, 120, 0.10])})
	if manager == null or pipeline == null or reward_manager == null or reward_generator == null:
		return

	var player := _make_player({"hp": 100.0, "gold": 10})
	var run_inventory = _RunInventory.new(0, {"wallet": player["wallet"]})

	for floor_number in [1, 2]:
		var floor = manager.get_current_floor()
		var combat_node = _find_node_by_type(floor, "combat")
		if combat_node == null:
			return
		assert_true(bool(pipeline.select_node(combat_node.id).get("ok", false)), "e2e-014 expected selection on floor %d" % floor_number)
		var battle_type := "normal"
		var enemy_name := "녹슨 검병"
		if floor_number == 2:
			battle_type = "elite"
			enemy_name = "철갑 감시자"
		var content = _content()
		if content == null:
			return
		var enemy_data: Dictionary = content.get_enemy_by_name(enemy_name)
		var summary: Dictionary = _run_battle(_build_allies_from_player(player), [_enemy_config(enemy_data, 700 + floor_number)])
		assert_eq(String(summary.get("winner", "")), "victory", "e2e-014 expected floor %d victory" % floor_number)
		var rewards: Dictionary = reward_generator.generate_rewards(battle_type)
		_grant_rewards_to_run(reward_manager, run_inventory, rewards, player)
		pipeline.complete_node({"result": "victory", "rewards": [rewards]})
		assert_true(pipeline.advance(), "e2e-014 expected advance from floor %d" % floor_number)

	var boss_node = _find_node_by_type(manager.get_current_floor(), "boss")
	assert_not_null(boss_node, "e2e-014 expected boss node")
	if boss_node == null:
		return
	assert_true(bool(pipeline.select_node(boss_node.id).get("ok", false)), "e2e-014 expected boss selection")
	var boss_content = _content()
	if boss_content == null:
		return
	var boss_data: Dictionary = boss_content.get_boss()
	var boss_summary: Dictionary = _run_battle(_build_allies_from_player(player), [_enemy_config(boss_data, 703)])
	assert_eq(String(boss_summary.get("winner", "")), "victory", "e2e-014 expected boss victory")
	var boss_rewards: Dictionary = reward_generator.generate_rewards("boss")
	_grant_rewards_to_run(reward_manager, run_inventory, boss_rewards, player)

	assert_gt(int(player["wallet"].get_gold()), 10, "e2e-014 expected gold to accumulate across act")
