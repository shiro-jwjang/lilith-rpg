extends RefCounted


func validate_act(act: Dictionary) -> Dictionary:
	var errors: Array = []
	var floors: Array = act.get("floors", [])
	var nodes := _flatten_nodes(floors)

	var treasure_total := _count_type(nodes, "treasure")
	if treasure_total < 1:
		errors.append("treasure_minimum")
	if treasure_total > 2:
		errors.append("treasure_maximum")

	var shop_total := _count_type(nodes, "shop")
	if shop_total < 1:
		errors.append("shop_minimum")

	var campfire_total := _count_type(nodes, "campfire")
	if campfire_total < 1:
		errors.append("campfire_minimum")
	if campfire_total > 2:
		errors.append("campfire_maximum")

	var unique_total := _count_type(nodes, "unique")
	if unique_total != 1:
		errors.append("unique_exactly_one")

	for floor in floors:
		if floor.floor_number == 1 and _count_type(floor.nodes, "unique") > 0:
			errors.append("unique_floor")
			break

	var floor_three = _find_floor(floors, 3)
	if floor_three == null or _count_type(floor_three.nodes, "boss") != 1:
		errors.append("boss_required")

	if floor_three != null:
		var unique_index := _find_index_by_type(floor_three.nodes, "unique")
		var boss_index := _find_index_by_type(floor_three.nodes, "boss")
		if unique_index != -1 and boss_index != -1 and unique_index != boss_index - 1:
			errors.append("unique_pre_boss")

	var event_catalog: Array = act.get("event_catalog", [])
	if _has_duplicates(event_catalog):
		errors.append("event_duplicate")

	var previous_floor_events := {}
	for floor in floors:
		var current_floor_events := {}
		for node in floor.nodes:
			if node.type != "event" or String(node.event_id).is_empty():
				continue
			if previous_floor_events.has(node.event_id):
				errors.append("event_consecutive_floor")
				break
			current_floor_events[node.event_id] = true
		previous_floor_events = current_floor_events

	return {
		"ok": errors.is_empty(),
		"errors": errors,
	}


func _flatten_nodes(floors: Array) -> Array:
	var nodes: Array = []
	for floor in floors:
		for node in floor.nodes:
			nodes.append(node)
	return nodes


func _count_type(nodes: Array, node_type: String) -> int:
	var count := 0
	for node in nodes:
		if node.type == node_type:
			count += 1
	return count


func _find_floor(floors: Array, floor_number: int):
	for floor in floors:
		if floor.floor_number == floor_number:
			return floor
	return null


func _find_index_by_type(nodes: Array, node_type: String) -> int:
	for index in range(nodes.size()):
		if nodes[index].type == node_type:
			return index
	return -1


func _has_duplicates(values: Array) -> bool:
	var seen := {}
	for value in values:
		if seen.has(value):
			return true
		seen[value] = true
	return false
