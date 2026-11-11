class_name WhaleCampaignUI
extends CanvasLayer

var host: Node2D
var player: TidePlayer
var data := WhaleUICampaignData.new()
var preferences := WhaleUIPreferences.new()
var panel: Control
var hud: WhaleCampaignHUD
var modal: Control
var body: VBoxContainer
var heading: Label
var footer: Label
var page_id: String = ""
var history: Array[String] = []
var focus_history: Dictionary = {}
var health_value: int = 0
var soul_value: int = 0
var notice_text: String = ""
var notice_left: float = 0.0
var location_left: float = 4.0
var pending_resume: bool = false
var resume_wait: float = 0.0
var previous_controls: bool = true
var previous_pause: bool = false
var busy: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	data.host = host
	if host.qa: preferences.path = "user://whalebelly/ui_qa_settings.cfg"
	preferences.read()
	preferences.apply(host)
	panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.theme = WhaleUIStyle.theme(preferences.contrast)
	add_child(panel)
	hud = WhaleCampaignHUD.new()
	hud.controller = self
	panel.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal = Control.new()
	panel.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.018, 0.055, 0.075, 0.96)
	modal.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	modal.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]: margin.add_theme_constant_override("margin_"+side, 52)
	for side: String in ["top", "bottom"]: margin.add_theme_constant_override("margin_"+side, 25)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	heading = WhaleUIStyle.label("", 36)
	column.add_child(heading)
	column.add_child(WhaleUIStyle.icon("ornament", Vector2(300, 33)))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 15)
	scroll.add_child(body)
	footer = WhaleUIStyle.label("", 15, WhaleUIStyle.MUTED)
	column.add_child(footer)
	modal.hide()
	bind_player(host.player)

func bind_player(next: TidePlayer) -> void:
	if is_instance_valid(player) and player.stats_changed.is_connected(_stats): player.stats_changed.disconnect(_stats)
	player = next
	player.stats_changed.connect(_stats)
	_stats(player.health, player.soul)
	location_left = 4.0
	if page_id == "death": close_all()

func _stats(hp: int, soul: int) -> void:
	health_value = hp
	soul_value = soul

func show_notice(text: String) -> void:
	if text == notice_text and notice_left > 0: return
	notice_text = text
	notice_left = 3.5

func clear_input() -> void:
	if not is_instance_valid(player): return
	player.skill_controller.input.clear()
	player.pending_action = ""
	player.pending_left = 0.0
	player.jump_buffer = 0.0

func open(page: String, push: bool = true) -> void:
	if busy: return
	if page_id.is_empty() and not pending_resume:
		previous_controls = player.controls_enabled
		previous_pause = get_tree().paused
	if not page_id.is_empty():
		var focused: Control = get_viewport().gui_get_focus_owner()
		if is_instance_valid(focused): focus_history[page_id] = focused.name
		if push and page_id != page: history.append(page_id)
	pending_resume = false
	clear_input()
	player.controls_enabled = false
	get_tree().paused = true
	page_id = page
	for child: Node in body.get_children():
		body.remove_child(child)
		child.queue_free()
	modal.show()
	hud.hide()
	WhaleUIPages.build(self, page)
	_focus_page.call_deferred()
	host.record_event("ui_open", {"page":page})

func _focus_page() -> void:
	var candidates: Array[Node] = body.find_children("*", "Control", true, false)
	var first: Control
	for node: Control in candidates:
		if node.focus_mode != Control.FOCUS_ALL or (node is BaseButton and node.disabled): continue
		if first == null: first = node
		if str(node.name) == str(focus_history.get(page_id, "")):
			node.grab_focus()
			return
	if first != null: first.grab_focus()

func back() -> void:
	if busy: return
	if not history.is_empty(): open(history.pop_back(), false)
	elif page_id not in ["title", "death"]: close_all()

func close_all() -> void:
	page_id = ""
	history.clear()
	modal.hide()
	hud.show()
	clear_input()
	get_viewport().gui_release_focus()
	pending_resume = true
	resume_wait = 0.12

func start_game(fresh: bool) -> void:
	if busy: return
	busy = true
	if not host.start_ui_session(fresh):
		busy = false
		footer.text = "无法写入存档，旧进度已保留，请检查存储空间。"
		return
	busy = false
	previous_controls = true
	previous_pause = false
	close_all()

func retry() -> void:
	if busy: return
	busy = true
	await host.respawn()
	busy = false
	previous_controls = true
	previous_pause = false
	close_all()

func save_preferences() -> void:
	preferences.apply(host)
	panel.theme = WhaleUIStyle.theme(preferences.contrast)
	footer.text = "设置已保存 · Esc 返回" if preferences.write() == OK else "设置已生效，但写入失败；本次会话有效。"

func _input(event: InputEvent) -> void:
	if host.continuity.travelling or host.continuity.transition.active: return
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode == KEY_ESCAPE:
		if page_id.is_empty(): open("pause")
		else: back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_region_map") and page_id.is_empty():
		open("map")
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_H and page_id.is_empty():
		open("help")
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_M:
		preferences.muted = not preferences.muted
		save_preferences()
		var mute_toggle: CheckButton = body.find_child("Mute",true,false) as CheckButton
		if page_id == "settings" and mute_toggle != null:
			mute_toggle.set_pressed_no_signal(preferences.muted)
			mute_toggle.text = "开启" if preferences.muted else "关闭"
		show_notice("音效已静音" if preferences.muted else "音效已开启")
		get_viewport().set_input_as_handled()
	elif page_id == "death" and event.is_action_pressed("tp_respawn"):
		retry()
		get_viewport().set_input_as_handled()

func _process(dt: float) -> void:
	if not is_instance_valid(player): return
	if not get_tree().paused:
		notice_left = maxf(0.0, notice_left-dt)
		location_left = maxf(0.0, location_left-dt)
	if pending_resume:
		resume_wait -= dt
		var held: bool = false
		for action: StringName in InputMap.get_actions():
			if str(action).begins_with("tp_") or action in [&"left", &"right", &"jump", &"attack", &"interact", &"float", &"grapple"]:
				held = held or Input.is_action_pressed(action)
		if resume_wait <= 0 and not held:
			clear_input()
			player.controls_enabled = previous_controls
			get_tree().paused = previous_pause
			pending_resume = false
			host.record_event("ui_resume", {})
	hud.queue_redraw()

func _exit_tree() -> void:
	if is_instance_valid(player) and player.stats_changed.is_connected(_stats): player.stats_changed.disconnect(_stats)
	if not page_id.is_empty() or pending_resume: get_tree().paused = previous_pause

func control_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node: Node in panel.find_children("*","Control",true,false):
		if not (node is BaseButton or node is HSlider) or not node.is_visible_in_tree(): continue
		var rect: Rect2 = node.get_global_rect()
		result.append({"name":str(node.name),"x":rect.position.x,"y":rect.position.y,"width":rect.size.x,"height":rect.size.y,"disabled":node.disabled if node is BaseButton else false})
	return result
