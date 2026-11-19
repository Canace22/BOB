class_name WhaleDialoguePanel
extends Control
## 使用嵌入字体的轻量对话框；逐字显示与跳过只发送意图，进度由主线结算。
signal advance_requested
signal skip_requested
var speaker_label: Label
var text_label: RichTextLabel
var next_button: Button
var skip_button: Button
var reveal: float = 0.0
var input_lock: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left=40
	panel.offset_right=-40
	panel.offset_top=-215
	panel.offset_bottom=-24
	panel.add_theme_stylebox_override("panel",WhaleUIStyle.box(Color(0.02,0.06,0.08,0.96),WhaleUIStyle.MUTED))
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	panel.add_child(column)
	speaker_label=WhaleUIStyle.label("",19,WhaleUIStyle.AMBER)
	speaker_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(speaker_label)
	text_label=RichTextLabel.new()
	text_label.bbcode_enabled=false
	text_label.custom_minimum_size=Vector2(0,88)
	text_label.size_flags_vertical=Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("normal_font_size",22)
	text_label.scroll_active=false
	text_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	column.add_child(text_label)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	next_button=WhaleUIStyle.button("F / 空格 / Enter 继续",advance)
	skip_button=WhaleUIStyle.button("Esc 跳过本段",func() -> void: skip_requested.emit())
	for button: Button in [next_button,skip_button]:
		button.custom_minimum_size=Vector2(230,34)
		button.focus_mode=Control.FOCUS_NONE
		buttons.add_child(button)
	hide()

func present(speaker: String, value: String) -> void:
	speaker_label.text=speaker
	text_label.text=value
	reveal=0.0
	text_label.visible_characters=0
	input_lock=0.15

func advance() -> void:
	if input_lock>0.0: return
	if text_label.visible_characters<text_label.get_total_character_count():
		reveal=float(text_label.get_total_character_count())
		text_label.visible_characters=int(reveal)
	else: advance_requested.emit()

func _process(dt: float) -> void:
	if not visible: return
	input_lock=maxf(0.0,input_lock-dt)
	reveal+=dt*38.0
	text_label.visible_characters=mini(int(reveal),text_label.get_total_character_count())

static func install(ui: WhaleCampaignUI) -> void:
	ui.dialogue_view = WhaleDialoguePanel.new()
	ui.panel.add_child(ui.dialogue_view)
	ui.dialogue_view.advance_requested.connect(ui.host.dialogue.advance)
	ui.dialogue_view.skip_requested.connect(func() -> void: ui.host.dialogue.finish(true))
	ui.host.dialogue.started.connect(func(_spec: Dictionary) -> void:
		# 复用菜单的暂停和按键释放流程，控制所有权不在呈现层重复维护。
		ui.player.velocity=Vector2.ZERO
		ui.open("dialogue",false))
	ui.host.dialogue.line_changed.connect(ui.dialogue_view.present)
	ui.host.dialogue.ended.connect(ui.close_all)
	ui.subtitle_label = WhaleUIStyle.paragraph("",WhaleUIStyle.BONE)
	ui.subtitle_label.add_theme_font_size_override("font_size",21)
	ui.subtitle_label.add_theme_constant_override("outline_size",6)
	ui.subtitle_label.add_theme_color_override("font_outline_color",Color.BLACK)
	ui.panel.add_child(ui.subtitle_label)
	ui.subtitle_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	ui.subtitle_label.offset_left=-420
	ui.subtitle_label.offset_right=420
	ui.subtitle_label.offset_top=-170
	ui.subtitle_label.offset_bottom=-100
	ui.host.dialogue.subtitle_changed.connect(func(value: String) -> void: ui.subtitle_label.text=value)

static func handle_key(ui: WhaleCampaignUI, event: InputEventKey) -> bool:
	if ui.page_id!="dialogue": return false
	var code: int = event.physical_keycode if event.physical_keycode else event.keycode
	if code in [KEY_F,KEY_SPACE,KEY_ENTER]: ui.dialogue_view.advance()
	elif code==KEY_ESCAPE: ui.host.dialogue.finish(true)
	ui.get_viewport().set_input_as_handled()
	return true
