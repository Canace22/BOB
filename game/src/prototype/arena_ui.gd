class_name CrabArenaUI
extends CanvasLayer

var title: Label
var stats: Label
var message: Label
var boss_bar: ProgressBar
var start_button: Button
var dash_button: Button
var pause_button: Button
var shake_button: Button
@onready var arena: CrabArena = get_parent() as CrabArena


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = load("res://src/ui/theme.tres") as Theme
	add_child(root)
	_panel(root, Rect2(16, 12, 880, 82))
	_panel(root, Rect2(16, 636, 890, 74))
	title = _label(root, Vector2(32, 22), 22)
	title.text = "搬壳母蟹 · 独立训练场"
	stats = _label(root, Vector2(32, 58), 20)
	var boss_title := _label(root, Vector2(510, 22), 20)
	boss_title.text = "搬壳母蟹"
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(440, 58)
	boss_bar.size = Vector2(400, 20)
	boss_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.77, 0.46, 0.23)
	fill.set_corner_radius_all(4)
	boss_bar.add_theme_stylebox_override("fill", fill)
	root.add_child(boss_bar)
	message = _label(root, Vector2(310, 145), 22)
	message.size = Vector2(660, 100)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var controls := _label(root, Vector2(32, 648), 18)
	controls.text = "A / D 移动   Space 跳跃（长按跳高）   J 轻击   K 重击   F 治疗   Esc 暂停\n重击 / 治疗消耗 2 蓄振；本训练场不写入主线存档。"
	start_button = _button(root, Vector2(970, 22), "开始 · Enter", arena.start)
	dash_button = _button(root, Vector2(970, 70), "冲刺：关闭", arena.toggle_dash)
	pause_button = _button(root, Vector2(970, 118), "暂停 · Esc", arena.toggle_pause)
	shake_button = _button(root, Vector2(970, 166), "震动：开启", _toggle_shake)


func _label(root: Control, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	root.add_child(label)
	return label


func _panel(root: Control, area: Rect2) -> void:
	var panel := ColorRect.new()
	panel.position = area.position
	panel.size = area.size
	panel.color = Color(0.02, 0.06, 0.08, 0.8)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)


func _button(root: Control, at: Vector2, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.position = at
	button.size = Vector2(275, 40)
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	root.add_child(button)
	return button


func _toggle_shake() -> void:
	arena.shake_enabled = not arena.shake_enabled


func _process(_delta: float) -> void:
	if stats == null:
		return
	stats.text = "生命 %d / 4   蓄振 %d / 4   %.1f 秒" % [GameState.hp, GameState.energy, arena.battle_time]
	boss_bar.max_value = arena.boss.health.maximum
	boss_bar.value = arena.boss.health.current
	start_button.disabled = arena.stage in ["entering", "fighting"]
	start_button.text = "开始 · Enter" if arena.stage == "ready" else "再试一次 · Enter"
	dash_button.disabled = start_button.disabled
	dash_button.text = "冲刺：开启 · Shift" if arena.dash_enabled else "冲刺：关闭"
	pause_button.disabled = not start_button.disabled
	pause_button.text = "继续 · Esc" if get_tree().paused else "暂停 · Esc"
	shake_button.text = "震动：开启" if arena.shake_enabled else "震动：关闭"
	match arena.stage:
		"ready": message.text = "看钳子读招，躲开后反击\n按 Enter 开始；可先切换冲刺对照模式"
		"entering": message.text = "准备"
		"won": message.text = "搬壳母蟹退让了\n%.1f 秒 · 按 Enter 再战" % arena.battle_time
		"lost": message.text = "这次失手了\n按 Enter 立即重试"
		_: message.text = "已暂停" if get_tree().paused else ("母蟹蓄势 · 接下来会有二连扫" if arena.boss.state == "phase" else "")
