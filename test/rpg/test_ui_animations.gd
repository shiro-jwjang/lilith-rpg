extends "res://test/rpg/test_base.gd"

const FEEDBACK_CONSTANTS_PATH := "res://scripts/rpg/ui/feedback_constants.gd"
const UI_CONSTANTS_PATH := "res://scripts/rpg/ui/ui_constants.gd"


func test_ui_024_basic_attack_animation_is_350ms() -> void:
	var feedback_constants = _make_script(FEEDBACK_CONSTANTS_PATH)
	if feedback_constants == null:
		return
	assert_eq(feedback_constants.ANIMATION_DURATIONS_MS["attack"], 350, "ui-024 expected attack animation 350ms")


func test_ui_025_hit_flash_animation_is_120ms() -> void:
	var feedback_constants = _make_script(FEEDBACK_CONSTANTS_PATH)
	if feedback_constants == null:
		return
	assert_eq(feedback_constants.ANIMATION_DURATIONS_MS["hit_flash"], 120, "ui-025 expected hit flash animation 120ms")


func test_ui_026_status_effect_appear_animation_is_150ms() -> void:
	var feedback_constants = _make_script(FEEDBACK_CONSTANTS_PATH)
	if feedback_constants == null:
		return
	assert_eq(feedback_constants.ANIMATION_DURATIONS_MS["status"], 150, "ui-026 expected status animation 150ms")


func test_ui_027_reward_popup_animation_is_300ms() -> void:
	var feedback_constants = _make_script(FEEDBACK_CONSTANTS_PATH)
	if feedback_constants == null:
		return
	assert_eq(feedback_constants.ANIMATION_DURATIONS_MS["reward"], 300, "ui-027 expected reward animation 300ms")


func test_ui_028_victory_or_defeat_animation_is_500ms() -> void:
	var feedback_constants = _make_script(FEEDBACK_CONSTANTS_PATH)
	if feedback_constants == null:
		return
	assert_eq(feedback_constants.ANIMATION_DURATIONS_MS["victory"], 500, "ui-028 expected victory animation 500ms")


func test_ui_029_particles_are_capped_at_twelve_per_skill() -> void:
	var ui_constants = _make_script(UI_CONSTANTS_PATH)
	if ui_constants == null:
		return
	assert_eq(ui_constants.PARTICLE_LIMITS["max_per_skill"], 12, "ui-029 expected max 12 particles per skill")


func _make_script(path: String):
	var script: Script = load(path)
	assert_not_null(script, "expected %s to exist" % path)
	if script == null:
		return null
	return script.new()
