extends Node

var victory: bool = false
var defeat: bool = false
var ended: bool = false
var current_floor: int = 1
var floors_cleared: int = 0
var nodes_visited: Array = []
var combats_won: int = 0
var gold_earned: int = 0
var current_node_id: String = ""


func start_new_run() -> void:
	victory = false
	defeat = false
	ended = false
	current_floor = 1
	floors_cleared = 0
	nodes_visited = []
	combats_won = 0
	gold_earned = 0
	current_node_id = ""


func reset() -> void:
	start_new_run()


func to_dict() -> Dictionary:
	return {
		"victory": victory,
		"defeat": defeat,
		"ended": ended,
		"current_floor": current_floor,
		"floors_cleared": floors_cleared,
		"nodes_visited": nodes_visited.duplicate(true),
		"combats_won": combats_won,
		"gold_earned": gold_earned,
		"current_node_id": current_node_id,
	}
