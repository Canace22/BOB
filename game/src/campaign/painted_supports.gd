class_name CampaignPaintedSupports
extends RefCounted
## 母版补绘形成的新岸台，使用同一顶线建立碰撞和地面查询，不改原房配方。
const DATA := "res://content/whalebelly/layout/painted_supports.json"
const DEPTH := 24.0

static func attach_data(rooms: Array) -> void:
	var records: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DATA)).rooms
	for room: Dictionary in rooms:
		if records.has(str(room.id)): room["painted_supports"]=records[str(room.id)].duplicate(true)

static func prepare_scene(scene: Node2D, room: Dictionary) -> void:
	var terrain: Node=scene.get_node_or_null("World/Terrain")
	if terrain==null: return
	var profiles: Array=room.get("painted_supports",[])
	for index: int in profiles.size():
		var name_text: String="PaintedSupport"+str(index)
		if terrain.has_node(name_text): continue
		var top: PackedVector2Array=[]
		for coordinate: Array in profiles[index]: top.append(Vector2(coordinate[0],coordinate[1]))
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
		terrain.add_child(body)

static func ground_y(room: Dictionary, x: float, near_y: float, best: float, distance: float) -> float:
	for surface: Array in room.get("painted_supports",[]):
		for i: int in range(1,surface.size()):
			var a:=Vector2(surface[i-1][0],surface[i-1][1])
			var b:=Vector2(surface[i][0],surface[i][1])
			if x<a.x or x>b.x or is_equal_approx(a.x,b.x): continue
			var y: float=lerpf(a.y,b.y,(x-a.x)/(b.x-a.x))
			if absf(y-near_y)<distance:
				best=y
				distance=absf(y-near_y)
	return best
