extends "res://test/rpg/test_base.gd"

const UI_CONSTANTS_PATH := "res://scripts/rpg/ui/ui_constants.gd"


func test_ui_031_font_family_includes_pretendard_or_noto_sans_kr() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_has(ui_constants.FONT_FAMILIES, "Pretendard", "ui-031 expected Pretendard font family")
	assert_has(ui_constants.FONT_FAMILIES, "Noto Sans KR", "ui-031 expected Noto Sans KR font family")


func test_ui_032_body_text_is_at_least_24px() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_ge(ui_constants.FONT_SIZES["body"], 24, "ui-032 expected body font size >= 24px")


func test_ui_033_warning_text_is_at_least_28px() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_ge(ui_constants.FONT_SIZES["warning"], 28, "ui-033 expected warning font size >= 28px")
	assert_ge(ui_constants.FONT_SIZES["important"], 28, "ui-033 expected important font size >= 28px")


func test_ui_034_hud_fonts_match_body_label_and_important_thresholds() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_ge(ui_constants.HUD_FONT_SIZES["body_number"], 24, "ui-034 expected HUD body number >= 24px")
	assert_ge(ui_constants.HUD_FONT_SIZES["label"], 20, "ui-034 expected HUD label >= 20px")
	assert_ge(ui_constants.HUD_FONT_SIZES["important_number"], 28, "ui-034 expected HUD important number >= 28px")


func _make_ui_constants():
	var script: Script = load(UI_CONSTANTS_PATH)
	assert_not_null(script, "expected ui_constants.gd to exist")
	if script == null:
		return null
	return script.new()
