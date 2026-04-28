extends "res://test/rpg/test_base.gd"

const UI_CONSTANTS_PATH := "res://scripts/rpg/ui/ui_constants.gd"


func test_ui_001_canvas_resolution_is_1920x1080_and_locked_to_16_9() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_eq(ui_constants.CANVAS_WIDTH, 1920, "ui-001 expected canvas width 1920")
	assert_eq(ui_constants.CANVAS_HEIGHT, 1080, "ui-001 expected canvas height 1080")
	assert_eq(ui_constants.ASPECT_RATIO_LABEL, "16:9", "ui-001 expected aspect ratio label 16:9")
	assert_eq(ui_constants.ASPECT_RATIO, 16.0 / 9.0, "ui-001 expected aspect ratio 16:9")
	assert_true(ui_constants.ASPECT_LOCKED, "ui-001 expected 16:9 to be locked")


func test_ui_002_resize_policy_preserves_16_9_with_letterbox_or_pillarbox() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_true(ui_constants.RESIZE_POLICY.has("maintain_aspect"), "ui-002 expected resize policy maintain_aspect")
	assert_true(ui_constants.RESIZE_POLICY["maintain_aspect"], "ui-002 expected maintain_aspect true")
	assert_true(ui_constants.RESIZE_POLICY.has("use_letterbox"), "ui-002 expected resize policy use_letterbox")
	assert_true(ui_constants.RESIZE_POLICY["use_letterbox"], "ui-002 expected use_letterbox true")
	assert_true(ui_constants.RESIZE_POLICY.has("use_pillarbox"), "ui-002 expected resize policy use_pillarbox")
	assert_true(ui_constants.RESIZE_POLICY["use_pillarbox"], "ui-002 expected use_pillarbox true")


func test_ui_003_safe_area_is_48px_on_all_sides() -> void:
	var ui_constants = _make_ui_constants()
	if ui_constants == null:
		return
	assert_eq(ui_constants.SAFE_AREA["top"], 48, "ui-003 expected safe area top 48")
	assert_eq(ui_constants.SAFE_AREA["bottom"], 48, "ui-003 expected safe area bottom 48")
	assert_eq(ui_constants.SAFE_AREA["left"], 48, "ui-003 expected safe area left 48")
	assert_eq(ui_constants.SAFE_AREA["right"], 48, "ui-003 expected safe area right 48")
	assert_eq(ui_constants.UI_BOUNDS["left"], 48, "ui-003 expected left bound 48")
	assert_eq(ui_constants.UI_BOUNDS["top"], 48, "ui-003 expected top bound 48")
	assert_eq(ui_constants.UI_BOUNDS["right"], 1872, "ui-003 expected right bound 1872")
	assert_eq(ui_constants.UI_BOUNDS["bottom"], 1032, "ui-003 expected bottom bound 1032")


func _make_ui_constants():
	var script: Script = load(UI_CONSTANTS_PATH)
	assert_not_null(script, "expected ui_constants.gd to exist")
	if script == null:
		return null
	return script.new()
