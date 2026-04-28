extends "res://test/rpg/test_base.gd"

const UI_CONSTANTS_PATH := "res://scripts/rpg/ui/ui_constants.gd"


func test_ui_014_battle_hud_always_shows_hp_mp_turn_order_and_status_effects() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_has(ui_constants.BATTLE_HUD_ALWAYS_VISIBLE, "HP_bar", "ui-014 expected HP_bar always visible")
	assert_has(ui_constants.BATTLE_HUD_ALWAYS_VISIBLE, "MP_bar", "ui-014 expected MP_bar always visible")
	assert_has(ui_constants.BATTLE_HUD_ALWAYS_VISIBLE, "turn_order", "ui-014 expected turn_order always visible")
	assert_has(ui_constants.BATTLE_HUD_ALWAYS_VISIBLE, "status_effects", "ui-014 expected status_effects always visible")


func test_ui_015_skill_preview_is_bottom_center_with_name_mp_and_description() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_eq(ui_constants.SKILL_PREVIEW["position"], "bottom_center", "ui-015 expected skill preview bottom_center")
	assert_has(ui_constants.SKILL_PREVIEW["fields"], "name", "ui-015 expected skill preview name field")
	assert_has(ui_constants.SKILL_PREVIEW["fields"], "mp", "ui-015 expected skill preview mp field")
	assert_has(ui_constants.SKILL_PREVIEW["fields"], "description", "ui-015 expected skill preview description field")


func _make_ui_constants():
	var script: Script = load(UI_CONSTANTS_PATH)
	assert_not_null(script, "expected ui_constants.gd to exist")
	if script == null:
		return null
	return script.new()
