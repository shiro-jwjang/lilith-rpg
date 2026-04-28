extends "res://test/rpg/test_base.gd"

const NODE_ICONS_PATH := "res://scripts/rpg/ui/node_icons.gd"
const UI_CONSTANTS_PATH := "res://scripts/rpg/ui/ui_constants.gd"


func test_ui_016_map_node_types_use_expected_icons() -> void:
	var node_icons = _make_script(NODE_ICONS_PATH)
	if node_icons == null:
		return
	assert_eq(node_icons.ICONS["battle"], "붉은검", "ui-016 expected battle icon 붉은검")
	assert_eq(node_icons.ICONS["event"], "보라두루마리", "ui-016 expected event icon 보라두루마리")
	assert_eq(node_icons.ICONS["treasure"], "금색상자", "ui-016 expected treasure icon 금색상자")
	assert_eq(node_icons.ICONS["shop"], "초록가방", "ui-016 expected shop icon 초록가방")
	assert_eq(node_icons.ICONS["campfire"], "주황불꽃", "ui-016 expected campfire icon 주황불꽃")
	assert_eq(node_icons.ICONS["unique"], "은색왕관", "ui-016 expected unique icon 은색왕관")
	assert_eq(node_icons.ICONS["boss"], "검은해골", "ui-016 expected boss icon 검은해골")


func test_ui_017_map_node_opacity_distinguishes_selectable_and_unselectable() -> void:
	var ui_constants = _make_script(UI_CONSTANTS_PATH)
	if ui_constants == null:
		return
	assert_eq(ui_constants.MAP_NODE_OPACITY["selectable"], 1.0, "ui-017 expected selectable opacity 1.0")
	assert_eq(ui_constants.MAP_NODE_OPACITY["unselectable"], 0.35, "ui-017 expected unselectable opacity 0.35")


func test_ui_018_current_map_node_uses_white_pulse_ring_every_1500ms() -> void:
	var ui_constants = _make_script(UI_CONSTANTS_PATH)
	if ui_constants == null:
		return
	assert_eq(ui_constants.CURRENT_NODE_INDICATOR["ring_color"], "white", "ui-018 expected current node ring white")
	assert_eq(ui_constants.CURRENT_NODE_INDICATOR["pulse_duration_ms"], 1500, "ui-018 expected current node pulse 1500ms")


func _make_script(path: String):
	var script: Script = load(path)
	assert_not_null(script, "expected %s to exist" % path)
	if script == null:
		return null
	return script.new()
