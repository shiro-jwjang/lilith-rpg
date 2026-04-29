extends SceneTree

## Headless test runner — no GUT dependency
## Usage: godot --headless --quit --script test/test_runner.gd

var _pass_count: int = 0
var _fail_count: int = 0
var _fail_messages: Array = []

func _init():
	_install_test_autoloads()

	# Pre-load implementation scripts (order matters: base first)
	load("res://scripts/rpg/data/base_record.gd")
	var impl_dir = DirAccess.open("res://scripts/rpg/data/")
	if impl_dir:
		impl_dir.list_dir_begin()
		var f = impl_dir.get_next()
		while f != "":
			if f.ends_with(".gd") and f != "base_record.gd":
				load("res://scripts/rpg/data/" + f)
			f = impl_dir.get_next()
		impl_dir.list_dir_end()

	print("\n═══════════════════════════════════════")
	print("  Lilith RPG — Test Runner")
	print("═══════════════════════════════════════\n")

	# Discover and run tests
	var test_dir = DirAccess.open("res://test/rpg/")
	if test_dir == null:
		push_error("Cannot open test/rpg/")
		quit(1)
		return

	test_dir.list_dir_begin()
	var file_name = test_dir.get_next()
	var test_files: Array = []
	while file_name != "":
		if file_name.ends_with(".gd") and file_name.begins_with("test_") and file_name != "test_base.gd":
			test_files.append(file_name)
		file_name = test_dir.get_next()
	test_dir.list_dir_end()

	for tf in test_files:
		_run_test_file("res://test/rpg/" + tf)

	# Summary
	var total = _pass_count + _fail_count
	print("\n═══════════════════════════════════════")
	print("  Results: %d passed, %d failed, %d total" % [_pass_count, _fail_count, total])
	print("═══════════════════════════════════════")
	if _fail_count > 0:
		print("\n  ❌ SOME TESTS FAILED\n")
		quit(1)
	else:
		print("\n  ✅ ALL TESTS PASSED\n")
		quit(0)


func _install_test_autoloads() -> void:
	_install_test_autoload("EventBus", "_event_bus_instance")
	_install_test_autoload("RunState", "_run_state_instance")
	_install_test_autoload("SaveManager", "_save_manager_instance")
	_install_test_autoload("SceneManager", "_scene_manager_instance")
	_install_test_autoload("GameRunner", "_game_runner_autoload_instance")


func _install_test_autoload(autoload_name: String, meta_key: String) -> void:
	var setting = String(ProjectSettings.get_setting("autoload/" + autoload_name, ""))
	if setting.is_empty():
		return
	var script_path := setting.trim_prefix("*")
	var script = load(script_path)
	if script == null:
		push_error("Failed to load autoload script: %s" % script_path)
		return
	var instance = script.new()
	if instance == null:
		push_error("Failed to instantiate autoload: %s" % script_path)
		return
	instance.name = autoload_name
	get_root().add_child(instance)
	Engine.set_meta(meta_key, instance)

func _run_test_file(path: String):
	var script = load(path) as GDScript
	if script == null:
		push_error("Failed to load: %s" % path)
		return

	var methods = script.get_script_method_list()
	var test_names: Array = []
	for m in methods:
		if m.name.begins_with("test_"):
			test_names.append(m.name)
	test_names.sort()

	var script_name = path.get_file().get_basename()
	if test_names.size() > 0:
		print("[%s — %d tests]" % [script_name, test_names.size()])

	for tn in test_names:
		var inst = script.new()
		if inst.has_method(tn):
			inst.call(tn)
		var failures: Array = inst._failures
		if failures.size() == 0:
			_pass_count += 1
			print("  ✅ %s" % tn)
		else:
			_fail_count += 1
			for msg in failures:
				print("  ❌ %s — %s" % [tn, msg])
