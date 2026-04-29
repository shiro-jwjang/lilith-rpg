extends Control

const UI_FONT = preload("res://assets/fonts/NotoSansKR.tres")

var _rich_text: RichTextLabel = null
var _copy_button: Button = null


func _ready() -> void:
	_setup()


func _setup() -> void:
	if _rich_text != null:
		return

	anchor_right = 1.0
	anchor_top = 0.10
	anchor_bottom = 0.75

	var font: FontFile = UI_FONT
	var font_size := 18

	_rich_text = RichTextLabel.new()
	_rich_text.anchor_right = 1.0
	_rich_text.anchor_bottom = 1.0
	_rich_text.bbcode_enabled = true
	_rich_text.scroll_following = true
	_rich_text.add_theme_font_override("normal_font", font)
	_rich_text.add_theme_font_size_override("normal_font_size", font_size)
	add_child(_rich_text)

	_copy_button = Button.new()
	_copy_button.text = "로그 복사"
	_copy_button.anchor_left = 1.0
	_copy_button.anchor_top = 0.0
	_copy_button.anchor_right = 1.0
	_copy_button.anchor_bottom = 0.0
	_copy_button.offset_left = -116.0
	_copy_button.offset_top = 8.0
	_copy_button.offset_right = -16.0
	_copy_button.offset_bottom = 40.0
	_copy_button.add_theme_font_override("font", font)
	_copy_button.add_theme_font_size_override("font_size", 14)
	_copy_button.pressed.connect(_on_copy_pressed)
	add_child(_copy_button)


func append_text(text: String) -> void:
	if _rich_text != null:
		_rich_text.append_text(text + "\n")


func clear_log() -> void:
	if _rich_text != null:
		_rich_text.clear()


func get_plain_text() -> String:
	if _rich_text != null:
		return _rich_text.get_parsed_text()
	return ""


func _on_copy_pressed() -> void:
	if _rich_text == null:
		return
	DisplayServer.clipboard_set(_rich_text.get_parsed_text())
	append_text("[color=gray]로그를 클립보드에 복사했다.[/color]")
