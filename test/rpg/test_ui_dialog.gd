extends "res://test/rpg/test_base.gd"

const UI_THEME_PATH := "res://scripts/rpg/ui/ui_theme.gd"


func test_ui_013_confirm_dialog_uses_one_sentence_and_two_buttons() -> void:
	var ui_theme = _make_ui_theme()
	if ui_theme == null:
		return
	assert_eq(ui_theme.CONFIRM_DIALOG["sentence_count"], 1, "ui-013 expected one sentence in confirm dialog")
	assert_eq(ui_theme.CONFIRM_DIALOG["button_count"], 2, "ui-013 expected two buttons in confirm dialog")
	assert_eq(ui_theme.CONFIRM_DIALOG["confirm_style"], "destructive", "ui-013 expected confirm button destructive")
	assert_eq(ui_theme.CONFIRM_DIALOG["cancel_style"], "secondary", "ui-013 expected cancel button secondary")


func _make_ui_theme():
	var script: Script = load(UI_THEME_PATH)
	assert_not_null(script, "expected ui_theme.gd to exist")
	if script == null:
		return null
	return script.new()
