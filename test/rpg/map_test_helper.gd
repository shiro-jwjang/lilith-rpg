extends RefCounted

const NODE_PATH := "res://scripts/rpg/map/node.gd"
const FLOOR_PATH := "res://scripts/rpg/map/floor.gd"
const GENERATOR_PATH := "res://scripts/rpg/map/map_generator.gd"
const VALIDATOR_PATH := "res://scripts/rpg/map/map_validator.gd"
const PIPELINE_PATH := "res://scripts/rpg/map/map_pipeline.gd"
const MANAGER_PATH := "res://scripts/rpg/map/map_manager.gd"

const EVENT_IDS := ["evt_a", "evt_b", "evt_c", "evt_d"]


func load_script(path: String):
	return load(path)


func make_node(type: String, floor_index: int, position: int, data: Dictionary = {}):
	var script = load_script(NODE_PATH)
	if script == null:
		return null
	return script.new(type, floor_index, position, data)


func make_floor(floor_number: int, config: Dictionary = {}):
	var script = load_script(FLOOR_PATH)
	if script == null:
		return null
	return script.new(floor_number, config)


func make_generator(config: Dictionary = {}):
	var script = load_script(GENERATOR_PATH)
	if script == null:
		return null
	return script.new(config)


func make_validator():
	var script = load_script(VALIDATOR_PATH)
	if script == null:
		return null
	return script.new()


func make_manager(act: Dictionary = {}, config: Dictionary = {}):
	var script = load_script(MANAGER_PATH)
	if script == null:
		return null
	return script.new(act, config)


func make_pipeline(manager = null, config: Dictionary = {}):
	var script = load_script(PIPELINE_PATH)
	if script == null:
		return null
	return script.new(manager, config)


func generate_act(config: Dictionary = {}) -> Dictionary:
	var generator = make_generator(config)
	if generator == null:
		return {}
	return generator.generate_act()


func flatten_nodes(act: Dictionary) -> Array:
	var all_nodes: Array = []
	for floor in act.get("floors", []):
		for node in floor.nodes:
			all_nodes.append(node)
	return all_nodes


func count_nodes_of_type(nodes: Array, type: String) -> int:
	var count := 0
	for node in nodes:
		if node.type == type:
			count += 1
	return count


func count_nodes_with_tier(nodes: Array, type: String, tier: String) -> int:
	var count := 0
	for node in nodes:
		if node.type == type and String(node.tier) == tier:
			count += 1
	return count


func event_ids_from_floor(floor) -> Array:
	var ids: Array = []
	for node in floor.nodes:
		if node.type == "event":
			ids.append(node.event_id)
	return ids


func build_manual_act(layout: Dictionary, extras: Dictionary = {}) -> Dictionary:
	var floors: Array = []
	for floor_number in [1, 2, 3]:
		var floor = make_floor(floor_number, {"skip_generation": true})
		if floor == null:
			return {}
		floor.nodes = []
		var floor_types: Array = layout.get(floor_number, [])
		for index in range(floor_types.size()):
			var spec = floor_types[index]
			var node = null
			if spec is Dictionary:
				var node_type: String = spec.get("type", "")
				var data: Dictionary = spec.duplicate(true)
				data.erase("type")
				node = make_node(node_type, floor_number, index, data)
			else:
				node = make_node(String(spec), floor_number, index)
			if node == null:
				return {}
			floor.nodes.append(node)
		floors.append(floor)

	var act := {
		"floors": floors,
		"event_catalog": extras.get("event_catalog", EVENT_IDS.duplicate()),
	}

	if extras.has("events_by_floor"):
		var event_map: Dictionary = extras["events_by_floor"]
		for floor in floors:
			var ids: Array = event_map.get(floor.floor_number, [])
			var event_index := 0
			for node in floor.nodes:
				if node.type == "event" and event_index < ids.size():
					node.event_id = ids[event_index]
					event_index += 1

	return act
