class_name WhaleUIMapPage
extends RefCounted

static func build(ui: WhaleCampaignUI) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 22)
	ui.body.add_child(header)
	header.add_child(WhaleUIStyle.label("鲸腹地图", 32))
	var count := WhaleUIStyle.label("", 16, WhaleUIStyle.MUTED)
	count.name = "MapCount"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(count)
	var back := WhaleUIStyle.button("Esc  返回", ui.back)
	back.name = "Back"
	header.add_child(back)
	WhaleUIStyle.compact_button(back)
	back.custom_minimum_size = Vector2(102,36)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	ui.body.add_child(tabs)
	var map := WhaleUIMap.new()
	map.name = "RouteMap"
	map.data = ui.data
	map.custom_minimum_size.y = 310
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui.body.add_child(map)
	ui.focus_history["map"] = "Room_" + str(ui.host.room.id)
	build_tabs(tabs, map, count)
	var key_hint := WhaleUIStyle.label("Tab  选点", 15, WhaleUIStyle.MUTED)
	key_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tabs.add_child(key_hint)

	var rule := ColorRect.new()
	rule.color = Color("355052")
	rule.custom_minimum_size.y = 1
	ui.body.add_child(rule)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	ui.body.add_child(row)
	var info := VBoxContainer.new()
	info.custom_minimum_size.y = 68
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	var guidance := WhaleUIStyle.label(short_hint(ui.host), 22, WhaleMapMarker.PAPER)
	guidance.name = "MapGuidance"
	guidance.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(guidance)
	var detail := WhaleUIStyle.paragraph("", WhaleUIStyle.MUTED)
	detail.name = "MapDetail"
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(detail)

	var read := Button.new()
	read.name = "ReadMemory"
	read.text = "查看记忆"
	read.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(read)
	_add_legend(row, WhaleMapMarker.Kind.CURRENT, "当前位置")
	_add_legend(row, WhaleMapMarker.Kind.VISITED, "已到达")
	_add_legend(row, WhaleMapMarker.Kind.UNKNOWN, "未到达")
	var memory := WhaleUIStyle.paragraph(WhaleUICampaignData.MEMORY_TEXT)
	memory.name = "MapMemory"
	memory.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	memory.hide()
	ui.body.add_child(memory)
	read.pressed.connect(func() -> void:
		memory.visible = not memory.visible
		read.text = "收起记忆" if memory.visible else "查看记忆")
	map.selected.connect(func(index: int, show_exits: bool) -> void:
		var room := map.rooms[index]
		guidance.text = short_hint(ui.host) if room.current else CampaignWorld.region_name(room.id) + " · " + WhaleUICampaignData.visit_label(room)
		guidance.add_theme_color_override("font_color", WhaleMapMarker.PAPER if room.current else WhaleUIStyle.BONE)
		detail.text = room_detail(map, index, show_exits)
		detail.visible = not detail.text.is_empty()
		memory.hide()
		read.text = "查看记忆"
		read.visible = room.id == "R1-07" and ui.host.collected.get(room.id,false))
	map.select_room(ui.host.room_index)

static func _add_legend(row: HBoxContainer, kind: WhaleMapMarker.Kind, title: String) -> void:
	var group := HBoxContainer.new()
	group.add_theme_constant_override("separation", 5)
	row.add_child(group)
	var symbol := Control.new()
	symbol.custom_minimum_size.x = 24
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(symbol)
	symbol.draw.connect(func() -> void: WhaleMapMarker.draw_symbol(symbol, symbol.size * 0.5, kind, 0.72))
	group.add_child(WhaleUIStyle.label(title, 15, WhaleUIStyle.MUTED))

static func build_tabs(tabs: HBoxContainer, map: WhaleUIMap, count: Label) -> void:
	var group := ButtonGroup.new()
	for region: String in ["world"] + CampaignWorld.REGIONS.keys():
		var total := 0
		var visited := 0
		for room: Dictionary in map.rooms:
			if region != "world" and CampaignWorld.region(str(room.id)) != region: continue
			total += 1
			if room.visited: visited += 1
		if total == 0: continue
		var progress := "已到达  %d/%d" % [visited,total]
		var title := "全图" if region == "world" else CampaignWorld.region_name(region)
		var tab := WhaleUIStyle.button(title, func() -> void:
			map.show_page(region)
			count.text = progress)
		tab.name = "Map_" + region
		tab.accessibility_description = progress
		tab.toggle_mode = true
		tab.button_group = group
		tab.button_pressed = region == map.page
		if tab.button_pressed: count.text = progress
		tabs.add_child(tab)
		tab.custom_minimum_size = Vector2(72, 38)
		for state: String in ["normal","hover","pressed","hover_pressed","focus"]:
			var style := WhaleUIStyle.box(Color.TRANSPARENT)
			style.set_content_margin_all(8)
			style.content_margin_left = 13
			style.content_margin_right = 13
			style.set_border_width_all(0)
			if state in ["pressed","hover_pressed","focus"]:
				style.border_width_bottom = 2
				style.border_color = WhaleMapMarker.PAPER if state != "focus" else WhaleUIStyle.BONE
			if state in ["hover","hover_pressed"]: style.bg_color = Color("1a3034")
			tab.add_theme_stylebox_override(state,style)
		tab.add_theme_color_override("font_color",WhaleUIStyle.MUTED)
		tab.add_theme_color_override("font_pressed_color",WhaleMapMarker.PAPER)

static func room_detail(map: WhaleUIMap, index: int, show_exits: bool = true) -> String:
	var room := map.rooms[index]
	var info := short_detail(map.data.host, room.id)
	if not info.is_empty(): return info
	var facts := PackedStringArray()
	for title: String in room.objectives:
		facts.append(title + str(room.objectives[title]))
	if not facts.is_empty(): return " · ".join(facts)
	if room.current and not show_exits: return ""
	var exits := PackedStringArray()
	for door: Dictionary in room.doors:
		var target := int(door.to)
		if target >= 0 and target < map.rooms.size(): exits.append(str(map.rooms[target].name))
	return "通往" + "、".join(exits) if not exits.is_empty() else ""

static func short_hint(host: Node2D) -> String:
	var target := CampaignGuidance.next_room(host)
	if not target.is_empty():
		for room: Dictionary in host.rooms:
			if str(room.id) == target:
				return ("返回" if str(host.room.id) in ["R1-06","R1-07"] else "前往") + str(room.name)
	if host.completed or CampaignWorld.region(str(host.room.id)) != "R1": return CampaignGuidance.objective(host)
	match str(host.room.id):
		"R1-07": return "拾取浮游"
		"R1-04": return "击败守卫"
		"R1-05": return "前往右侧出口"
	return "继续探索"

static func short_detail(host: Node2D, id: String) -> String:
	if CampaignRelics.ITEMS.has(id):
		var item: Dictionary = CampaignRelics.ITEMS[id]
		var route := ""
		if id == "R1-06":
			route = " · 先去记忆袋获得浮游" if not host.has_ability("float") else " · 左右交替浮游上行 · 原路返回"
		return ("已获得：" if host.collected.get(id,false) else "右上方收集：") + str(item.name) + " · 护盾上限 +%d" % int(item.charges) + route
	match id:
		"R1-07": return "浮游已获得" if host.collected.get(id,false) else "支路 · 浮游待领取"
		"R1-06": return "支路 · 先去记忆袋获得浮游" if not host.has_ability("float") else "支路 · 左右交替浮游上行 · 原路返回"
	return ""

static func snapshot(ui: WhaleCampaignUI) -> Dictionary:
	if ui.page_id != "map": return {}
	var map := ui.body.find_child("RouteMap",true,false) as WhaleUIMap
	var memory := ui.body.find_child("MapMemory",true,false) as Label
	var detail := ui.body.find_child("MapDetail",true,false) as Label
	if map == null or memory == null: return {}
	var scroll := ui.body.get_parent() as ScrollContainer
	return {"hint":short_hint(ui.host),"detail":detail.text if detail else "","memory_visible":memory.visible,
		"route_points":map.recommended_route().size(),
		"needs_scroll":scroll.get_v_scroll_bar().visible}
