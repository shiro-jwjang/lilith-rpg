extends RefCounted

const NODE_SCRIPT = preload("res://scripts/rpg/map/node.gd")

var floor_number: int = 0
var nodes: Array = []
var _config: Dictionary = {}


func _init(number: int, config: Dictionary = {}) -> void:
	floor_number = number
	_config = config.duplicate(true)
	if not bool(_config.get("skip_generation", false)):
		generate_nodes()


func generate_nodes() -> Array:
	nodes.clear()
	match floor_number:
		1:
			_add_node("combat", {"tier": "normal"})
			_add_node("event", {"event_id": "ruined_altar"})
			_add_node("campfire")
		2:
			_add_node("combat", {"tier": "normal"})
			_add_node("combat", {"tier": "elite"})
			_add_node("event", {"event_id": "ruin_merchant"})
			_add_node("shop")
		3:
			_add_node("treasure")
			_add_node("unique")
			_add_node("boss")
	return nodes


func _add_node(node_type: String, data: Dictionary = {}) -> void:
	nodes.append(NODE_SCRIPT.new(node_type, floor_number, nodes.size(), data))
