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
var skip_pending: bool = false
var panel: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	panel = PanelContainer.new()
	add_child(panel)
	resized.connect(_layout)
	_layout()
	apply_style(false)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	panel.add_child(column)
	speaker_label=WhaleUIStyle.label("",22,WhaleUIStyle.BONE)
	speaker_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(speaker_label)
	text_label=RichTextLabel.new()
	text_label.bbcode_enabled=false
	text_label.custom_minimum_size=Vector2(0,24)
	text_label.size_flags_vertical=Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("normal_font_size",20)
	text_label.scroll_active=true
	text_label.mouse_filter=Control.MOUSE_FILTER_PASS
	column.add_child(text_label)
	var buttons := HBoxContainer.new()
	buttons.alignment=BoxContainer.ALIGNMENT_END
	column.add_child(buttons)
	next_button=WhaleUIStyle.button("F / 空格 / Enter 继续",advance)
	skip_button=WhaleUIStyle.button("Esc 跳过本段",request_skip)
	for button: Button in [next_button,skip_button]:
		button.focus_mode=Control.FOCUS_ALL
		buttons.add_child(button)
		WhaleUIStyle.compact_button(button)
	hide()

func _layout() -> void:
	var value: String = text_label.text if is_instance_valid(text_label) else ""
	var bounds: Rect2 = WhaleUIStyle.dialogue_rect(size,value)
	panel.position = bounds.position
	panel.size = bounds.size

func apply_style(high_contrast: bool) -> void:
	var style := WhaleUIStyle.surface(high_contrast)
	style.content_margin_top=12
	style.content_margin_bottom=12
	panel.add_theme_stylebox_override("panel",style)

func request_skip() -> void:
	if input_lock>0.0: return
	if skip_pending:
		skip_requested.emit()
	else:
		skip_pending = true
		skip_button.text = "再次确认跳过 · Esc / Enter"
		skip_button.grab_focus()

func present(speaker: String, value: String) -> void:
	speaker_label.text=speaker
	text_label.text=value
	reveal=0.0
	text_label.visible_characters=0
	input_lock=0.15
	skip_pending=false
	skip_button.text="Esc 跳过本段"
	text_label.scroll_to_line(0)
	_layout.call_deferred()

func advance() -> void:
	if input_lock>0.0: return
	skip_pending=false
	skip_button.text="Esc 跳过本段"
	next_button.grab_focus()
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
	ui.subtitle_label.offset_top=-270
	ui.subtitle_label.offset_bottom=-200
	ui.host.dialogue.subtitle_changed.connect(func(value: String) -> void: ui.subtitle_label.text=value)

static func handle_key(ui: WhaleCampaignUI, event: InputEventKey) -> bool:
	if ui.page_id!="dialogue": return false
	var code: int = event.physical_keycode if event.physical_keycode else event.keycode
	if code in [KEY_F,KEY_SPACE]: ui.dialogue_view.advance()
	elif code==KEY_ENTER:
		if ui.dialogue_view.skip_button.has_focus(): ui.dialogue_view.request_skip()
		else: ui.dialogue_view.advance()
	elif code==KEY_ESCAPE: ui.dialogue_view.request_skip()
	else: return false
	ui.get_viewport().set_input_as_handled()
	return true
