extends "res://test/rpg/test_base.gd"

const UI_CONSTANTS_PATH := "res://scripts/rpg/ui/ui_constants.gd"


func test_ui_019_event_options_range_from_two_to_four() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_eq(ui_constants.EVENT_OPTIONS["min"], 2, "ui-019 expected minimum event options 2")
	assert_eq(ui_constants.EVENT_OPTIONS["max"], 4, "ui-019 expected maximum event options 4")


func test_ui_020_event_flow_is_split_into_description_choices_and_result_toast() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_eq(ui_constants.EVENT_FLOW_PHASES.size(), 3, "ui-020 expected three event flow phases")
	assert_eq(ui_constants.EVENT_FLOW_PHASES[0], "description_panel", "ui-020 expected description panel first")
	assert_eq(ui_constants.EVENT_FLOW_PHASES[1], "choice_buttons", "ui-020 expected choice buttons second")
	assert_eq(ui_constants.EVENT_FLOW_PHASES[2], "result_toast", "ui-020 expected result toast third")


func _make_ui_constants():
	var script: Script = load(UI_CONSTANTS_PATH)
	assert_not_null(script, "expected ui_constants.gd to exist")
	if script == null:
		return null
	return script.new()
