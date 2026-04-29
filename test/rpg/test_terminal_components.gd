extends "res://test/rpg/test_base.gd"

const TEXT_LOG_SCRIPT = preload("res://scenes/terminal/components/text_log.gd")
const CHOICE_PANEL_SCRIPT = preload("res://scenes/terminal/components/choice_panel.gd")


class _ChoiceTarget extends RefCounted:
	var called := false
	var last_value := -1

	func on_choice(value: int) -> void:
		called = true
		last_value = value


func test_text_log_append_and_get_plain_text() -> void:
	var text_log = TEXT_LOG_SCRIPT.new()
	text_log._setup()

	assert_not_null(text_log._rich_text, "TextLog should create its RichTextLabel on _ready")

	text_log.append_text("첫 줄")
	text_log.append_text("둘째 줄")

	assert_eq(text_log.get_plain_text(), "첫 줄\n둘째 줄\n", "TextLog should preserve appended lines")

	text_log.free()


func test_text_log_clear_log() -> void:
	var text_log = TEXT_LOG_SCRIPT.new()
	text_log._setup()

	text_log.append_text("임시 로그")
	text_log.clear_log()

	assert_eq(text_log.get_plain_text(), "", "clear_log should remove all appended text")

	text_log.free()


func test_choice_panel_add_and_clear_choices() -> void:
	var choice_panel = CHOICE_PANEL_SCRIPT.new()
	var target = _ChoiceTarget.new()
	choice_panel.setup(target)

	choice_panel.add_choice("첫 선택지", "on_choice", [7])
	choice_panel.add_choice("둘째 선택지", "on_choice", [9])

	assert_eq(choice_panel.get_child_count(), 2, "ChoicePanel should add one button per choice")
	var first_button := choice_panel.get_child(0) as Button
	assert_not_null(first_button, "ChoicePanel children should be buttons")
	assert_eq(first_button.text, "첫 선택지", "choice button text should match the provided label")

	first_button.emit_signal("pressed")
	assert_true(target.called, "pressed choice should call the configured target")
	assert_eq(target.last_value, 7, "pressed choice should forward callback args")

	choice_panel.clear_choices()
	var children := choice_panel.get_children()
	assert_eq(children.size(), 2, "clear_choices should queue every button for deletion")
	for child in children:
		assert_true(child.is_queued_for_deletion(), "clear_choices should queue buttons for deletion")

	choice_panel.free()
