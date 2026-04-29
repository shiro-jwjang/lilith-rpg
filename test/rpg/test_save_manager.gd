extends "res://test/rpg/test_base.gd"

const PERSISTENT_SAVE_PATH := "user://saves/persistent.json"
const RUN_SAVE_PATH := "user://saves/run.json"


func test_load_persistent_returns_empty_dict_when_missing() -> void:
	var manager = _get_save_manager()
	if manager == null:
		return

	_delete_if_exists(PERSISTENT_SAVE_PATH)
	assert_eq(manager.load_persistent(), {}, "load_persistent should return an empty dictionary when no file exists")


func test_save_and_load_persistent_round_trip() -> void:
	var manager = _get_save_manager()
	if manager == null:
		return

	var data := {"test_key": "test_value", "number": 42}
	manager.save_persistent(data)
	var loaded: Dictionary = manager.load_persistent()

	assert_eq(loaded.get("test_key", ""), "test_value", "persistent save should round-trip string")
	assert_eq(int(loaded.get("number", 0)), 42, "persistent save should round-trip number")

	manager.save_persistent({})


func test_unlock_boss_persists_correctly() -> void:
	var manager = _get_save_manager()
	if manager == null:
		return

	manager.save_persistent({})
	manager.unlock_boss("boss_alpha")
	manager.unlock_boss("boss_alpha")
	var loaded: Dictionary = manager.load_persistent()
	var unlocked = loaded.get("unlocked_bosses", [])

	assert_true(unlocked is Array, "unlock_boss should persist an unlocked_bosses array")
	assert_eq((unlocked as Array).size(), 1, "unlock_boss should avoid duplicate boss entries")
	assert_eq((unlocked as Array)[0], "boss_alpha", "unlock_boss should persist the requested boss id")

	manager.save_persistent({})


func test_save_and_load_run_round_trip() -> void:
	var manager = _get_save_manager()
	if manager == null:
		return

	var data := {"floor": 3, "node_id": "floor3_node2"}
	manager.save_run(data)
	var loaded: Dictionary = manager.load_run()

	assert_eq(int(loaded.get("floor", 0)), 3, "run save should round-trip numeric data")
	assert_eq(String(loaded.get("node_id", "")), "floor3_node2", "run save should round-trip string data")

	manager.delete_run_save()


func test_delete_run_save_removes_file() -> void:
	var manager = _get_save_manager()
	if manager == null:
		return

	manager.save_run({"exists": true})
	assert_true(FileAccess.file_exists(RUN_SAVE_PATH), "run save should exist before deletion")
	manager.delete_run_save()
	assert_false(FileAccess.file_exists(RUN_SAVE_PATH), "delete_run_save should remove the run save file")


func _get_save_manager():
	var manager = Engine.get_meta("_save_manager_instance", null)
	assert_not_null(manager, "SaveManager autoload should be installed for SceneTree tests")
	return manager


func _delete_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
