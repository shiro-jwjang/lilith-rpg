extends RefCounted

var manager = null
var state: String = "select_node"
var current_node_id: String = ""
var rewards: Array = []
var displayed_floor: int = 1


func _init(map_manager = null, _config: Dictionary = {}) -> void:
	manager = map_manager
	if manager != null:
		displayed_floor = manager.current_floor_number


func select_node(node_id: String) -> Dictionary:
	if manager == null:
		return {"ok": false, "error": "Missing manager"}
	var result: Dictionary = manager.select_node(node_id)
	if result.get("ok", false):
		current_node_id = node_id
		state = "node_entered"
	return result


func complete_node(result: Dictionary) -> void:
	rewards = (result.get("rewards", []) as Array).duplicate(true)
	state = "result_reflected"


func advance() -> bool:
	if manager == null:
		return false
	var next_floor: int = manager.current_floor_number + 1
	if not manager.advance_to_floor(next_floor):
		return false
	displayed_floor = manager.current_floor_number
	state = "next_floor_ready"
	return true
