extends VBoxContainer

const UI_FONT = preload("res://assets/fonts/NotoSansKR.tres")

var _callback_target: Object = null


func setup(target: Object) -> void:
	_callback_target = target


func clear_choices() -> void:
	for child in get_children():
		child.queue_free()


func add_choice(label: String, method_name: String, args: Array) -> void:
	var button := Button.new()
	button.text = label
	var font: FontFile = UI_FONT
	button.add_theme_font_override("font", _create_font_with_emoji_fallback(font))
	button.add_theme_font_size_override("font_size", 16)
	if _callback_target != null:
		button.pressed.connect(_make_callback(method_name, args))
	add_child(button)


func _make_callback(method_name: String, args: Array) -> Callable:
	var target = _callback_target
	return func() -> void: target.callv(method_name, args)


func _create_font_with_emoji_fallback(font: Font) -> FontVariation:
	var fallback_font := SystemFont.new()
	fallback_font.font_names = [
		"Noto Color Emoji",
		"Apple Color Emoji",
		"Segoe UI Emoji",
		"Noto Sans Symbols 2",
	]

	var font_with_fallback := FontVariation.new()
	font_with_fallback.base_font = font
	font_with_fallback.fallbacks = [fallback_font]
	return font_with_fallback
