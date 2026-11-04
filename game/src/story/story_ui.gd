class_name StoryUI
extends CanvasLayer
## Presentation only: the host owns simulation pause, saves, and chapter transitions.

signal dialogue_finished(id: String)
signal dialogue_closed(id: String)
signal start_requested(fresh: bool)
signal retry_requested
signal pause_changed(paused: bool)
signal title_requested

var modal_open: bool = false
var page: String = ""
var dialogue_id: String = ""
var dialogue_index: int = 0
var root: Control
var modal: PanelContainer
var body: VBoxContainer
var health_label: Label
var objective_label: Label
var hint_label: Label
var notice_label: Label
var dialogue_label: Label
var _lines: Array[String] = []
var _has_save: bool = false
var _armed: bool = false
var _opened_at: int = 0
var _notice_remaining: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = WhaleUIStyle.theme()
	add_child(root)
	var hud := VBoxContainer.new()
	hud.position = Vector2(24, 18)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	health_label = WhaleUIStyle.label("", 21, WhaleUIStyle.AMBER)
	objective_label = WhaleUIStyle.label("", 18)
	for label: Label in [health_label, objective_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hud.add_child(label)
	hint_label = WhaleUIStyle.label("", 18)
	root.add_child(hint_label)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_top = -48
	notice_label = WhaleUIStyle.label("", 18, WhaleUIStyle.AMBER)
	root.add_child(notice_label)
	notice_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	notice_label.offset_top = 100
	modal = PanelContainer.new()
	modal.add_theme_stylebox_override("panel", WhaleUIStyle.box(Color("07151df5"), WhaleUIStyle.TEAL))
	root.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	modal.offset_left = -340
	modal.offset_right = 340
	modal.offset_top = -200
	modal.offset_bottom = 200
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	modal.add_child(body)
	modal.hide()

func _process(delta: float) -> void:
	if not _armed and Time.get_ticks_msec() - _opened_at > 180:
		_armed = not (Input.is_physical_key_pressed(KEY_E) or Input.is_physical_key_pressed(KEY_ENTER)
			or Input.is_physical_key_pressed(KEY_KP_ENTER))
	if _notice_remaining > 0:
		_notice_remaining -= delta
		if _notice_remaining <= 0: notice_label.text = ""

func set_hud(health: int, objective: String, hint: String) -> void:
	health_label.text = "拾潮者  ·  生命 %d" % health
	objective_label.text = objective
	hint_label.text = hint

func show_notice(text: String) -> void:
	notice_label.text = text
	_notice_remaining = 7.0

func show_title(has_save: bool) -> void:
	_has_save = has_save
	_open("title", "鲸腹遗城")
	body.add_child(WhaleUIStyle.label("第一章 · 须庭", 24, WhaleUIStyle.AMBER))
	body.add_child(WhaleUIStyle.paragraph("循着低鸣，走进仍有人生活的遗城。"))
	if has_save: _button("继续旅途", func() -> void: _start(false))
	if has_save: _button("开始新旅途", _confirm_new)
	else: _button("开始新旅途", func() -> void: _start(true))
	body.add_child(WhaleUIStyle.paragraph("A / D 移动 · Space 跳跃 · J 短击\nE 共鸣 / 交互 · Esc 暂停 · M 静音"))
	_focus_first()

func _confirm_new() -> void:
	_open("confirm", "开始新旅途？")
	body.add_child(WhaleUIStyle.paragraph("当前章节将重新开始，原旅途会先备份。"))
	_button("返回", func() -> void: show_title(_has_save))
	_button("确认开始", func() -> void: _start(true))
	_focus_first()

func _start(fresh: bool) -> void:
	hide_modal()
	start_requested.emit(fresh)

func show_dialogue(id: String, lines: Array[String]) -> void:
	if lines.is_empty(): return
	dialogue_id = id
	dialogue_index = 0
	_lines = lines.duplicate()
	_open("dialogue", "共鸣 · 补巢者")
	dialogue_label = WhaleUIStyle.paragraph(_lines[0], WhaleUIStyle.BONE)
	dialogue_label.custom_minimum_size.y = 100
	body.add_child(dialogue_label)
	_button("继续  E / Enter", _next_line)
	_button("暂别  Esc", _close_dialogue)
	pause_changed.emit(true)
	_focus_first()

func _next_line() -> void:
	if not _armed: return
	dialogue_index += 1
	if dialogue_index < _lines.size():
		dialogue_label.text = _lines[dialogue_index]
		return
	var completed: String = dialogue_id
	hide_modal()
	pause_changed.emit(false)
	dialogue_finished.emit(completed)

func _close_dialogue() -> void:
	var closed: String = dialogue_id
	hide_modal()
	pause_changed.emit(false)
	dialogue_closed.emit(closed)

func show_death() -> void:
	_open("death", "低鸣仍在")
	body.add_child(WhaleUIStyle.paragraph("从安全台重新出发。已经保存的交流与进度会保留。"))
	_button("重新出发  R", _retry)
	_button("返回标题", _title)
	_focus_first()

func _retry() -> void:
	hide_modal()
	retry_requested.emit()

func show_complete() -> void:
	_open("complete", "第一章完成 · 须庭")
	body.add_child(WhaleUIStyle.paragraph("你已获知折井的方向。\n第二章尚未开放，可以留在须庭继续探索。"))
	_button("继续探索", _resume)
	_button("返回标题", _title)
	pause_changed.emit(true)
	_focus_first()

func show_pause() -> void:
	_open("pause", "旅途暂歇")
	_button("继续探索  Esc", _resume)
	_button("返回标题", _title)
	pause_changed.emit(true)
	_focus_first()

func _resume() -> void:
	hide_modal()
	pause_changed.emit(false)

func _title() -> void:
	title_requested.emit()

func hide_modal() -> void:
	modal.hide()
	modal_open = false
	page = ""
	var focus: Control = root.get_viewport().gui_get_focus_owner()
	if focus != null: focus.release_focus()

func _open(next_page: String, heading: String) -> void:
	for child: Node in body.get_children():
		body.remove_child(child)
		child.queue_free()
	page = next_page
	modal_open = true
	_armed = false
	_opened_at = Time.get_ticks_msec()
	modal.show()
	body.add_child(WhaleUIStyle.label(heading, 30))

func _button(text: String, action: Callable) -> void:
	body.add_child(WhaleUIStyle.button(text, action))

func _focus_first() -> void:
	for child: Node in body.get_children():
		if child is Button:
			child.grab_focus()
			return

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var code: int = event.physical_keycode if event.physical_keycode else event.keycode
	if code == KEY_ESCAPE:
		if not modal_open: show_pause()
		elif page == "dialogue": _close_dialogue()
		elif page == "pause" or page == "complete": _resume()
		elif page == "confirm": show_title(_has_save)
		get_viewport().set_input_as_handled()
	elif modal_open and code in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_R]:
		get_viewport().set_input_as_handled()
		if not _armed: return
		if page == "dialogue" and code in [KEY_E, KEY_ENTER, KEY_KP_ENTER]: _next_line()
		elif page == "death" and code == KEY_R: _retry()
		elif code in [KEY_ENTER, KEY_KP_ENTER]:
			var focus: Control = get_viewport().gui_get_focus_owner()
			if focus is Button: focus.pressed.emit()
