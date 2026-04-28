extends "res://test/rpg/test_base.gd"

const HELPER_PATH := "res://test/rpg/map_test_helper.gd"


func test_map_021_act_has_at_least_one_treasure() -> void:
	var act = _generate_act()
	if act.is_empty():
		return
	var helper = _helper()
	assert_ge(helper.count_nodes_of_type(helper.flatten_nodes(act), "treasure"), 1, "map-021 act should have at least one treasure")


func test_map_022_act_has_at_most_two_treasures() -> void:
	var act = _generate_act()
	if act.is_empty():
		return
	var helper = _helper()
	assert_true(helper.count_nodes_of_type(helper.flatten_nodes(act), "treasure") <= 2, "map-022 act should have at most two treasures")


func test_map_023_act_has_at_least_one_shop() -> void:
	var act = _generate_act()
	if act.is_empty():
		return
	var helper = _helper()
	assert_ge(helper.count_nodes_of_type(helper.flatten_nodes(act), "shop"), 1, "map-023 act should have at least one shop")


func test_map_024_act_has_at_least_one_campfire() -> void:
	var act = _generate_act()
	if act.is_empty():
		return
	var helper = _helper()
	assert_ge(helper.count_nodes_of_type(helper.flatten_nodes(act), "campfire"), 1, "map-024 act should have at least one campfire")


func test_map_025_act_has_at_most_two_campfires() -> void:
	var act = _generate_act()
	if act.is_empty():
		return
	var helper = _helper()
	assert_true(helper.count_nodes_of_type(helper.flatten_nodes(act), "campfire") <= 2, "map-025 act should have at most two campfires")


func test_map_026_act_has_exactly_one_unique() -> void:
	var act = _generate_act()
	if act.is_empty():
		return
	var helper = _helper()
	assert_eq(helper.count_nodes_of_type(helper.flatten_nodes(act), "unique"), 1, "map-026 act should have exactly one unique node")


func test_map_027_unique_only_appears_on_floor_two_or_three() -> void:
	var act = _generate_act()
	if act.is_empty():
		return
	for floor in act.get("floors", []):
		for node in floor.nodes:
			if node.type == "unique":
				assert_true(floor.floor_number == 2 or floor.floor_number == 3, "map-027 unique node should only appear on floor 2 or 3")


func test_map_028_unique_is_positioned_immediately_before_boss_when_on_floor_three() -> void:
	var act = _generate_act()
	if act.is_empty():
		return
	var floors: Array = act.get("floors", [])
	var floor_three = floors[2]
	var unique_index := -1
	var boss_index := -1
	for index in range(floor_three.nodes.size()):
		var node = floor_three.nodes[index]
		if node.type == "unique":
			unique_index = index
		elif node.type == "boss":
			boss_index = index
	assert_true(unique_index == -1 or unique_index == boss_index - 1, "map-028 unique should be the pre-boss node when placed on floor 3")


func _generate_act() -> Dictionary:
	var helper = _helper()
	var script = helper.load_script(helper.GENERATOR_PATH)
	assert_not_null(script, "expected map_generator.gd to exist")
	if script == null:
		return {}
	return helper.generate_act()


func _helper():
	return load(HELPER_PATH).new()
