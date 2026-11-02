class_name CrabArenaUI
extends CanvasLayer

var title: Label
var stats: Label
var skills_status: Label
var message: Label
var victory_panel: Control
var result_time: Label
var boss_title: Label
var stagger_label: Label
var boss_bar: ProgressBar
var stagger_bar: ProgressBar
var start_button: Button
var dash_button: Button
var pause_button: Button
var shake_button: Button
var help_panel: Control
var help_button: Button
var help_expanded := true
var help_folded_once := false
@onready var arena: CrabArena = get_parent() as CrabArena


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = load("res://src/ui/theme.tres") as Theme
	add_child(root)
	_panel(root, Rect2(16, 12, 880, 112))
	help_panel = Control.new()
	help_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(help_panel)
	_panel(help_panel, Rect2(16, 636, 890, 74))
	title = _label(root, Vector2(32, 22), 22)
	title.text = "搬壳母蟹 · 独立训练场"
	stats = _label(root, Vector2(32, 58), 20)
	skills_status = _label(root, Vector2(32, 88), 17)
	boss_title = _label(root, Vector2(440, 22), 20)
	boss_bar = _bar(root, Rect2(440, 54, 424, 18), Color(0.77, 0.46, 0.23))
	stagger_label = _label(root, Vector2(440, 82), 15)
	stagger_bar = _bar(root, Rect2(584, 86, 280, 10), Color(0.38, 0.77, 0.86))
	message = _label(root, Vector2(310, 155), 22)
	message.size = Vector2(660, 100)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var controls := _label(help_panel, Vector2(32, 648), 18)
	controls.text = "A / D 移动   Space 跳跃（长按跳高）   J 连击   K 重击   U 蓄力   F 治疗   Esc 暂停\nU 松开发射 · J 打中可接 J / K · K 和 F 消耗 2 蓄振"
	start_button = _button(root, Vector2(970, 22), "开始 · Enter", arena.start)
	dash_button = _button(root, Vector2(970, 70), "冲刺：关闭", arena.toggle_dash)
	pause_button = _button(root, Vector2(970, 118), "暂停 · Esc", arena.toggle_pause)
	shake_button = _button(root, Vector2(970, 166), "震动：开启", _toggle_shake)
	help_button = _button(root, Vector2(1010, 660), "操作 · H", toggle_help)
	help_button.size.x = 230
	victory_panel = Control.new()
	victory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(victory_panel)
	_label(victory_panel, Vector2(38, 17), 17).text = "搬壳母蟹 · 战斗胜利"
	var praise := _label(victory_panel, Vector2(36, 40), 34)
	praise.text = "潮声为你回响"
	praise.modulate = Color(1.0, 0.86, 0.59)
	_label(victory_panel, Vector2(38, 95), 18).text = "做得好，你找到了破绽！"
	result_time = _label(victory_panel, Vector2(570, 60), 20)
	victory_panel.hide()


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


func _bar(root: Control, area: Rect2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = area.position
	bar.size = area.size
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	root.add_child(bar)
	return bar


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


func toggle_help() -> void:
	help_expanded = not help_expanded
	help_folded_once = true


func _process(_delta: float) -> void:
	if stats == null:
		return
	stats.text = "生命 %d / %d   蓄振 %d / %d" % [GameState.hp, arena.player.health.maximum,
		GameState.energy, GameState.MAX_ENERGY]
	stats.modulate = Color(1.0, 0.8, 0.65) if GameState.hp <= 2 else Color.WHITE
	skills_status.text = _skill_hint()
	if arena.stage == "fighting" and arena.battle_time >= 6 and not help_folded_once:
		help_expanded = false
		help_folded_once = true
	help_panel.visible = help_expanded or get_tree().paused
	help_button.text = "收起操作 · H" if help_panel.visible else "操作 · H"
	boss_bar.max_value = arena.boss.health.maximum
	boss_bar.value = arena.boss.health.current
	_update_boss_hud()
	start_button.disabled = arena.stage in ["entering", "fighting"]
	start_button.visible = not start_button.disabled
	dash_button.visible = not start_button.disabled
	shake_button.visible = not start_button.disabled
	pause_button.position.y = 22 if start_button.disabled else 118
	start_button.text = "开始 · Enter" if arena.stage == "ready" else "再试一次 · Enter"
	dash_button.disabled = start_button.disabled
	dash_button.text = "冲刺：开启 · Shift" if arena.dash_enabled else "冲刺：关闭"
	pause_button.disabled = not start_button.disabled
	pause_button.text = "继续 · Esc" if get_tree().paused else "暂停 · Esc"
	shake_button.text = "震动：开启" if arena.shake_enabled else "震动：关闭"
	var won := arena.stage == "won"
	victory_panel.visible = won
	for item: CanvasItem in [title, stats, skills_status, boss_title, boss_bar, stagger_label, stagger_bar, message]:
		item.visible = not won
	match arena.stage:
		"ready": message.text = "跳过低扫，收钳反击\n按 Enter 开始"
		"entering": message.text = "看钳子，等破绽"
		"won": result_time.text = "%.1f 秒 · 按 Enter 再战" % arena.battle_time
		"lost": message.text = "别泄气，下一次等它收钳再反击\n按 Enter 立即重试"
		_: message.text = "已暂停" if get_tree().paused else _combat_hint()
	stagger_bar.visible = not won and not arena.boss.hurtbox.braced() and arena.boss.stagger_cooldown <= 0


func _update_boss_hud() -> void:
	var boss := arena.boss
	boss_title.text = "搬壳母蟹 · " + _phase_name(boss.phase + 1 if boss.state == "phase" else boss.phase)
	stagger_bar.max_value = CrabMoves.STAGGER_LIMIT
	stagger_bar.value = CrabMoves.STAGGER_LIMIT if boss.state == "stagger" else boss.stagger
	stagger_label.text = "护壳 · 减伤" if boss.hurtbox.braced() else "破绽 · 可反击"
	stagger_label.modulate = Color(0.66, 0.84, 1.0) if boss.hurtbox.braced() else Color(1.0, 0.88, 0.60)
	if boss.state == "stagger":
		stagger_label.text = "破防！"


func _phase_name(phase: int) -> String:
	return ["一阶段 · 试探", "二阶段 · 连击", "三阶段 · 猛攻"][clampi(phase - 1, 0, 2)]


func _skill_hint() -> String:
	var shield := "护盾就绪" if arena.player.hurtbox.guard > 0 else "护盾积累 %d / %d" % [arena.skills.shield_charge, TrainingSkills.SHIELD_HITS]
	if arena.player.actions.mode == "aim":
		return shield + ("    蓄满 · 松开 U" if arena.player.actions.elapsed >= TrainingSkills.CHARGE_TIME else "    正在蓄力")
	return shield


func _combat_hint() -> String:
	var boss := arena.boss
	match boss.state:
		"phase":
			return _phase_name(mini(boss.phase + 1, 3))
		"stagger": return "破防！反击"
		"recover": return "收钳 · 反击"
		"tell", "active":
			if boss.hurtbox.counter_window():
				return "举钳 · K 打断"
			var move := "低扫 · 跳"
			if boss.kind == "slam":
				move = "下砸 · 后退"
			elif boss.kind == "charge":
				move = "冲撞 · 后退"
			return move + ("  %d/%d" % [boss.sequence_index + 1, boss.sequence.size()] if boss.sequence.size() > 1 else "")
	return ""
