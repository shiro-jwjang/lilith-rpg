extends Node

const SAVE_DIR := "user://saves/"


func _ready() -> void:
	_ensure_save_dir()


func save_persistent(data: Dictionary) -> void:
	_ensure_save_dir()
	var file := FileAccess.open(SAVE_DIR + "persistent.json", FileAccess.WRITE)
	if file == null:
		push_error("Failed to open persistent save file")
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_persistent() -> Dictionary:
	if not FileAccess.file_exists(SAVE_DIR + "persistent.json"):
		return {}
	var file := FileAccess.open(SAVE_DIR + "persistent.json", FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		return {}
	return json.data if json.data is Dictionary else {}


func save_run(run_data: Dictionary) -> void:
	_ensure_save_dir()
	var file := FileAccess.open(SAVE_DIR + "run.json", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(run_data, "\t"))


func load_run() -> Dictionary:
	if not FileAccess.file_exists(SAVE_DIR + "run.json"):
		return {}
	var file := FileAccess.open(SAVE_DIR + "run.json", FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		return {}
	return json.data if json.data is Dictionary else {}


func delete_run_save() -> void:
	if FileAccess.file_exists(SAVE_DIR + "run.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_DIR + "run.json"))


func unlock_boss(boss_id: String) -> void:
	var data := load_persistent()
	if not data.has("unlocked_bosses"):
		data["unlocked_bosses"] = []
	if boss_id not in data["unlocked_bosses"]:
		data["unlocked_bosses"].append(boss_id)
	save_persistent(data)


func _ensure_save_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
