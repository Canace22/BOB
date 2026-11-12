class_name WhaleUIMap
extends Control
signal selected(index: int)
var data: WhaleUICampaignData
var nodes: Array[Dictionary] = []
var buttons: Dictionary = {}
var depths: Dictionary = {}
const ANATOMY_POSITIONS: Dictionary = {
	0:Vector2(.09,.70),1:Vector2(.29,.67),2:Vector2(.49,.70),
	3:Vector2(.69,.70),4:Vector2(.89,.70),5:Vector2(.62,.10),6:Vector2(.48,.36),
}
const HEAD: Texture2D = preload("res://art/xumen-continuity/r1-anatomy-overview.png")
const WHALE: Texture2D = preload("res://art/world-map/whale-anatomy-overview.png")
var anatomy: TextureRect
var page: String = "R1"

func _ready() -> void:
	# One page per region: its own rooms plus placed neighbours from linked regions.
	page = CampaignWorld.region(str(data.host.room.id))
	nodes=data.map_rooms().filter(func(room: Dictionary) -> bool: return CampaignWorld.on_map_page(page, str(room.id)))
	# The first region keeps its head close-up; later regions sit on the whole whale.
	anatomy = TextureRect.new()
	anatomy.name = "WhaleHeadAnatomy" if page == "R1" else "WhaleAnatomy"
	anatomy.texture = HEAD if page == "R1" else WHALE
	anatomy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	anatomy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	anatomy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anatomy.modulate = Color(.62,.71,.77,.38) if page == "R1" else Color(.74,.82,.86,.56)
	add_child(anatomy)
	anatomy.show_behind_parent = true
	var known: Dictionary={}
	for room: Dictionary in nodes: known[int(room.index)]=room
	if not nodes.is_empty():
		var start: int=int(nodes[0].index)
		depths[start]=0
		var pending: Array[int]=[start]
		while not pending.is_empty():
			var id: int=pending.pop_front()
			for door: Dictionary in known[id].doors:
				var target: int=int(door.to)
				if known.has(target) and not depths.has(target):
					depths[target]=int(depths[id])+1
					pending.append(target)
	for room: Dictionary in nodes:
		var id: int=int(room.index)
		var label: String=str(room.name)
		var button: Button=WhaleUIStyle.button(label,select_room.bind(id))
		button.name="Room_"+str(room.id)
		# Whale pages pack several rooms into one organ, so their nodes hug the name.
		button.custom_minimum_size=Vector2(140,48) if page == "R1" else Vector2(72,40)
		button.add_theme_font_size_override("font_size",14)
		if not room.visited and not room.next: button.modulate=Color(0.66,0.8,0.81)
		button.tooltip_text = str(room.route_kind) + (" · 未探索" if not room.visited else "")
		# Solid fill keeps names readable over the backdrop and hides links passing behind.
		button.add_theme_stylebox_override("normal",WhaleUIStyle.box(Color("0c2028"),Color("4c6b70")))
		if room.next: button.add_theme_stylebox_override("normal",WhaleUIStyle.box(Color("152f35"),WhaleUIStyle.TEAL))
		if room.current: button.add_theme_stylebox_override("normal",WhaleUIStyle.box(Color("263c3b"),WhaleUIStyle.AMBER))
		if room.visited and room.camp:
			button.icon = load("res://art/ui/shell.svg") as Texture2D
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width",24)
		add_child(button)
		buttons[id]=button
	resized.connect(_layout)
	_layout()

func select_room(index: int) -> void:
	selected.emit(index)

## Area the backdrop actually covers; room positions are fractions of it.
func frame() -> Rect2:
	var art: Vector2=anatomy.texture.get_size()
	var fit: Vector2=art*minf(size.x/art.x,size.y/art.y)
	return Rect2((size-fit)*.5,fit)

func _layout() -> void:
	anatomy.size=size
	var area: Rect2=frame()
	var wide: Vector2=Vector2(clampf(size.x*.155,90,155),48)
	for room: Dictionary in nodes:
		var id: int=int(room.index)
		var button: Button=buttons[id]
		if page == "R1": button.custom_minimum_size=wide
		button.size=button.get_combined_minimum_size()
		var placed: Variant=CampaignWorld.map_position(page,str(room.id))
		var normalized: Vector2=placed if placed != null else ANATOMY_POSITIONS.get(id,Vector2(.5,.5))
		button.position=area.position+normalized*area.size-button.size*.5
		button.position=button.position.clamp(Vector2.ZERO,(size-button.size).max(Vector2.ZERO))
	queue_redraw()

func _draw() -> void:
	for room: Dictionary in nodes:
		var id: int=int(room.index)
		if not buttons.has(id): continue
		for door: Dictionary in room.doors:
			var target: int=int(door.to)
			if target<=id or not buttons.has(target): continue
			var a: Button=buttons[id]
			var b: Button=buttons[target]
			var begin: Vector2=a.position+a.size*0.5
			var end: Vector2=b.position+b.size*0.5
			var visited: bool=room.visited and data.host.visited.get(str(data.host.rooms[target].id),false)
			var route:=PackedVector2Array([begin,end])
			var detour: bool=id==1 and target==5
			if detour:
				route=PackedVector2Array([begin,Vector2(begin.x*.72,size.y*.15),Vector2(end.x,size.y*.15),end])
			for segment:int in range(route.size()-1):
				if visited:draw_line(route[segment],route[segment+1],WhaleUIStyle.MUTED,1.5,true)
				else:draw_dashed_line(route[segment],route[segment+1],Color("587a80"),1.5,7,true)
			# Only reveal requirements authored on an explored side of this passage.
			var needs: Array[String] = CampaignWorld.requirements(door) if room.visited else ([] as Array[String])
			if needs.is_empty() and data.host.visited.get(str(data.host.rooms[target].id),false):
				for reverse: Dictionary in data.host.rooms[target].get("doors",[]):
					if int(reverse.to)==id: needs=CampaignWorld.requirements(reverse)
			if not needs.is_empty():
				var open: PackedVector2Array=span(a,b)
				var center: Vector2=(open[0]+open[1])*0.5 if open.size()==2 else (begin+end)*0.5
				if detour:center=Vector2(begin.x*.78,size.y*.35)
				_draw_requirement(center,CampaignWorld.requirement_label(needs))
	_draw_recommended_route()
	for room: Dictionary in nodes:
		if room.current and buttons.has(int(room.index)):
			var button: Button=buttons[int(room.index)]
			var center: Vector2=button.position+Vector2(button.size.x*0.5,-12)
			draw_colored_polygon(PackedVector2Array([center+Vector2(-7,-6),center+Vector2(7,-6),center+Vector2(0,5)]),WhaleUIStyle.AMBER)

## The label goes below the mark, or to the first side where no room node covers it.
func _draw_requirement(center: Vector2, label: String) -> void:
	var diamond: PackedVector2Array=PackedVector2Array([center+Vector2(0,-9),center+Vector2(9,0),center+Vector2(0,9),center+Vector2(-9,0),center+Vector2(0,-9)])
	draw_colored_polygon(diamond,WhaleUIStyle.INK)
	draw_polyline(diamond,WhaleUIStyle.AMBER,2,true)
	var width: float=WhaleUIStyle.FONT.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
	var below: Vector2=center+Vector2(-width*0.5,27)
	var at: Vector2=below
	for spot: Vector2 in [below,center+Vector2(16,5),center+Vector2(-width*0.5,-17),center+Vector2(-16-width,5)]:
		var text:=Rect2(spot-Vector2(0,14),Vector2(width,18))
		if not buttons.values().any(func(button: Button) -> bool: return button.get_rect().intersects(text)):
			at=spot
			break
	draw_string_outline(WhaleUIStyle.FONT,at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,4,WhaleUIStyle.INK)
	draw_string(WhaleUIStyle.FONT,at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,WhaleUIStyle.BONE)

## An arrow from the current room to the recommended neighbour stays readable
## even when both endpoints are covered by their clickable room labels.
func recommended_route() -> PackedVector2Array:
	var current := -1
	var next := -1
	for room: Dictionary in nodes:
		if room.current: current = int(room.index)
		if room.next: next = int(room.index)
	if not buttons.has(current) or not buttons.has(next): return PackedVector2Array()
	return span(buttons[current], buttons[next], 6.0)

## Uncovered part of the straight link between two nodes; empty when they touch.
func span(a: Button, b: Button, gap: float = 0.0) -> PackedVector2Array:
	var direction := ((b.position + b.size * 0.5) - (a.position + a.size * 0.5)).normalized()
	var from := _edge(a, direction, gap)
	var to := _edge(b, -direction, gap)
	return PackedVector2Array([from, to]) if (to - from).dot(direction) > 0.0 else PackedVector2Array()

func _edge(button: Button, direction: Vector2, gap: float) -> Vector2:
	var half := button.size * 0.5 + Vector2(gap,gap)
	var distance := minf(half.x / maxf(absf(direction.x),0.001), half.y / maxf(absf(direction.y),0.001))
	return button.position + button.size * 0.5 + direction * distance

func _draw_recommended_route() -> void:
	var route := recommended_route()
	if route.size() != 2: return
	var direction := (route[1] - route[0]).normalized()
	var side := direction.orthogonal()
	draw_line(route[0],route[1],WhaleUIStyle.INK,9,true)
	draw_line(route[0],route[1],WhaleUIStyle.AMBER,3,true)
	# A short gap only has room for the arrowhead at the target.
	var heads: Array[float] = [1.0]
	if route[0].distance_to(route[1]) > 40.0: heads.push_front(0.5)
	for ratio: float in heads:
		var tip: Vector2 = route[0].lerp(route[1],ratio)
		draw_colored_polygon(PackedVector2Array([tip,tip-direction*13+side*7,tip-direction*13-side*7]),WhaleUIStyle.AMBER)
