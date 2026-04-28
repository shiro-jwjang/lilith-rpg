extends "res://test/rpg/test_base.gd"

const UI_CONSTANTS_PATH := "res://scripts/rpg/ui/ui_constants.gd"


func test_ui_030_camera_shake_is_capped_at_six_percent() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_eq(ui_constants.CAMERA["shake_max_percent"], 6, "ui-030 expected camera shake max 6 percent")


func _make_ui_constants():
	var script: Script = load(UI_CONSTANTS_PATH)
	assert_not_null(script, "expected ui_constants.gd to exist")
	if script == null:
		return null
	return script.new()
