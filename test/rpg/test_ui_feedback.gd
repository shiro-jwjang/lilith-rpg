extends "res://test/rpg/test_base.gd"

const UI_CONSTANTS_PATH := "res://scripts/rpg/ui/ui_constants.gd"


func test_ui_021_damage_number_appears_within_200ms() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_eq(ui_constants.FEEDBACK["damage_number_display_ms"], 200, "ui-021 expected damage number display within 200ms")


func test_ui_022_hp_bar_animation_finishes_within_250ms() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_eq(ui_constants.FEEDBACK["hp_bar_animation_ms"], 250, "ui-022 expected hp bar animation within 250ms")


func test_ui_023_critical_feedback_uses_gold_120_percent_scale_and_unique_sound() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_eq(ui_constants.CRITICAL_FEEDBACK["color"], "gold", "ui-023 expected critical color gold")
	assert_eq(ui_constants.CRITICAL_FEEDBACK["scale"], 1.2, "ui-023 expected critical scale 1.2")
	assert_true(ui_constants.CRITICAL_FEEDBACK["unique_sound"], "ui-023 expected critical unique sound")


func _make_ui_constants():
	var script: Script = load(UI_CONSTANTS_PATH)
	assert_not_null(script, "expected ui_constants.gd to exist")
	if script == null:
		return null
	return script.new()
