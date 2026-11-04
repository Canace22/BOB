class_name WhaleUIStyle
extends RefCounted

const INK := Color("07151d")
const BONE := Color("e5e1ce")
const MUTED := Color("a8bdb7")
const AMBER := Color("dfba77")
const TEAL := Color("8fbfb6")
const FONT: Font = preload("res://art/fonts/WhalefallUI.ttf")

static func box(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = border
	result.set_border_width_all(1)
	result.set_content_margin_all(12)
	return result

static func theme(high_contrast: bool = false) -> Theme:
	var result := Theme.new()
	result.default_font = FONT
	result.default_font_size = 18
	result.set_color("font_color", "Label", BONE)
	result.set_color("font_color", "Button", BONE)
	result.set_color("font_hover_color", "Button", AMBER)
	result.set_color("font_focus_color", "Button", AMBER)
	result.set_color("font_disabled_color", "Button", Color("819792"))
	result.set_stylebox("normal", "Button", box(Color(0.04, 0.1, 0.12, 0.4)))
	result.set_stylebox("hover", "Button", box(Color("1b3338"), TEAL))
	result.set_stylebox("pressed", "Button", box(Color("29423f"), AMBER))
	result.set_stylebox("focus", "Button", box(Color.TRANSPARENT, AMBER))
	result.set_stylebox("disabled", "Button", box(Color(0.03, 0.08, 0.1, 0.7)))
	if high_contrast:
		result.set_stylebox("normal", "Button", box(INK, TEAL))
	return result

static func label(text: String, font_size: int = 18, color: Color = BONE) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func paragraph(text: String, color: Color = MUTED) -> Label:
	var result := label(text, 17, color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result

static func button(text: String, action: Callable, enabled: bool = true) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(260, 46)
	result.disabled = not enabled
	result.pressed.connect(action)
	return result

static func icon(id: String, dimensions: Vector2 = Vector2(76, 76)) -> TextureRect:
	var result := TextureRect.new()
	result.texture = load("res://art/ui/" + id + ".svg") as Texture2D
	result.custom_minimum_size = dimensions
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func key(action: String) -> String:
	if InputMap.has_action(action):
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				var code: int = event.physical_keycode if event.physical_keycode else event.keycode
				return OS.get_keycode_string(code)
	return "—"
