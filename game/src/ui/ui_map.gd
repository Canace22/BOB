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
var anatomy: TextureRect

func _ready() -> void:
	nodes=data.map_rooms()
	anatomy = TextureRect.new()
	anatomy.name = "WhaleHeadAnatomy"
	anatomy.texture = preload("res://art/xumen-continuity/r1-anatomy-overview.png")
	anatomy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	anatomy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	anatomy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anatomy.modulate = Color(.62,.71,.77,.38)
	add_child(anatomy)
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
		if room.current: label="所在 · "+label
		label += "\n" + ("下一步 · " if room.next else "") + str(room.route_kind)
		if not room.visited: label += "\n未探索"
		var button: Button=WhaleUIStyle.button(label,select_room.bind(id))
		button.name="Room_"+str(room.id)
		button.custom_minimum_size=Vector2(140,76)
		button.add_theme_font_size_override("font_size",14)
		if not room.visited: button.modulate=Color(0.66,0.8,0.81)
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

func _layout() -> void:
	if is_instance_valid(anatomy): anatomy.size=size
	var width: float=clampf(size.x*.155,90,155)
	for room: Dictionary in nodes:
		var id: int=int(room.index)
		var button: Button=buttons[id]
		button.custom_minimum_size=Vector2(width,76)
		button.size=Vector2(width,76)
		var normalized: Vector2=ANATOMY_POSITIONS.get(id,Vector2(.5,.5))
		button.position=normalized*size-button.size*.5
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
			if id==1 and target==5:
				route=PackedVector2Array([begin,Vector2(begin.x*.72,size.y*.15),Vector2(end.x,size.y*.15),end])
			for segment:int in range(route.size()-1):
				if visited:draw_line(route[segment],route[segment+1],WhaleUIStyle.MUTED,1.5,true)
				else:draw_dashed_line(route[segment],route[segment+1],Color("587a80"),1.5,7,true)
			# Only reveal requirements authored on an explored side of this passage.
			var requirement: String = str(door.get("ability","")) if room.visited else ""
			if requirement.is_empty() and data.host.visited.get(str(data.host.rooms[target].id),false):
				for reverse: Dictionary in data.host.rooms[target].get("doors",[]):
					if int(reverse.to)==id: requirement=str(reverse.get("ability",""))
			if not requirement.is_empty():
				var center: Vector2=(begin+end)*0.5
				if id==1 and target==5:center=Vector2(begin.x*.78,size.y*.35)
				var diamond: PackedVector2Array=PackedVector2Array([center+Vector2(0,-9),center+Vector2(9,0),center+Vector2(0,9),center+Vector2(-9,0),center+Vector2(0,-9)])
				draw_colored_polygon(diamond,WhaleUIStyle.INK)
				draw_polyline(diamond,WhaleUIStyle.AMBER,2,true)
				var label: String=WhaleUICampaignData.ability_name(requirement)
				var width: float=WhaleUIStyle.FONT.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
				draw_string(WhaleUIStyle.FONT,center+Vector2(-width*0.5,27),label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,WhaleUIStyle.BONE)
	for room: Dictionary in nodes:
		if room.current and buttons.has(int(room.index)):
			var button: Button=buttons[int(room.index)]
			var center: Vector2=button.position+Vector2(button.size.x*0.5,-12)
			draw_colored_polygon(PackedVector2Array([center+Vector2(-7,-6),center+Vector2(7,-6),center+Vector2(0,5)]),WhaleUIStyle.AMBER)
