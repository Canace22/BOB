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
		"camp": WhaleUICampPage.build(ui)
		"camp_details": WhaleUICampPage.details(ui)
		"death": _death(ui)
		"help": _help(ui)
		"ending": _ending(ui)
		"conversation": _conversation(ui)

static func layout(ui: WhaleCampaignUI) -> void:
	var talking: bool = ui.page_id == "conversation"
	var resting: bool = ui.page_id in ["camp", "camp_details"]
	for control: Control in [ui.shade, ui.margin]:
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if talking or resting:
			var width: float = minf(620.0 if resting else 900.0, ui.panel.size.x - 48.0)
			control.offset_left = (ui.panel.size.x - width) * 0.5
			control.offset_right = -control.offset_left
			var height: float = minf(500.0, ui.panel.size.y - 48.0) if resting else minf(260.0, ui.panel.size.y * 0.4)
			control.offset_top = (ui.panel.size.y - height) * 0.5 if resting else ui.panel.size.y - height - 24.0
			control.offset_bottom = -control.offset_top if resting else -24.0
			if talking:
				var bounds: Rect2 = WhaleUIStyle.dialogue_rect(ui.panel.size,"\n".join(ui.conversation_lines),120)
				control.position = bounds.position
				control.size = bounds.size
	for side: String in ["left", "right"]: ui.margin.add_theme_constant_override("margin_"+side, 28 if resting else (24 if talking else 52))
	for side: String in ["top", "bottom"]: ui.margin.add_theme_constant_override("margin_"+side, 20 if resting else (12 if talking else 25))
	(ui.heading.get_parent() as VBoxContainer).add_theme_constant_override("separation",6 if talking else 12)
	var shade_alpha: float = 0.56 if ui.page_id == "title" else (0.68 if ui.page_id == "pause" else (0.92 if talking and not ui.preferences.contrast else 0.96))
	ui.shade.color = Color.BLACK if ui.page_id == "death" else Color(0.018, 0.055, 0.075, shade_alpha)
	if (talking or resting) and ui.preferences.contrast: ui.shade.color.a = 1.0
	ui.frame.visible = talking or resting
	ui.frame.position = ui.shade.position
	ui.frame.size = ui.shade.size
	ui.frame.add_theme_stylebox_override("panel",WhaleUIStyle.surface(ui.preferences.contrast))
	if talking or resting: ui.shade.color.a = 0.0
	ui.ornament.visible = not talking and not resting and ui.page_id != "map"
	ui.heading.visible = ui.page_id != "map"
	ui.footer.visible = not talking and ui.page_id != "map"
	ui.heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if talking else HORIZONTAL_ALIGNMENT_CENTER
	ui.heading.add_theme_font_size_override("font_size", 30 if resting else (22 if talking else 36))
	ui.body.alignment = BoxContainer.ALIGNMENT_BEGIN if talking else BoxContainer.ALIGNMENT_CENTER
	ui.body.add_theme_constant_override("separation", 6 if talking else 15)

static func _conversation(ui: WhaleCampaignUI) -> void:
	ui.heading.text = ui.conversation_title
	for line: String in ui.conversation_lines:
		var paragraph: Label = WhaleUIStyle.paragraph(line,WhaleUIStyle.BONE)
		paragraph.add_theme_font_size_override("font_size",20)
		paragraph.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		ui.body.add_child(paragraph)
	var close: Button = action(ui.body,"ConversationClose","F / Enter / Esc 返回",ui.back)
	WhaleUIStyle.compact_button(close)
	close.custom_minimum_size.x=120
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	ui.footer.text = "F / 空格 / Enter 返回 · Esc 返回"

static func _title(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "鲸落遗城"
	var column: VBoxContainer = menu(ui)
	column.add_child(WhaleUIStyle.label("一鲸沉落，万物向生。",20,WhaleUIStyle.MUTED))
	var save: Dictionary = WhaleUISaveAccess.read(ui.host.save_path(),ui.host.rooms)
	var can_continue: bool = not save.is_empty()
	if can_continue:
		var location: String = str(ui.host.rooms[int(save.checkpoint.room)].name)
		column.add_child(WhaleUIStyle.label("已记录的检查点 · "+location,16,WhaleUIStyle.AMBER))
	action(column,"Continue","继续旅途",func() -> void: ui.start_game(false),can_continue)
	action(column,"NewGame","重新开始" if can_continue else "开始旅程",func() -> void: request_new_game(ui))
	action(column,"Settings","设置",func() -> void: ui.open("settings"))
	action(column,"Help","操作说明",func() -> void: ui.open("help"))
	if not can_continue: column.add_child(WhaleUIStyle.paragraph("没有可继续的有效存档。新旅途从外伤坡开始。"))
	ui.footer.text = "Tab 选择 · Enter 确认 · 游戏中按 Esc 可重新开始或返回首页"

static func request_new_game(ui: WhaleCampaignUI) -> void:
	if ui.page_id != "title" or FileAccess.file_exists(ui.host.save_path()): ui.open("confirm_new")
	else: ui.start_game(true)

static func _confirm(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "重新开始？"
	var column: VBoxContainer = menu(ui,560)
	column.add_child(WhaleUIStyle.paragraph("当前检查点、能力与收集进度将被新旅途替换。\n原存档会另存为备份，新旅途写入失败时保留原件。"))
	action(column,"CancelNew","保留当前旅途",ui.back)
	action(column,"ConfirmNew","确认重新开始",func() -> void: ui.start_game(true))

static func _pause(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "潮声暂歇"
	var column: VBoxContainer = menu(ui)
	column.add_child(WhaleUIStyle.label(CampaignWorld.region_name(str(ui.host.room.id))+" · "+str(ui.host.room.name),18,WhaleUIStyle.MUTED))
	action(column,"Resume","继续旅途",ui.close_all)
	action(column,"Restart","重新开始",func() -> void: request_new_game(ui))
	action(column,"Map","查看地图",func() -> void: ui.open("map"))
	action(column,"Settings","设置",func() -> void: ui.open("settings"))
	action(column,"Help","操作说明",func() -> void: ui.open("help"))
	action(column,"Title","返回首页",func() -> void:
		ui.history.clear()
		ui.open("title",false))
	column.add_child(WhaleUIStyle.paragraph("返回首页后再继续，将回到最近保存的检查点。"))

static func _map(ui: WhaleCampaignUI) -> void:
	WhaleUIMapPage.build(ui)

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
	column.add_child(WhaleUIStyle.label("骨鸣器 · 开局即可攻击",22,WhaleUIStyle.AMBER))
	column.add_child(WhaleUIStyle.paragraph("空格起跳，空中松开再按一次可二段跳，落地后恢复。\n靠近敌人按 J 普攻，不消耗蓄振。\n负壳蟹：空格跳过低扫，下砸时后退；等整套连招结束、收钳后靠近按 J 反击。护壳时普攻仍可削血。"))
	var unlocked_ids: Array = ["dash", "float", "pressure", "bone", "silence"] + CampaignRelics.ITEMS.keys()
	for id: String in unlocked_ids:
		var relic: bool = CampaignRelics.ITEMS.has(id)
		if not bool((ui.host.collected if relic else ui.host.abilities).get(id, false)): continue
		var card: Dictionary = WhaleUnlockBanner.relic_card(id) if relic else WhaleUnlockBanner.ability_card(id)
		column.add_child(WhaleUIStyle.label(str(card.title), 22, WhaleUIStyle.AMBER))
		column.add_child(WhaleUIStyle.paragraph(str(card.detail)))
	column.add_child(WhaleUIStyle.paragraph("A/D 移动 · J 普攻 · I 格挡\nK 三段斩（每段可用 A/D 换向）· L 冲刺 · A/D+L 撞击\nW+J 上挑 · 地面 S+J 横扫 · 空中 S+J 下刺\nS+L 后跳并打断动作 · 后跳中 J 回斩\n点按 Q / E 后，下方展开四列组合技；预选保留 0.8 秒\nQ+E 辅助页 · E+I 按住调息 · Q+E+L 按住蓄力\nF 交互 · W 浮游 · G 锚定 · C 地图 · Esc 暂停\nM 静音 · H 帮助 · F5 存档 · F6 读取 · F9 临时练习\n小地图：白色为自己，编号对应出口，× 表示受阻。\n剧情对话：F / 空格继续，Tab选择按钮，Enter确认；跳过需再次确认。\n冲刺、回旋和五段连斩需原进度解锁；上涌、下潜需舌台奖励。"))
	action(column,"HelpBack","返回",ui.back)

## Placeholder closing text until the final chapter is written; the loop itself is complete.
static func _ending(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "归海"
	var column: VBoxContainer = menu(ui,660)
	column.add_child(WhaleUIStyle.label("三道槽依次亮起，导流闸缓缓打开。",22))
	column.add_child(WhaleUIStyle.paragraph("潮压、骨音与静默在槽中合为一股，\n水穿过整具鲸骨，流向外海。\n\n旅途至此告一段落。进度已保存，仍可回到鲸腹继续探索。"))
	action(column,"EndingTitle","返回首页",func() -> void:
		ui.history.clear()
		ui.open("title",false))
	action(column,"EndingStay","继续探索",ui.close_all)
