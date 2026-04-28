extends RefCounted

const FLOOR_SCRIPT = preload("res://scripts/rpg/map/floor.gd")

const EVENT_CATALOG := ["evt_a", "evt_b", "evt_c", "evt_d"]

var _config: Dictionary = {}


func _init(config: Dictionary = {}) -> void:
	_config = config.duplicate(true)


func generate_act() -> Dictionary:
	var floors: Array = []
	for floor_number in [1, 2, 3]:
		floors.append(FLOOR_SCRIPT.new(floor_number, _config.get(floor_number, {})))
	return {
		"floors": floors,
		"event_catalog": EVENT_CATALOG.duplicate(),
	}
