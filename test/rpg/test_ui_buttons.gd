extends "res://test/rpg/test_base.gd"

const UI_THEME_PATH := "res://scripts/rpg/ui/ui_theme.gd"


func test_ui_007_buttons_use_56px_height_and_240px_min_width() -> void:
	var ui_theme = _make_ui_theme()
	if ui_theme == null:
		return
	assert_eq(ui_theme.BUTTON_SPECS["height"], 56, "ui-007 expected button height 56")
	assert_eq(ui_theme.BUTTON_SPECS["min_width"], 240, "ui-007 expected button min width 240")


func test_ui_008_buttons_define_four_visual_states() -> void:
	var ui_theme = _make_ui_theme()
	if ui_theme == null:
		return
	assert_eq(ui_theme.BUTTON_STATES.size(), 4, "ui-008 expected four button states")
	assert_has(ui_theme.BUTTON_STATES, "default", "ui-008 expected default state")
	assert_has(ui_theme.BUTTON_STATES, "hover", "ui-008 expected hover state")
	assert_has(ui_theme.BUTTON_STATES, "pressed", "ui-008 expected pressed state")
	assert_has(ui_theme.BUTTON_STATES, "disabled", "ui-008 expected disabled state")


func test_ui_009_buttons_define_three_distinct_styles() -> void:
	var ui_theme = _make_ui_theme()
	if ui_theme == null:
		return
	assert_eq(ui_theme.BUTTON_STYLES.size(), 3, "ui-009 expected three button styles")
	assert_has(ui_theme.BUTTON_STYLES, "primary", "ui-009 expected primary style")
	assert_has(ui_theme.BUTTON_STYLES, "secondary", "ui-009 expected secondary style")
	assert_has(ui_theme.BUTTON_STYLES, "destructive", "ui-009 expected destructive style")
	assert_ne(ui_theme.BUTTON_STYLES["primary"], ui_theme.BUTTON_STYLES["secondary"], "ui-009 expected primary and secondary visuals to differ")
	assert_ne(ui_theme.BUTTON_STYLES["primary"], ui_theme.BUTTON_STYLES["destructive"], "ui-009 expected primary and destructive visuals to differ")
	assert_ne(ui_theme.BUTTON_STYLES["secondary"], ui_theme.BUTTON_STYLES["destructive"], "ui-009 expected secondary and destructive visuals to differ")


func test_ui_010_disabled_buttons_ignore_clicks() -> void:
	var ui_theme = _make_ui_theme()
	if ui_theme == null:
		return
	assert_true(ui_theme.BUTTON_STATES["disabled"]["ignore_click"], "ui-010 expected disabled buttons to ignore clicks")


func _make_ui_theme():
	var script: Script = load(UI_THEME_PATH)
	assert_not_null(script, "expected ui_theme.gd to exist")
	if script == null:
		return null
	return script.new()
