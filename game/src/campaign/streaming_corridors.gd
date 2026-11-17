class_name CampaignStreamingCorridors
extends Node2D
## 连接使用入库位图；矩形只作不可见碰撞，不代替正式美术。
var host: Node2D
var layout: Dictionary = {}
var platform_count: int = 0
var links: Array = []
var seam_art: CampaignSeamArt
var world_terrain: CampaignWorldTerrain
const PLATFORM: Texture2D = preload("res://art/world-kit/r3-bank-platform.png")
const WATER: Texture2D = preload("res://art/world-kit/r3-water-base.png")
const WIDTH := 140.0
const DEPTH := 18.0

static func prepare_scene(index: int, scene: Node2D, data: Dictionary) -> void:
	var rooms: Array = data.get("rooms",[])
	if index<0 or index>=rooms.size(): return
	CampaignPaintedSupports.prepare_scene(scene,rooms[index])
	# 主干原画支撑材质按房内坐标采样；流式房根非零时先明确世界偏移。
	for sprite: Node in scene.find_children("*","Sprite2D",true,false):
		if sprite.material is ShaderMaterial and sprite.material.shader.resource_path.ends_with("/native_foundation.gdshader"):
			sprite.material=sprite.material.duplicate(false)
			sprite.material.set_shader_parameter("stream_room_offset",Vector2(data.origins[index]))

	if str(rooms[index].id)=="R2-04":
		_prepare_lung_endcap(scene)
		return
	if str(rooms[index].id)!="R4-06" or scene.has_meta("streaming_tail_shaft"): return
	var left: float = CampaignStreamingLayout.TAIL_SHAFT_LEFT
	var right: float = CampaignStreamingLayout.TAIL_SHAFT_RIGHT
	# 物理与位图都开同一条竖口，不能只删碰撞让主角穿过完整地板图。
	for path: String in ["World/Terrain/Surface_P1/Contour","World/Terrain/Bed0/Contour"]:
		_cut_collision(scene.get_node_or_null(path) as CollisionPolygon2D,left,right)
	var art: Node = scene.get_node_or_null("World/Art")
	if art != null:
		for sprite: Node in art.get_children():
			if sprite is Sprite2D and (str(sprite.name).begins_with("P1_") or str(sprite.name).begins_with("Bed0_")):
				_cut_bitmap(scene,sprite,left,right)
	var folds: Node = scene.get_node_or_null("Foreground/Folds")
	if folds != null:
		for sprite: Node in folds.get_children():
			# 前景有少量视差，预留边缘余量，不让它在主角下行时重新遮住洞口。
			if sprite is Sprite2D: _cut_bitmap(scene,sprite,left-80,right+80)
	scene.set_meta("streaming_tail_shaft",true)

static func _prepare_lung_endcap(scene: Node2D) -> void:
	if scene.has_meta("streaming_lung_endcap"): return
	# 尽头是封闭肺膜，不用可开门外观，也不新增通路；同区位图旋转等比组成壁面。
	var wall:=Sprite2D.new()
	wall.name="LungEndcap"
	wall.texture=load("res://art/world-kit/r2-soft-bed.png")
	wall.centered=false
	wall.rotation=PI*0.5
	wall.scale=Vector2.ONE*1.32
	wall.position=Vector2(3080,-120)
	wall.set_meta("stream_master_terrain_source",true)
	scene.get_node("World/Art").add_child(wall)
	var body:=StaticBody2D.new()
	body.name="LungEndcapBoundary"
	body.collision_layer=1
	body.collision_mask=2
	body.position=Vector2(2834,730)
	var shape:=CollisionShape2D.new()
	var rectangle:=RectangleShape2D.new()
	rectangle.size=Vector2(48,1800)
	shape.shape=rectangle
	body.add_child(shape)
	scene.get_node("World/Terrain").add_child(body)
	scene.set_meta("streaming_lung_endcap",true)

static func _cut_collision(contour: CollisionPolygon2D, left: float, right: float) -> void:
	if contour == null or contour.polygon.size()!=4: return
	var bounds := Rect2(contour.polygon[0],Vector2.ZERO)
	for point: Vector2 in contour.polygon: bounds = bounds.expand(point)
	if bounds.position.x>=left or bounds.end.x<=right: return
	var other := contour.duplicate() as CollisionPolygon2D
	other.name = str(contour.name)+"ShaftRight"
	# duplicate 保留原床面/单向平台的区别、碰撞层和 margin。
	contour.polygon = PackedVector2Array([bounds.position,Vector2(left,bounds.position.y),Vector2(left,bounds.end.y),Vector2(bounds.position.x,bounds.end.y)])
	other.polygon = PackedVector2Array([Vector2(right,bounds.position.y),Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(right,bounds.end.y)])
	contour.get_parent().add_child(other)

static func _cut_bitmap(scene: Node2D, sprite: Sprite2D, left: float, right: float) -> void:
	if sprite.texture == null or sprite.centered or sprite.region_enabled: return
	var transform: Transform2D = scene.global_transform.affine_inverse()*sprite.global_transform
	if absf(transform.x.y)>0.001 or transform.x.x<=0: return
	var width: float = sprite.texture.get_width()
	var start: float = clampf((left-transform.origin.x)/transform.x.x,0,width)
	var end: float = clampf((right-transform.origin.x)/transform.x.x,0,width)
	if end<=start: return
	var parent: Node = sprite.get_parent()
	for span: Vector2 in [Vector2(0,start),Vector2(end,width)]:
		if span.y-span.x<=0.01: continue
		var piece := sprite.duplicate() as Sprite2D
		piece.name = str(sprite.name)+("ShaftLeft" if span.x==0 else "ShaftRight")
		piece.position.x += span.x*sprite.scale.x
		piece.region_enabled = true
		# flip_h 翻的是采样区，右半图对应的纹理坐标必须反向截取。
		var texture_x: float = width-span.y if sprite.flip_h else span.x
		piece.region_rect = Rect2(texture_x,0,span.y-span.x,sprite.texture.get_height())
		piece.region_filter_clip_enabled = true
		parent.add_child(piece)
	parent.remove_child(sprite)
	sprite.free()

func build() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	platform_count = 0
	links = layout.get("links",[])
	seam_art=CampaignSeamArt.new()
	seam_art.host=host
	seam_art.layout=layout
	add_child(seam_art)
	_build_backdrop()
	for i: int in links.size():
		var link: Dictionary = links[i]
		var group := Node2D.new()
		group.name = "Connection_%d_%d" % [int(link.a),int(link.b)]
		add_child(group)
		for point: Vector2 in PackedVector2Array(link.path):
			if not _existing_surface(point):
				_platform(group,point,false)
				# 竖井包含首尾水平接段，同样必须补本区台根，不能留下不可见台或异区金色台面。
				_native_ledge(group,point,link)

func _build_backdrop() -> void:
	add_child(CampaignStreamWater.create(layout))
	if FileAccess.file_exists(CampaignWorldTerrain.DATA):
		world_terrain=CampaignWorldTerrain.new()
		world_terrain.host=host
		add_child(world_terrain)

func _platform(parent: Node2D, at: Vector2, show_art: bool = true) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = PLATFORM
	sprite.centered = false
	sprite.visible=show_art
	# 台账原尺寸2162×727，Alpha包围盒(84,191)-(2079,626)，站面在235px。
	# 同步纹理可能已等比缩小，使用比例指标对齐可见平台与碰撞顶面。
	var factor: float = WIDTH/(PLATFORM.get_width()*(1995.0/2162.0))
	sprite.scale = Vector2.ONE*factor
	sprite.position = at-Vector2(WIDTH*0.5+PLATFORM.get_width()*(84.0/2162.0)*factor,PLATFORM.get_height()*(235.0/727.0)*factor)
	parent.add_child(sprite)
	var body := StaticBody2D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WIDTH-12,DEPTH)
	collision.shape = shape
	collision.position.y = DEPTH*0.5
	collision.one_way_collision = true
	collision.one_way_collision_margin = 6.0
	body.add_child(collision)
	parent.add_child(body)
	platform_count += 1

func _has_depth_art(link: Dictionary) -> bool:
	var id: String=str(layout.rooms[int(link.a)].id)+"--"+str(layout.rooms[int(link.b)].id)
	return ResourceLoader.exists("res://art/seamless-continuity-v1/"+id+"-depth.png")

func _native_ledge(parent: Node2D, at: Vector2, link: Dictionary) -> void:
	var id: String=str(layout.rooms[int(link.a)].id)
	var root_path: String="res://art/seamless-continuity-v1/ledge-lung-root.png" if id=="R3-01" else "res://art/seamless-continuity-v1/ledge-oral-root.png"
	if ResourceLoader.exists(root_path):
		var root:=Sprite2D.new()
		root.name="RegisteredLedge"
		# 同一父节点有多块台根，Godot会自动改名；母版收集不能依赖显示名称。
		root.set_meta("stream_master_ledge",true)
		root.texture=load(root_path)
		root.centered=false
		var factor: float=WIDTH/(500.0 if id=="R3-01" else 580.0)
		var anchor:=Vector2(350,250) if id=="R3-01" else Vector2(400,267)
		var path: PackedVector2Array=link.path
		var index: int=path.find(at)
		var axis: float=0.0
		for adjacent: int in [index-1,index+1]:
			if adjacent>=0 and adjacent<path.size() and absf(path[adjacent].y-at.y)>10: axis+=path[adjacent].x-at.x
		var direction: float=1.0 if axis>=0 else -1.0
		root.scale=Vector2(factor*direction,factor)
		root.position=at-Vector2(anchor.x*factor*direction,anchor.y*factor)
		root.z_index=2
		# 厚根以背景的冷暗体积为基准，保留台面高光，避免高对比白边像贴纸。
		root.modulate=Color(0.82,0.86,0.9) if id=="R3-01" else Color(0.78,0.84,0.9)
		root.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		root.visible=not FileAccess.file_exists(CampaignWorldTerrain.DATA)
		parent.add_child(root)
		return
	var path: String="res://art/seamless-continuity-v1/ledges/r1.png"
	var left: float=0.0
	var top: float=0.0
	var width: float=1.0
	if not id.begins_with("R1"):
		path="res://art/world-kit/r2-membrane-platform.png" if id=="R3-01" else "res://art/world-kit/r4-bone-platform.png"
		left=60.0/2162.0 if id=="R3-01" else 63.0/2098.0
		top=192.0/727.0 if id=="R3-01" else 239.0/749.0
		width=2042.0/2162.0 if id=="R3-01" else 1972.0/2098.0
	var texture: Texture2D=load(path)
	var sprite:=Sprite2D.new()
	sprite.name="RegisteredLedge"
	sprite.set_meta("stream_master_ledge",true)
	sprite.texture=texture
	sprite.centered=false
	var factor: float=WIDTH/(texture.get_width()*width)
	sprite.scale=Vector2.ONE*factor
	sprite.position=at-Vector2(WIDTH*0.5+texture.get_width()*left*factor,texture.get_height()*top*factor)
	sprite.z_index=2
	parent.add_child(sprite)

func _existing_surface(point: Vector2) -> bool:
	var rooms: Array = layout.get("rooms",[])
	var origins: Dictionary = layout.get("origins",{})
	for index: int in origins:
		var local: Vector2 = point-Vector2(origins[index])
		if not Rect2(Vector2.ZERO,Vector2(float(rooms[index].size[0]),float(rooms[index].size[1]))).has_point(local): continue
		for surface: Array in rooms[index].get("surfaces",[]):
			# 只有整块落脚面已被原地形覆盖时才省略拼台，不能在房边留下半台宽空隙。
			var first_x: float = float(surface[0][0])
			var last_x: float = float(surface[-1][0])
			if local.x < minf(first_x,last_x)+WIDTH*0.5 or local.x > maxf(first_x,last_x)-WIDTH*0.5: continue
			for j: int in range(1,surface.size()):
				var a := Vector2(float(surface[j-1][0]),float(surface[j-1][1]))
				var b := Vector2(float(surface[j][0]),float(surface[j][1]))
				if absf(b.x-a.x)<0.01 or local.x<minf(a.x,b.x) or local.x>maxf(a.x,b.x): continue
				var y: float = lerpf(a.y,b.y,(local.x-a.x)/(b.x-a.x))
				if absf(local.y-y)<28.0: return true
	return false

func corridor_segment_near(world: Vector2) -> Dictionary:
	var nearest: Dictionary = {}
	var distance: float = 260.0
	for link: Dictionary in links:
		var path: PackedVector2Array = link.path
		for i: int in range(1,path.size()):
			var point: Vector2 = Geometry2D.get_closest_point_to_segment(world,path[i-1],path[i])
			var gap: float = point.distance_to(world)
			if gap >= distance: continue
			distance = gap
			nearest = {"a":int(link.a),"b":int(link.b),"link":link,"point":point,"distance":gap,"segment":i-1}
	return nearest
