class_name ChapterDialogue
extends CanvasLayer

var pages: PackedStringArray = []
var index: int = 0
var flag_id: String = ""
var heading: Label
var body: Label
var next_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.035, 0.045, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var box := VBoxContainer.new()
	box.position = Vector2(230, 190)
	box.size = Vector2(820, 350)
	box.theme = preload("res://src/ui/theme.tres")
	box.add_theme_constant_override("separation", 24)
	add_child(box)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 30)
	box.add_child(heading)
	body = Label.new()
	body.custom_minimum_size = Vector2(820, 160)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 24)
	box.add_child(body)
	next_button = Button.new()
	next_button.pressed.connect(advance)
	box.add_child(next_button)
	EventBus.chapter_story_requested.connect(present)
	hide()


func present(title: String, text: PackedStringArray, completion: String) -> void:
	if visible or text.is_empty():
		return
	pages = text
	index = 0
	flag_id = completion
	heading.text = title
	show()
	get_tree().paused = true
	_render()
	next_button.grab_focus()


func _render() -> void:
	body.text = pages[index]
	next_button.text = "E / Enter · 继续（%d / %d）" % [index + 1, pages.size()] if index < pages.size() - 1 else "E / Enter · 出发"


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		advance()
	elif event.is_action_pressed("pause") or event.is_action_pressed("map"):
		get_viewport().set_input_as_handled()


func advance() -> void:
	index += 1
	if index < pages.size():
		_render()
		return
	GameState.set_flag(flag_id)
	GameState.save_progress()
	hide()
	get_tree().paused = false
