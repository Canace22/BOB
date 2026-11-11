class_name WhaleUIMapPage
extends RefCounted
## Keep navigation visible; memories are opt-in reading.

static func build(ui: WhaleCampaignUI) -> void:
	ui.heading.text = "须门遗港"
	var guidance := WhaleUIStyle.label(short_hint(ui.host),20,WhaleUIStyle.AMBER)
	guidance.name = "MapGuidance"
	ui.body.add_child(guidance)
	var map := WhaleUIMap.new()
	map.name = "RouteMap"
	map.data = ui.data
	map.custom_minimum_size = Vector2(0,280)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.body.add_child(map)
	var detail := WhaleUIStyle.label("",16,WhaleUIStyle.MUTED)
	detail.name = "MapDetail"
	ui.body.add_child(detail)
	var memory := WhaleUIStyle.paragraph(WhaleUICampaignData.MEMORY_TEXT)
	memory.name = "MapMemory"
	memory.hide()
	ui.body.add_child(memory)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",18)
	ui.body.add_child(row)
	var read := WhaleUIStyle.button("查看记忆",func() -> void: pass)
	read.name = "ReadMemory"
	read.custom_minimum_size = Vector2(150,40)
	read.pressed.connect(func() -> void:
		memory.visible = not memory.visible
		read.text = "收起记忆" if memory.visible else "查看记忆")
	row.add_child(read)
	var back := WhaleUIStyle.button("返回",ui.back)
	back.name = "Back"
	back.custom_minimum_size = Vector2(150,40)
	row.add_child(back)
	map.selected.connect(func(index: int) -> void:
		var id: String = str(ui.host.rooms[index].id)
		detail.text = short_detail(ui.host,id)
		memory.hide()
		read.text = "查看记忆"
		read.visible = id == "R1-07" and ui.host.collected.get(id,false))
	map.select_room(ui.host.room_index)
	ui.footer.text = "Esc 返回"

static func short_hint(host: Node2D) -> String:
	var target := CampaignGuidance.next_room(host)
	if not target.is_empty():
		for room: Dictionary in host.rooms:
			if str(room.id) == target:
				return ("返回" if str(host.room.id) in ["R1-06","R1-07"] else "前往") + str(room.name)
	if host.completed: return "首关完成"
	match str(host.room.id):
		"R1-07": return "拾取浮游"
		"R1-04": return "击败守卫"
		"R1-05": return "前往右侧出口"
	return "继续探索"

static func short_detail(host: Node2D, id: String) -> String:
	if CampaignRelics.ITEMS.has(id):
		var item: Dictionary = CampaignRelics.ITEMS[id]
		return ("已获得：" if host.collected.get(id,false) else "右上方收集：") + str(item.name) + " · 护盾上限 +%d" % item.charges + (" · 需浮游" if id == "R1-06" and not host.has_ability("float") else "")
	match id:
		"R1-07": return "浮游已获得" if host.collected.get(id,false) else "支路 · 浮游"
		"R1-06": return "支路 · 需浮游" if not host.has_ability("float") else "支路 · 原路返回"
	return ""

static func snapshot(ui: WhaleCampaignUI) -> Dictionary:
	if ui.page_id != "map": return {}
	var map := ui.body.find_child("RouteMap",true,false) as WhaleUIMap
	var memory := ui.body.find_child("MapMemory",true,false) as Label
	var guidance := ui.body.find_child("MapGuidance",true,false) as Label
	var detail := ui.body.find_child("MapDetail",true,false) as Label
	if map == null or memory == null or guidance == null: return {}
	var scroll := ui.body.get_parent() as ScrollContainer
	return {"hint":guidance.text,"detail":detail.text,"memory_visible":memory.visible,
		"route_points":map.recommended_route().size(),
		"needs_scroll":scroll.get_v_scroll_bar().visible}
