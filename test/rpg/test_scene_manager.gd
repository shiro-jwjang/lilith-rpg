extends "res://test/rpg/test_base.gd"


func test_scene_manager_autoload_exists() -> void:
	var manager = Engine.get_meta("_scene_manager_instance", null)
	assert_not_null(manager, "SceneManager autoload should be installed for SceneTree tests")
	if manager == null:
		return
	assert_eq(String(manager.name), "SceneManager", "autoload instance should be mounted as SceneManager")


func test_go_to_terminal_updates_current_target() -> void:
	var manager = _get_scene_manager()
	if manager == null:
		return

	manager.go_to("terminal")
	assert_eq(manager.get_current_target(), "terminal", "go_to should store the last requested target")


func test_resolve_path_unknown_returns_empty_string() -> void:
	var manager = _get_scene_manager()
	if manager == null:
		return

	assert_eq(manager._resolve_path("unknown"), "", "_resolve_path should return an empty string for unknown targets")


func test_resolve_path_terminal_returns_main_scene() -> void:
	var manager = _get_scene_manager()
	if manager == null:
		return

	assert_eq(manager._resolve_path("terminal"), "res://scenes/main.tscn", "terminal target should resolve to the main scene path")


func _get_scene_manager():
	var manager = Engine.get_meta("_scene_manager_instance", null)
	assert_not_null(manager, "SceneManager autoload should be installed for SceneTree tests")
	return manager
