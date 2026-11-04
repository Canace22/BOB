class_name WhaleUIMap
extends Control
signal selected(index: int)
var data: WhaleUICampaignData
var nodes: Array[Dictionary] = []
var buttons: Dictionary = {}
var depths: Dictionary = {}

func _ready() -> void:
	nodes=data.map_rooms()
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
		elif not room.visited: label+="\n未探索"
		elif room.camp: label+="\n营地"
		var button: Button=WhaleUIStyle.button(label,select_room.bind(id))
		button.name="Room_"+str(room.id)
		button.custom_minimum_size=Vector2(140,64)
		button.add_theme_font_size_override("font_size",16)
		if not room.visited: button.modulate=Color(0.66,0.8,0.81)
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
	var max_depth: int=0
	for value: int in depths.values(): max_depth=maxi(max_depth,value)
	var columns: Dictionary={}
	for room: Dictionary in nodes:
		var id: int=int(room.index)
		var depth: int=int(depths.get(id,max_depth))
		if not columns.has(depth): columns[depth]=[]
		columns[depth].append(id)
	var width: float=minf(180,(size.x-50)/maxi(1,max_depth+1)-20)
	var spacing: float=minf(230,(size.x-width-50)/maxi(1,max_depth))
	var origin: float=(size.x-width-max_depth*spacing)*0.5
	for depth: int in columns:
		var ids: Array=columns[depth]
		for row: int in range(ids.size()):
			var button: Button=buttons[ids[row]]
			button.custom_minimum_size.x=width
			button.size=Vector2(width,64)
			button.position=Vector2(origin+depth*spacing,size.y*(row+1)/float(ids.size()+1)-32)
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
			if visited: draw_line(begin,end,WhaleUIStyle.MUTED,1.5,true)
			else: draw_dashed_line(begin,end,Color("587a80"),1.5,7,true)
			# Only reveal requirements authored on an explored side of this passage.
			var requirement: String = str(door.get("ability","")) if room.visited else ""
			if requirement.is_empty() and data.host.visited.get(str(data.host.rooms[target].id),false):
				for reverse: Dictionary in data.host.rooms[target].get("doors",[]):
					if int(reverse.to)==id: requirement=str(reverse.get("ability",""))
			if not requirement.is_empty():
				var center: Vector2=(begin+end)*0.5
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
