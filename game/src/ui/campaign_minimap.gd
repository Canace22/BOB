class_name WhaleCampaignMinimap
extends Control
## 当前房间的等比路线图；直接投影运行中的平台、玩家与出口，不使用拓扑格子。
var data: WhaleUICampaignData
var exits: Array[Dictionary] = []
var room_size := Vector2.ONE
var plot := Rect2()
var scale_factor: float = 1.0
var signature: int = 0
var refresh_left: float = 0.0
var shell: Texture2D
var high_contrast: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell = load("res://art/ui/shell.svg") as Texture2D
	resized.connect(refresh)

func _process(dt: float) -> void:
	if data == null or data.host.room.is_empty(): return
	_update_clearance(dt)
	refresh_left -= dt
	if refresh_left <= 0.0:
		refresh_left = 0.2
		var next_signature: int = hash([data.host.room.id, data.host.abilities, data.host.defeated])
		if next_signature != signature:
			signature = next_signature
			refresh()
	queue_redraw()

func _update_clearance(dt: float) -> void:
	var alpha: float = 1.0
	if is_instance_valid(data.host.player):
		var feet: Vector2 = get_global_transform_with_canvas().affine_inverse() * data.host.player.get_global_transform_with_canvas().origin
		var silhouette := Rect2(feet-Vector2(54,138),Vector2(108,156))
		if Rect2(Vector2.ZERO,size).grow(24).intersects(silhouette): alpha = 0.08
	modulate.a = move_toward(modulate.a,alpha,dt*8.0)

func refresh() -> void:
	if data == null or data.host.room.is_empty(): return
	room_size = data.host.point(data.host.room.size).max(Vector2.ONE)
	var available := Vector2(maxf(1,size.x-32),100)
	scale_factor = minf(available.x/room_size.x,available.y/room_size.y)
	plot = Rect2(Vector2((size.x-room_size.x*scale_factor)*0.5,42),room_size*scale_factor)
	exits.clear()
	for door: Dictionary in data.host.room.get("doors", []):
		var target: int = int(door.to)
		var label: String = str(data.host.rooms[target].name) if target >= 0 and target < data.host.rooms.size() else ("归海" if target == -1 else "未开放")
		exits.append({"number":exits.size()+1,"point":data.host.point(door.pos),"label":label,
			"blocked":_blocked(str(data.host.room.id),door),"target":target})
	queue_redraw()

func project(point: Vector2) -> Vector2:
	return plot.position + point * scale_factor

func player_point() -> Vector2:
	# 跨房时转换到当前场景坐标，连接段上的位置在绘制时收在图边。
	return data.host.scenery.to_local(data.host.player.global_position)

func _draw() -> void:
	if data == null or data.host.room.is_empty(): return
	draw_style_box(WhaleUIStyle.surface(high_contrast),Rect2(Vector2.ZERO,size))
	_label(Vector2(14,25),str(data.host.room.name),17,WhaleUIStyle.BONE)
	_label(Vector2(size.x-73,25),WhaleUIStyle.key("ui_region_map")+" 地图",15,WhaleUIStyle.MUTED)
	draw_rect(plot,Color(0.1,0.2,0.23,0.25))
	for surface: Array in data.host.room.get("surfaces", []):
		var points := PackedVector2Array()
		for point: Array in surface: points.append(project(data.host.point(point)))
		if points.size()>1: draw_polyline(points,Color("78918f"),1.2,true)
	var camp: Array = data.camp_position()
	if camp.size()==2 and shell != null:
		draw_texture_rect(shell,Rect2(project(data.host.point(camp))-Vector2(6,10),Vector2(12,12)),false,WhaleUIStyle.TEAL)
	for exit: Dictionary in exits: _draw_exit(exit)
	if is_instance_valid(data.host.player):
		var point: Vector2 = project(player_point().clamp(Vector2.ZERO,room_size))
		draw_circle(point,5.5,WhaleUIStyle.INK)
		draw_colored_polygon(PackedVector2Array([point+Vector2(0,-5),point+Vector2(4,0),point+Vector2(0,5),point+Vector2(-4,0)]),WhaleUIStyle.BONE)

func _draw_exit(exit: Dictionary) -> void:
	var color: Color = WhaleUIStyle.AMBER if exit.blocked else WhaleUIStyle.TEAL
	var at: Vector2 = project(exit.point)
	draw_circle(at,8,WhaleUIStyle.INK)
	draw_arc(at,8,0,TAU,20,color,1.5,true)
	_label(at+Vector2(-4,5),str(exit.number),13,color)
	var column: int = (int(exit.number)-1)%2
	var row: int = (int(exit.number)-1)/2
	var label: String = "%d %s%s" % [exit.number,exit.label," ×" if exit.blocked else ""]
	_label(Vector2(14+column*(size.x-24)*0.5,168+row*22),label,14,color)
	if exit.blocked:
		draw_line(at+Vector2(8,-7),at+Vector2(12,-3),color,2,true)
		draw_line(at+Vector2(8,-3),at+Vector2(12,-7),color,2,true)

func _blocked(source_id: String, door: Dictionary) -> bool:
	for need: String in CampaignWorld.requirements(door):
		if need == "boss":
			if not data.host.defeated.get(source_id+":0",false): return true
		elif not data.host.has_ability(need): return true
	return int(door.get("to",-2)) == -2 or (door.has("locked") and not data.host.has_ability(str(door.locked)))

func _label(at: Vector2, value: String, font_size: int, color: Color) -> void:
	draw_string_outline(WhaleUIStyle.FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,3,WhaleUIStyle.INK)
	draw_string(WhaleUIStyle.FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
