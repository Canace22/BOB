class_name WhaleUICampPage
extends RefCounted
## Rest has already happened in the campaign; these pages only read its result.

static func column(ui: WhaleCampaignUI) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.add_theme_constant_override("separation", 10)
	ui.body.add_child(result)
	return result

static func build(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "壳巢歇息"
	var content: VBoxContainer = column(ui)
	content.add_child(WhaleUIStyle.label(str(ui.host.room.name), 18, WhaleUIStyle.MUTED))
	content.add_child(WhaleUIStyle.icon("shell", Vector2(68, 68)))
	content.add_child(WhaleUIStyle.label("在旧壳中，让潮声平息。", 22))
	var capacity: int = CampaignRelics.capacity(ui.host.collected)
	content.add_child(WhaleUIStyle.label("生命与护盾已恢复" if capacity > 0 else "生命已恢复", 18, WhaleUIStyle.TEAL))
	var saved: bool = ui.host.last_save_ok
	content.add_child(WhaleUIStyle.paragraph("检查点已记录" if saved else "进度写入失败，请检查存储空间。", WhaleUIStyle.MUTED if saved else WhaleUIStyle.AMBER))
	WhaleUIPages.action(content, "LeaveCamp", "继续旅途", ui.close_all)
	var details_button: Button = WhaleUIPages.action(content, "CampDetails", "休息详情", func() -> void: ui.open("camp_details"))
	details_button.custom_minimum_size.y = 36
	details_button.flat = true
	details_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ui.footer.text = "Tab 选择 · Enter 确认 · Esc 离开"

static func details(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "休息详情"
	var content: VBoxContainer = column(ui)
	var capacity: int = CampaignRelics.capacity(ui.host.collected)
	var values: String = "生命 %d / %d" % [ui.player.health, ui.player.max_health]
	if capacity > 0: values += "     护盾 %d / %d" % [ui.host.relics.charges, capacity]
	content.add_child(WhaleUIStyle.label(values, 20, WhaleUIStyle.TEAL))
	content.add_child(WhaleUIStyle.paragraph("蓄振 %d / %d · 通过战斗获得" % [ui.player.soul, ui.player.max_soul]))
	content.add_child(WhaleUIStyle.paragraph("营地恢复生命与护盾，并记录检查点。\n休息不会恢复蓄振。"))
	if capacity > 0:
		content.add_child(WhaleUIStyle.paragraph("自动抵挡等量伤害；营地、重试与续档补满。\n跌落不受护盾保护。"))
		for id: String in CampaignRelics.ITEMS:
			if ui.host.collected.get(id, false):
				content.add_child(WhaleUIStyle.paragraph(CampaignRelics.description(id).get_slice("\n", 0)))
	WhaleUIPages.action(content, "CampDetailsBack", "返回歇息", ui.back)
	ui.footer.text = "Enter / Esc 返回歇息"
