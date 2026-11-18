class_name CampaignPaintedSupports
extends RefCounted
## 母版补绘形成的新岸台，使用同一顶线建立碰撞和地面查询，不改原房配方。
const DATA := "res://content/whalebelly/layout/painted_supports.json"
const DEPTH := 24.0

static func attach_data(rooms: Array) -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var records: Dictionary=data.rooms
	for room: Dictionary in rooms:
		if records.has(str(room.id)): room["painted_supports"]=records[str(room.id)].duplicate(true)
		var profiles: Array=[]
		var replaced: Array=[]
		for id: String in data.get("corridors",{}):
			if id.get_slice("--",0)!=str(room.id): continue
			profiles.append_array(data.corridors[id].tops.duplicate(true))
			replaced.append_array(data.corridors[id].replace.duplicate(true))
		if not profiles.is_empty():
			room["painted_corridors"]=profiles
			room["painted_corridor_replacements"]=replaced

static func restore_corridor_point(room: Dictionary, value: Vector2) -> Vector2:
	for coordinate: Array in room.get("painted_corridor_replacements",[]):
		if absf(value.x-float(coordinate[0]))>64 or absf(value.y-float(coordinate[1]))>24: continue
		var y: float=ground_y({"painted_corridors":room.get("painted_corridors",[])},value.x,value.y,INF,150)
		if is_finite(y): return Vector2(value.x,y)
	return Vector2.INF

static func corridor_data(layout: Dictionary, link: Dictionary) -> Dictionary:
	var id: String=str(layout.rooms[int(link.a)].id)+"--"+str(layout.rooms[int(link.b)].id)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DATA))
	return data.get("corridors",{}).get(id,{})

static func replaces(data: Dictionary, local: Vector2) -> bool:
	for point: Array in data.get("replace",[]):
		if local.distance_to(Vector2(point[0],point[1]))<0.1: return true
	return false

static func add_body(parent: Node, points: Array, offset: Vector2, name_text: String) -> void:
	var top: PackedVector2Array=[]
	for coordinate: Array in points: top.append(offset+Vector2(coordinate[0],coordinate[1]))
	var polygon: PackedVector2Array=top.duplicate()
	for i: int in range(top.size()-1,-1,-1): polygon.append(top[i]+Vector2(0,DEPTH))
	var body:=StaticBody2D.new()
	body.name=name_text
	body.collision_layer=1
	body.collision_mask=2
	var shape:=CollisionPolygon2D.new()
	shape.polygon=polygon
	shape.one_way_collision=true
	shape.one_way_collision_margin=6.0
	body.add_child(shape)
	parent.add_child(body)

static func prepare_scene(scene: Node2D, room: Dictionary) -> void:
	var terrain: Node=scene.get_node_or_null("World/Terrain")
	if terrain==null: return
	var profiles: Array=room.get("painted_supports",[])
	for index: int in profiles.size():
		var name_text: String="PaintedSupport"+str(index)
		if terrain.has_node(name_text): continue
		add_body(terrain,profiles[index],Vector2.ZERO,name_text)

static func ground_y(room: Dictionary, x: float, near_y: float, best: float, distance: float) -> float:
	var profiles: Array=room.get("painted_supports",[])+room.get("painted_corridors",[])
	for surface: Array in profiles:
		for i: int in range(1,surface.size()):
			var a:=Vector2(surface[i-1][0],surface[i-1][1])
			var b:=Vector2(surface[i][0],surface[i][1])
			if x<a.x or x>b.x or is_equal_approx(a.x,b.x): continue
			var y: float=lerpf(a.y,b.y,(x-a.x)/(b.x-a.x))
			if absf(y-near_y)<distance:
				best=y
				distance=absf(y-near_y)
	return best
