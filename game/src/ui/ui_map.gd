class_name WhaleUIMap
extends Control

signal selected(index: int, show_exits: bool)
const HEAD: Texture2D = preload("res://art/xumen-continuity/r1-anatomy-overview.png")
const WHALE: Texture2D = preload("res://art/world-map/whale-anatomy-overview.png")
var data: WhaleUICampaignData
var nodes: Array[Dictionary] = []
var buttons: Dictionary[int, WhaleMapMarker] = {}
var rooms: Array[Dictionary] = []
var anatomy: TextureRect
var caption: Label
var inspected: int = -1
var page: String = "world"

func _ready() -> void:
	rooms = data.map_rooms()
	anatomy = TextureRect.new()
	anatomy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	anatomy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	anatomy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anatomy.show_behind_parent = true
	add_child(anatomy)
	caption = WhaleUIStyle.label("", 17)
	var plate := WhaleUIStyle.box(Color("0b202b"), Color("749691"))
	plate.set_corner_radius_all(4)
	plate.set_content_margin_all(4)
	plate.content_margin_left = 10
	plate.content_margin_right = 10
	caption.add_theme_stylebox_override("normal", plate)
	caption.z_index = 1
	add_child(caption)
	resized.connect(_layout)
	show_page(page)

func show_page(region: String) -> void:
	page = region
	inspected = -1
	caption.hide()
	for button: WhaleMapMarker in buttons.values():
		remove_child(button)
		button.queue_free()
	buttons.clear()
	nodes = rooms.filter(func(room: Dictionary) -> bool: return CampaignWorld.on_map_page(page, str(room.id)))
	anatomy.texture = HEAD if page == "R1" else WHALE
	anatomy.modulate = Color(0.82,0.88,0.90,0.84) if page == "R1" else Color(1,1,1,0.92)
	var first := -1
	for room: Dictionary in nodes:
		var index := int(room.index)
		var button := WhaleMapMarker.new()
		button.configure(room, page != "world")
		button.focus_entered.connect(select_room.bind(index))
		button.mouse_entered.connect(select_room.bind(index))
		button.pressed.connect(select_room.bind(index, true))
		add_child(button)
		buttons[index] = button
		if first < 0 and CampaignWorld.region(str(room.id)) == region: first = index
	_layout()
	if buttons.has(data.host.room_index): select_room(data.host.room_index)
	elif first >= 0: select_room(first)

func select_room(index: int, show_exits: bool = false) -> void:
	if not buttons.has(index): return
	if buttons.has(inspected):
		buttons[inspected].inspected = false
		buttons[inspected].queue_redraw()
	inspected = index
	var marker := buttons[index]
	marker.inspected = true
	marker.queue_redraw()
	caption.text = str(rooms[index].name)
	caption.add_theme_color_override("font_color", WhaleMapMarker.PAPER if rooms[index].current else WhaleUIStyle.BONE)
	caption.show()
	_place_caption()
	queue_redraw()
	selected.emit(index, show_exits)

func frame() -> Rect2:
	var art := anatomy.texture.get_size()
	var fit := art * minf(size.x / art.x, size.y / art.y)
	return Rect2((size-fit)*0.5, fit)

func _layout() -> void:
	anatomy.size = size
	var area := frame()
	for room: Dictionary in nodes:
		var button := buttons[int(room.index)]
		button.size = button.get_combined_minimum_size()
		var spot: Vector2 = CampaignWorld.map_position(page, room.id)
		button.position = area.position + spot * area.size - button.size * 0.5
	_place_caption()
	queue_redraw()

func _place_caption() -> void:
	if not buttons.has(inspected): return
	var center := buttons[inspected].get_rect().get_center()
	caption.size = caption.get_combined_minimum_size()
	var half := caption.size * 0.5
	var dx := 24 + half.x
	var dy := 24 + half.y
	var offsets := [Vector2(0,dy), Vector2(0,-dy), Vector2(dx,0), Vector2(-dx,0),
		Vector2(dx,dy), Vector2(-dx,dy), Vector2(dx,-dy), Vector2(-dx,-dy)]
	var route := recommended_route()
	var best := INF
	for offset: Vector2 in offsets:
		var at := (center + offset - half).clamp(Vector2.ZERO, (size-caption.size).max(Vector2.ZERO))
		var box := Rect2(at, caption.size)
		# Prioritize keeping markers visible, then the arrow, then proximity.
		var penalty := 0
		for marker: WhaleMapMarker in buttons.values():
			if marker.get_rect().intersects(box): penalty += 10
		for i: int in range(route.size()-1):
			if Rect2(route[i],Vector2.ZERO).expand(route[i+1]).grow(6).intersects(box): penalty += 1
		if penalty < best:
			best = penalty
			caption.position = at
		if penalty == 0: break

func _link(from: int, to: int) -> PackedVector2Array:
	var a := buttons[from].get_rect().get_center()
	var b := buttons[to].get_rect().get_center()
	if page == "R1" and rooms[from].id == "R1-06" and rooms[to].id == "R1-02":
		var reverse := _link(to, from)
		reverse.reverse()
		return reverse
	if page == "R1" and rooms[from].id == "R1-02" and rooms[to].id == "R1-06":
		var top := frame().position.y + frame().size.y * 0.15
		return PackedVector2Array([a, Vector2(a.x-30,top), Vector2(b.x,top), b])
	return PackedVector2Array([a,b])

func recommended_route() -> PackedVector2Array:
	var current: int = data.host.room_index
	if not buttons.has(current): return PackedVector2Array()
	for room: Dictionary in nodes:
		if room.next:
			var route := _link(current, int(room.index))
			route[0] += route[0].direction_to(route[1]) * 18
			route[-1] += route[-1].direction_to(route[-2]) * 11
			return route
	return PackedVector2Array()

func _draw() -> void:
	for room: Dictionary in nodes:
		var index := int(room.index)
		for door: Dictionary in room.doors:
			var target := int(door.to)
			if target <= index or not buttons.has(target): continue
			var route := _link(index, target)
			var visited: bool = room.visited and rooms[target].visited
			draw_polyline(route, Color("07151de0"), 4.5, true)
			if visited:
				draw_polyline(route, WhaleMapMarker.SEA, 2, true)
			else:
				for i: int in range(route.size()-1):
					draw_dashed_line(route[i], route[i+1], Color("b1c9cbd0"), 1.7, 6, true)
			if page != "world" and (inspected == index or inspected == target):
				_draw_gate(room, door, target, route)
	var route := recommended_route()
	if route.is_empty(): return
	draw_polyline(route, WhaleUIStyle.INK, 7, true)
	draw_polyline(route, WhaleMapMarker.PAPER, 3, true)
	var tip := route[-1]
	var direction := route[-2].direction_to(tip)
	var side := direction.orthogonal() * 5
	draw_colored_polygon(PackedVector2Array([tip,tip-direction*11+side,tip-direction*11-side]), WhaleMapMarker.PAPER)

func _draw_gate(room: Dictionary, door: Dictionary, target: int, route: PackedVector2Array) -> void:
	var needs: Array[String] = []
	if room.visited: needs = CampaignWorld.requirements(door)
	if needs.is_empty() and rooms[target].visited:
		for reverse: Dictionary in rooms[target].doors:
			if int(reverse.to) == int(room.index): needs = CampaignWorld.requirements(reverse)
	if needs.is_empty(): return
	var at := route[0].lerp(route[1], 0.5)
	var label := CampaignWorld.requirement_label(needs)
	var width := WhaleUIStyle.FONT.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
	at.x = clampf(at.x - width * 0.5, 2, size.x-width-2)
	at.y -= 6
	draw_string_outline(WhaleUIStyle.FONT,at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,15,5,WhaleUIStyle.INK)
	draw_string(WhaleUIStyle.FONT,at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,15,WhaleMapMarker.PAPER)
