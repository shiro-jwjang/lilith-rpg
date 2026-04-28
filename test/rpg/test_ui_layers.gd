extends "res://test/rpg/test_base.gd"

const UI_CONSTANTS_PATH := "res://scripts/rpg/ui/ui_constants.gd"
const UI_THEME_PATH := "res://scripts/rpg/ui/ui_theme.gd"


func test_ui_004_ui_layer_order_is_background_info_panel_interaction_modal_toast() -> void:
	var ui_constants = _make_script(UI_CONSTANTS_PATH)
	if ui_constants == null:
		return
	assert_eq(ui_constants.Z_LAYERS["background"], 0, "ui-004 expected background layer 0")
	assert_eq(ui_constants.Z_LAYERS["info_panel"], 10, "ui-004 expected info_panel layer 10")
	assert_eq(ui_constants.Z_LAYERS["interaction"], 20, "ui-004 expected interaction layer 20")
	assert_eq(ui_constants.Z_LAYERS["modal_toast"], 30, "ui-004 expected modal_toast layer 30")
	assert_true(ui_constants.Z_LAYERS["background"] < ui_constants.Z_LAYERS["info_panel"], "ui-004 expected background < info_panel")
	assert_true(ui_constants.Z_LAYERS["info_panel"] < ui_constants.Z_LAYERS["interaction"], "ui-004 expected info_panel < interaction")
	assert_true(ui_constants.Z_LAYERS["interaction"] < ui_constants.Z_LAYERS["modal_toast"], "ui-004 expected interaction < modal_toast")


func test_ui_005_modal_overlay_uses_0_6_opacity() -> void:
	var ui_theme = _make_script(UI_THEME_PATH)
	if ui_theme == null:
		return
	assert_eq(ui_theme.MODAL_DIM_OPACITY, 0.6, "ui-005 expected modal dim opacity 0.6")


func test_ui_006_modal_blocks_background_interaction_when_open() -> void:
	var ui_theme = _make_script(UI_THEME_PATH)
	if ui_theme == null:
		return
	assert_true(ui_theme.MODAL_BLOCKS_BACKGROUND_INTERACTION, "ui-006 expected modal to block background interaction")


func _make_script(path: String):
	var script: Script = load(path)
	assert_not_null(script, "expected %s to exist" % path)
	if script == null:
		return null
	return script.new()
