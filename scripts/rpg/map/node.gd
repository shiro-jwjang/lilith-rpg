extends RefCounted

const VALID_TYPES := [
	"combat",
	"event",
	"treasure",
	"shop",
	"campfire",
	"unique",
	"boss",
]

var id: String = ""
var type: String = ""
var floor_index: int = 0
var position: int = 0
var visited: bool = false
var tier: String = ""
var event_id: String = ""


static func validate_type(node_type: String) -> Dictionary:
	if VALID_TYPES.has(node_type):
		return {"ok": true}
	return {
		"ok": false,
		"error": "Invalid node type: %s" % node_type,
	}


func _init(node_type: String, node_floor_index: int, node_position: int, data: Dictionary = {}) -> void:
	var type_result := validate_type(node_type)
	if not type_result["ok"]:
		push_error(type_result["error"])
		return

	type = node_type
	floor_index = node_floor_index
	position = node_position
	id = String(data.get("id", "floor%d_node%d" % [floor_index, position + 1]))
	visited = bool(data.get("visited", false))
	tier = String(data.get("tier", "normal" if type == "combat" else ""))
	event_id = String(data.get("event_id", ""))
