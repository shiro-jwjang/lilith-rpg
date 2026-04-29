extends Node

const SCENE_MAP := {
	"terminal": "res://scenes/main.tscn",
	"title": "res://scenes/main.tscn",
}

var _current_target: String = ""


func go_to(target: String, params: Dictionary = {}) -> void:
	var path := _resolve_path(target)
	if path == "":
		push_error("SceneManager: unknown target '%s'" % target)
		return
	_current_target = target
	var main_loop = Engine.get_main_loop()
	if main_loop != null and main_loop is SceneTree:
		var tree: SceneTree = main_loop
		tree.change_scene_to_file(path)


func get_current_target() -> String:
	return _current_target


func _resolve_path(target: String) -> String:
	return String(SCENE_MAP.get(target, ""))
