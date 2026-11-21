class_name WhaleInteractionPrompt
extends Control
## Screen-space prompt shared by interactions and nearby traversal actions.

const FONT_SIZE := 14
var message: String = ""
var action_key: String = ""
var blocked: bool = false
var explanation: String = ""
var age: float = 0.0
var reduce_motion: bool = false
var high_contrast: bool = false
var card_rect := Rect2()
var caption: Label
var key_label: Label
var detail: Label
var card_style := StyleBoxFlat.new()
var key_style := StyleBoxFlat.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption = WhaleUIStyle.label("", FONT_SIZE)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(caption)
	detail = WhaleUIStyle.label("", 13)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(detail)
	key_label = WhaleUIStyle.label("", 16, WhaleUIStyle.INK)
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(key_label)
	for style: StyleBoxFlat in [card_style, key_style]:
		style.set_corner_radius_all(10)
	card_style.set_border_width_all(1)
	card_style.shadow_offset = Vector2.ZERO
	visible = false

func present(value: String, key: String, unavailable: bool, guidance: String = "") -> void:
	if value == message and key == action_key and unavailable == blocked and guidance == explanation: return
	age = 0.0
	message = value
	action_key = key
	blocked = unavailable
	explanation = guidance
	visible = not message.is_empty()
	caption.text = message
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if blocked else HORIZONTAL_ALIGNMENT_LEFT
	caption.add_theme_font_size_override("font_size", 16 if blocked else FONT_SIZE)
	caption.add_theme_color_override("font_color", WhaleUIStyle.AMBER if blocked else WhaleUIStyle.BONE)
	detail.text = explanation
	detail.visible = not explanation.is_empty()
	key_label.text = action_key
	key_label.visible = not action_key.is_empty()

func _process(dt: float) -> void:
	if not visible or get_tree().paused: return
	age += dt
	var appear: float = 1.0 if reduce_motion else clampf(age / 0.18, 0.0, 1.0)
	modulate.a = appear
	var pulse: float = 0.0 if reduce_motion else maxf(0.0, 1.0 - age / 0.7)
	var accent: Color = WhaleUIStyle.AMBER
	card_style.bg_color = Color(WhaleUIStyle.INK, 1.0 if high_contrast else (0.94 if blocked else 0.88))
	card_style.set_border_width_all(2 if blocked else 1)
	card_style.border_color = accent.lerp(WhaleUIStyle.BONE, 0.15 + pulse * 0.35)
	card_style.shadow_color = Color(accent, 0.1 + pulse * 0.08)
	card_style.shadow_size = int(4 + pulse * 3)
	key_style.bg_color = WhaleUIStyle.AMBER
	_layout(appear)
	queue_redraw()

func _layout(appear: float) -> void:
	var dock: Rect2 = WhaleActionHUDStyle.dock_rect(size)
	var key_width: float = maxf(24.0, WhaleUIStyle.FONT.get_string_size(action_key,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+10) if key_label.visible else 0.0
	var inset: float = 20+(key_width+8 if key_label.visible else 0)
	var content_width: float = maxf(WhaleUIStyle.FONT.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,16 if blocked else FONT_SIZE).x,WhaleUIStyle.FONT.get_string_size(explanation,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x)
	var text_width: float = minf(dock.size.x-inset,maxf(28,content_width))
	caption.size = Vector2(text_width,0)
	detail.size = Vector2(text_width,0)
	var content_height: float = caption.get_minimum_size().y+(detail.get_minimum_size().y+4 if detail.visible else 0)
	var height: float = maxf(30,content_height+12)
	var lift: float = 0 if reduce_motion else 3*pow(1-appear,2)
	card_rect = Rect2(Vector2(dock.end.x-text_width-inset,dock.position.y-height-8+lift),Vector2(text_width+inset,height))
	key_label.position = card_rect.position+Vector2(7,(height-22)*0.5)
	key_label.size = Vector2(key_width,22)
	caption.position = card_rect.position+Vector2(inset-10,(height-content_height)*0.5)
	detail.position = caption.position+Vector2(0,caption.size.y+4)

func _draw() -> void:
	if message.is_empty(): return
	draw_style_box(card_style, card_rect)
	if key_label.visible:
		draw_style_box(key_style, Rect2(key_label.position, key_label.size))
