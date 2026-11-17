class_name CampaignSeamArt
extends Node2D
## 联合补绘按实机参考的世界矩形定位，不改碰撞或拉伸两端房间。
const DATA := "res://art/seamless-continuity-v1/registration.json"
const BLEND := preload("res://src/campaign/seam_art.gdshader")
var host: Node2D
var layout: Dictionary
var groups: Array[Dictionary] = []
static var patch_cache: Dictionary={}

func _ready() -> void:
	# 旧注册属于上一版房间尺寸，只作制作源保留。
	if layout.rooms[0].has("layout"): return
	if not FileAccess.file_exists(DATA): return
	var records: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if not records is Array: return
	for record: Dictionary in records:
		var path: String = "res://art/seamless-continuity-v1/"+str(record.id)+".png"
		if not ResourceLoader.exists(path): continue
		var link: Dictionary = {}
		for edge: Dictionary in layout.links:
			if int(edge.a)==int(record.a) and int(edge.b)==int(record.b): link=edge
		if link.is_empty(): continue
		var rect := Rect2(float(record.world[0]),float(record.world[1]),float(record.world[2]),float(record.world[3]))
		var depth_path: String=path.trim_suffix(".png")+"-depth.png"
		if ResourceLoader.exists(depth_path):
			# 竖井远景已交给统一世界背景，落脚台仍由精确注册的独立台根负责。
			var shaft := Node2D.new()
			shaft.name = str(record.id).replace("--","_")
			add_child(shaft)
			groups.append({"node":shaft,"a":int(link.a),"b":int(link.b)})
			continue
		var terrain_path: String = "res://art/continuous-backdrops-v1/terrain/"+str(record.id)+".png"
		var texture: Texture2D = load(terrain_path if ResourceLoader.exists(terrain_path) else path)
		var scale: float = rect.size.x/texture.get_width()
		if absf(scale*texture.get_height()-rect.size.y)>2.0:
			push_error("Seam art aspect mismatch: "+str(record.id))
			continue
		var group := Node2D.new()
		group.name = str(record.id).replace("--","_")
		add_child(group)
		var sprite := Sprite2D.new()
		sprite.texture=texture
		sprite.centered=false
		sprite.position=rect.position
		sprite.scale=Vector2.ONE*scale
		sprite.z_index=1
		var material := ShaderMaterial.new()
		material.shader=BLEND
		material.set_shader_parameter("patch_rect",Vector4(rect.position.x,rect.position.y,rect.size.x,rect.size.y))
		for side: String in ["a","b"]:
			var room: Rect2=layout.room_bounds[int(link[side])]
			material.set_shader_parameter("room_"+side,Vector4(room.position.x,room.position.y,room.size.x,room.size.y))
		var protected: PackedVector4Array=[]
		for index: int in layout.room_bounds:
			if index==int(link.a) or index==int(link.b): continue
			var room: Rect2=layout.room_bounds[index]
			if room.grow(80).intersects(rect): protected.append(Vector4(room.position.x,room.position.y,room.size.x,room.size.y))
		material.set_shader_parameter("protected_rooms",protected)
		material.set_shader_parameter("protected_count",protected.size())
		sprite.material=material
		group.add_child(sprite)
		groups.append({"node":group,"a":int(link.a),"b":int(link.b)})

func _process(_dt: float) -> void:
	if not is_instance_valid(host) or host.quitting: return
	for entry: Dictionary in groups:
		entry.node.visible=not FileAccess.file_exists(CampaignWorldTerrain.DATA) and host.streaming.is_ready(entry.a) and host.streaming.is_ready(entry.b) and not host.reference_visible and host.layer_solo<0 and host.capture_path.is_empty()

func has_edge(a: int,b: int) -> bool:
	for entry: Dictionary in groups:
		if entry.a==a and entry.b==b: return true
	return false

static func patches_for(room_origin: Vector2) -> PackedVector4Array:
	if patch_cache.has(room_origin): return patch_cache[room_origin]
	var result:=PackedVector4Array()
	if not FileAccess.file_exists(DATA): return result
	var records: Array=JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var base: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var rooms: Array=CampaignWorld.load_rooms(base)
	var data: Dictionary=CampaignStreamingLayout.build(rooms)
	var index: int=-1
	for id: int in data.origins:
		if Vector2(data.origins[id]).is_equal_approx(room_origin): index=id
	for record: Dictionary in records:
		if int(record.a)!=index and int(record.b)!=index: continue
		result.append(Vector4(float(record.world[0]),float(record.world[1]),float(record.world[2]),float(record.world[3])))
	patch_cache[room_origin]=result
	return result
