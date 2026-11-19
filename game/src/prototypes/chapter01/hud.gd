class_name Chapter01PreviewHUD
extends Control

signal restart_requested
const FONT: Font = preload("res://art/fonts/WhalefallUI.ttf")
var title: Label
var subtitle: Label
var count: Label
var prompt: Label
var toast: Label
var elapsed := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title = make_label(Vector2(34, 24), Vector2(740, 40), 27, Color("e5dcc8"))
	subtitle = make_label(Vector2(36, 67), Vector2(900, 35), 16, Color("9eb9ba"))
	count = make_label(Vector2(990, 25), Vector2(250, 40), 18, Color("d4bd8a"))
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prompt = make_label(Vector2(200, 618), Vector2(880, 42), 21, Color("edddad"))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast = make_label(Vector2(230, 110), Vector2(820, 40), 19, Color("c6e1d6"))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var controls := make_label(Vector2(30, 681), Vector2(1200, 30), 15, Color("b9c8c8"))
	controls.text = "A / D 或 ← / → 移动    空格 跳跃    E 穿门    R 回到入口    F 全屏"
	var badge := make_label(Vector2(965, 673), Vector2(280, 35), 14, Color("b49f79"))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.text = "第一章 · 地图与转场预览"


func make_label(pos: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = dimensions
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", color)
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_shadow_color", Color("031019"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func show_room(room: Dictionary, visited: int) -> void:
	title.text = str(room.label)
	subtitle.text = str(room.hint)
	count.text = "已探索 %d / 10" % visited


func notify(text: String) -> void:
	toast.text = text
	elapsed = 3.4


func _process(delta: float) -> void:
	elapsed = maxf(0, elapsed - delta)
	toast.modulate.a = minf(1.0, elapsed)
