extends RefCounted

const GENERATOR_SCRIPT = preload("res://scripts/rpg/map/map_generator.gd")

var act: Dictionary = {}
var current_floor_number: int = 1
var _selected_node_ids_by_floor: Dictionary = {}


func _init(initial_act: Dictionary = {}, _config: Dictionary = {}) -> void:
	act = initial_act.duplicate(false)
	if act.is_empty():
		act = GENERATOR_SCRIPT.new().generate_act()


func get_current_floor():
	return _find_floor(current_floor_number)


func get_selected_nodes_for_floor(floor_number: int) -> Array:
	return (_selected_node_ids_by_floor.get(floor_number, []) as Array).duplicate()


func select_node(node_id: String) -> Dictionary:
	var selected_for_floor: Array = _selected_node_ids_by_floor.get(current_floor_number, [])
	if selected_for_floor.size() >= 1:
		return {
			"ok": false,
			"error": "Only one node per floor",
		}

	var node = _find_node_by_id(node_id)
	if node == null:
		return {
			"ok": false,
			"error": "Unknown node id",
		}

	_selected_node_ids_by_floor[current_floor_number] = [node_id]
	return {"ok": true, "node": node}


func can_advance_to_floor(target_floor: int) -> bool:
	return target_floor == current_floor_number + 1 and target_floor <= 3


func can_go_to_floor(target_floor: int) -> bool:
	return target_floor >= current_floor_number and target_floor <= 3


func set_current_floor(floor_number: int) -> void:
	current_floor_number = floor_number


func advance_to_floor(target_floor: int) -> bool:
	if not can_advance_to_floor(target_floor):
		return false
	current_floor_number = target_floor
	return true


func _find_floor(floor_number: int):
	for floor in act.get("floors", []):
		if floor.floor_number == floor_number:
			return floor
	return null


func _find_node_by_id(node_id: String):
	var floor = get_current_floor()
	if floor == null:
		return null
	for node in floor.nodes:
		if node.id == node_id:
			return node
	return null
