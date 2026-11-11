class_name WhaleUIPages
extends RefCounted

static func menu(ui: WhaleCampaignUI, width: float = 420) -> VBoxContainer:
	var center := CenterContainer.new()
	ui.body.add_child(center)
	var result := VBoxContainer.new()
	result.custom_minimum_size.x = width
	result.add_theme_constant_override("separation", 13)
	center.add_child(result)
	return result

static func action(parent: Node, id: String, text: String, callback: Callable, enabled: bool = true) -> Button:
	var button: Button = WhaleUIStyle.button(text,callback,enabled)
	button.name = id
	parent.add_child(button)
	return button

static func build(ui: WhaleCampaignUI, page: String) -> void:
	ui.footer.text = "Tab 移动焦点 · Enter 确认 · Esc 返回"
	match page:
		"title": _title(ui)
		"confirm_new": _confirm(ui)
		"pause": _pause(ui)
		"settings": WhaleUISettingsPage.build(ui)
		"map": _map(ui)
		"camp": _camp(ui)
		"death": _death(ui)
		"help": _help(ui)

static func _title(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "鲸落万物生 · 遗潮回声"
	var column: VBoxContainer = menu(ui)
	column.add_child(WhaleUIStyle.label("一鲸沉落，万物向生。",20,WhaleUIStyle.MUTED))
	var save: Dictionary = WhaleUISaveAccess.read(ui.host.save_path(),ui.host.rooms)
	var can_continue: bool = not save.is_empty()
	if can_continue:
		var location: String = str(ui.host.rooms[int(save.checkpoint.room)].name)
		column.add_child(WhaleUIStyle.label("已记录的检查点 · "+location,16,WhaleUIStyle.AMBER))
	action(column,"Continue","继续旅途",func() -> void: ui.start_game(false),can_continue)
	action(column,"NewGame","开始新的旅途",func() -> void:
		if FileAccess.file_exists(ui.host.save_path()): ui.open("confirm_new")
		else: ui.start_game(true))
	action(column,"Settings","设置",func() -> void: ui.open("settings"))
	action(column,"Help","操作说明",func() -> void: ui.open("help"))
	if not can_continue: column.add_child(WhaleUIStyle.paragraph("没有可继续的有效存档。新旅途从外伤坡开始。"))
	ui.footer.text = "沿潮声，走向深处。"

static func _confirm(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "开始新的旅途？"
	var column: VBoxContainer = menu(ui,560)
	column.add_child(WhaleUIStyle.paragraph("当前检查点、能力与收集进度将被新旅途替换。\n原存档会另存为备份，新旅途写入失败时保留原件。"))
	action(column,"CancelNew","保留当前旅途",ui.back)
	action(column,"ConfirmNew","确认开始新旅途",func() -> void: ui.start_game(true))

static func _pause(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "潮声暂歇"
	var column: VBoxContainer = menu(ui)
	column.add_child(WhaleUIStyle.label("须门遗港 · "+str(ui.host.room.name),18,WhaleUIStyle.MUTED))
	action(column,"Resume","继续旅途",ui.close_all)
	action(column,"Map","查看地图",func() -> void: ui.open("map"))
	action(column,"Settings","设置",func() -> void: ui.open("settings"))
	action(column,"Help","操作说明",func() -> void: ui.open("help"))
	action(column,"Title","返回标题",func() -> void:
		ui.history.clear()
		ui.open("title",false))
	column.add_child(WhaleUIStyle.paragraph("返回标题后再继续，将回到最近保存的检查点。"))

static func _map(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "潮路手记 · 须门遗港"
	var map := WhaleUIMap.new()
	map.data = ui.data
	map.custom_minimum_size = Vector2(0,310)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.body.add_child(map)
	var detail: Label = WhaleUIStyle.paragraph("")
	detail.custom_minimum_size.y = 74
	detail.name = "MapDetail"
	ui.body.add_child(detail)
	map.selected.connect(func(index: int) -> void:
		detail.text = str(ui.host.rooms[index].name)+"\n"+ui.data.room_description(index))
	map.select_room(ui.host.room_index)
	var row: VBoxContainer = menu(ui)
	action(row,"Back","返回",ui.back)
	ui.footer.text = "房间连接示意 · 三角：所在 · 壳形：营地 · 菱形：能力门 · 虚线：已知未探索 · 未知留白"

static func _camp(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "壳巢歇息 · "+str(ui.host.room.name)
	var column: VBoxContainer = menu(ui,660)
	column.add_child(WhaleUIStyle.icon("shell"))
	column.add_child(WhaleUIStyle.label("在旧壳中，让潮声平息。",22))
	column.add_child(WhaleUIStyle.paragraph("生命 %d / %d · 蓄振 %d / %d" % [ui.player.health,ui.player.max_health,ui.player.soul,ui.player.max_soul]))
	column.add_child(WhaleUIStyle.paragraph("检查点已记录，生命已恢复。\n营地不会恢复蓄振；蓄振通过战斗获得。" if ui.host.last_save_ok else "生命已恢复，但进度写入失败。请检查存储空间。",WhaleUIStyle.AMBER))
	column.add_child(WhaleUIStyle.label("共生栖位",23))
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation",16)
	column.add_child(slots)
	for text: String in ["运动槽 · 未开放","共鸣槽 · 未开放"]:
		var locked: Button = WhaleUIStyle.button(text,func() -> void: pass,false)
		locked.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slots.add_child(locked)
	column.add_child(WhaleUIStyle.paragraph("本章尚未开放共生模块的获取与配置。当前没有可装备模块。"))
	action(column,"LeaveCamp","继续旅途",ui.close_all)

static func _death(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "归于微光"
	var column: VBoxContainer = menu(ui,540)
	column.add_child(WhaleUIStyle.icon("leaf",Vector2(52,70)))
	column.add_child(WhaleUIStyle.label("潮水会记得来路。",24))
	var index: int = clampi(int(ui.host.checkpoint.room),0,ui.host.rooms.size()-1)
	column.add_child(WhaleUIStyle.paragraph(("重新挑战将回到本房入口，双方生命恢复。\n" if not ui.data.boss().is_empty() else "")+"返回检查点："+str(ui.host.rooms[index].name)+"。\n本次已获得的能力、收集和开启的通路保留。"))
	if not ui.data.boss().is_empty():
		action(column,"Retry",WhaleUIStyle.key("tp_respawn")+"  重新挑战",ui.retry)
		action(column,"Checkpoint","返回检查点",func() -> void: ui.retry(true))
	else:
		action(column,"Retry",WhaleUIStyle.key("tp_respawn")+"  返回检查点",ui.retry)
	ui.footer.text = "R / Enter 重试 · 鼠标点击选择"

static func _help(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "拾潮者 · 操作手记"
	var column: VBoxContainer = menu(ui,780)
	var entries: Array[Array] = [["tp_left","tp_right","移动"],["tp_jump","","跳跃 / 二段跳"],["tp_attack","","短击；方向配合上挑 / 下劈"],["tp_dash","","贴流冲（需解锁）"],["tp_orb","","鸣弹；上 / 下配合潮术"],["tp_heavy","","重鸣"],["tp_heal","","调息：落地且生命未满"],["tp_interact","","营地、补给与通行节点"]]
	for entry: Array in entries:
		var key_text: String = WhaleUIStyle.key(str(entry[0]))
		if not str(entry[1]).is_empty(): key_text += " / "+WhaleUIStyle.key(str(entry[1]))
		column.add_child(WhaleUIStyle.label(key_text+"    "+str(entry[2]),17))
	column.add_child(WhaleUIStyle.paragraph("C 地图 · Tab 镜头 · Esc 暂停 · M 静音 · H 帮助\nW 浮游 · G 锚定 · B 迎珠 · T 探潮 · V 蓄力长冲\nF5 存档 · F6 读取 · F9 临时练习 · F10 练习技能组"))
	action(column,"HelpBack","返回",ui.back)
