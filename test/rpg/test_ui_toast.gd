extends "res://test/rpg/test_base.gd"

const TOAST_CONFIG_PATH := "res://scripts/rpg/ui/toast_config.gd"


func test_ui_011_toast_defaults_to_top_center_for_1500ms() -> void:
	var toast_config = _make_toast_config()
	if toast_config == null:
		return
	assert_eq(toast_config.POSITION, "top_center", "ui-011 expected toast position top_center")
	assert_eq(toast_config.DURATION_MS, 1500, "ui-011 expected toast duration 1500ms")


func test_ui_012_toast_types_use_distinct_colors() -> void:
	var toast_config = _make_toast_config()
	if toast_config == null:
		return
	assert_eq(toast_config.TYPE_COLORS["acquire"], "gold", "ui-012 expected acquire toast gold")
	assert_eq(toast_config.TYPE_COLORS["loss"], "red", "ui-012 expected loss toast red")
	assert_eq(toast_config.TYPE_COLORS["status"], "purple", "ui-012 expected status toast purple")
	assert_eq(toast_config.TYPE_COLORS["fail"], "gray", "ui-012 expected fail toast gray")


func _make_toast_config():
	var script: Script = load(TOAST_CONFIG_PATH)
	assert_not_null(script, "expected toast_config.gd to exist")
	if script == null:
		return null
	return script.new()
