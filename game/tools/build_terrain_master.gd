extends SceneTree
## 先构造唯一世界母版并导出总览，再从相同节点树逐块取像素，禁止逐房拼淡边。
var OUT: String = ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()+"/assets/runtime/sprites/world-terrain-v1"
var SOURCE: String = ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()+"/assets/source/world-terrain-v1"
const TILE := 1536
const GUTTER := 2
const MATERIAL := preload("res://tools/terrain_master.gdshader")
var viewport: SubViewport
var master: Node2D
var layout: Dictionary
var items: Array[Dictionary] = []
var chunks: Array[Dictionary] = []
func _initialize() -> void: run.call_deferred()

func add_sprite(source: Sprite2D, transform: Transform2D, label: String, connector: bool=false) -> void:
	var sprite:=Sprite2D.new()
	sprite.name="Part_%04d"%items.size()
	sprite.texture=source.texture
	sprite.centered=source.centered
	sprite.offset=source.offset
	sprite.flip_h=source.flip_h
	sprite.flip_v=source.flip_v
	sprite.region_enabled=source.region_enabled
	sprite.region_rect=source.region_rect
	sprite.transform=transform
	var material:=ShaderMaterial.new()
	material.shader=MATERIAL
	material.set_shader_parameter("connector",connector)
	var rectangles:=PackedVector4Array()
	for index: int in layout.room_bounds:
		var rect: Rect2=layout.room_bounds[index]
		rectangles.append(Vector4(rect.position.x,rect.position.y,rect.size.x,rect.size.y))
	material.set_shader_parameter("rooms",rectangles)
	material.set_shader_parameter("room_count",rectangles.size())
	var path: String=source.texture.resource_path
	var mask_path: String=""
	if path.contains("/r1-chapter-scenes/"):
		mask_path="res://art/continuous-backdrops-v1/chapter/"+path.get_base_dir().get_file()+"-"+path.get_file()
		if ResourceLoader.exists(mask_path):
			material.set_shader_parameter("content_mask",load(mask_path))
			material.set_shader_parameter("use_mask",true)
	sprite.material=material
	master.add_child(sprite)
	sprite.owner=master
	var rect: Rect2=transform*source.get_rect()
	items.append({"node":sprite,"rect":rect,"source":path,"label":label,"mask":mask_path,"connector":connector,"transform":[transform.x.x,transform.x.y,transform.y.x,transform.y.y,transform.origin.x,transform.origin.y]})

func render_at(rect: Rect2, size: Vector2i) -> Image:
	viewport.size=size
	var scale: Vector2=Vector2(size)/rect.size
	viewport.canvas_transform=Transform2D(Vector2(scale.x,0),Vector2(0,scale.y),-rect.position*scale)
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	DirAccess.make_dir_recursive_absolute(SOURCE)
	var base: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	layout=CampaignStreamingLayout.build(CampaignWorld.load_rooms(base))
	viewport=SubViewport.new()
	viewport.transparent_bg=true
	viewport.world_2d=World2D.new()
	root.add_child(viewport)
	master=Node2D.new()
	master.name="WorldTerrainMaster"
	viewport.add_child(master)
	for index: int in layout.rooms.size():
		var scene: Node2D=load(CampaignWorld.scene_path(str(layout.rooms[index].id))).instantiate()
		CampaignStreamingCorridors.prepare_scene(index,scene,layout)
		scene.position=layout.origins[index]
		for node: Node in scene.find_children("*","Sprite2D",true,false):
			if CampaignWorldTerrain.owns(node):
				# 尚未进树的裁切副本没有有效global_transform，显式累乘父链直到房根。
				var transform: Transform2D=node.transform
				var ancestor: Node=node.get_parent()
				while ancestor is Node2D or ancestor is Control:
					transform=ancestor.get_transform()*transform
					ancestor=ancestor.get_parent()
				if str(layout.rooms[index].id) in ["R3-01","R4-01","R4-03"] and str(node.name).begins_with("Bed"):
					# 旧重复底床在自然收尖处留了可碰撞空隙；绕脚线等比加少量重叠。
					var foot: float=float(layout.rooms[index].surfaces[0][0][1])+Vector2(layout.origins[index]).y
					var anchor:=Vector2((transform*node.get_rect().get_center()).x,foot)
					transform.origin=anchor+(transform.origin-anchor)*1.06
					transform.x*=1.06
					transform.y*=1.06
				add_sprite(node,transform,str(layout.rooms[index].id)+"/"+str(scene.get_path_to(node)))
		scene.free()
		if str(layout.rooms[index].id)=="R3-01":
			# 胃枢底床原来只用了带开孔的装饰褶皱，补同区入库岸台作为实体承重面。
			var texture: Texture2D=load("res://art/world-kit/r3-bank-platform.png")
			var origin: Vector2=layout.origins[index]
			var floor_y: float=origin.y+float(layout.rooms[index].surfaces[0][0][1])
			var width: float=float(layout.rooms[index].size[0])
			for slot: int in 4:
				var cap:=Sprite2D.new()
				cap.texture=texture
				cap.centered=false
				var factor: float=(width/4.0+80.0)/(texture.get_width()*(1995.0/2162.0))
				var at:=Vector2(origin.x+width*(slot+0.5)/4.0,floor_y)
				var transform:=Transform2D(0,Vector2.ONE*factor,0,at-Vector2(texture.get_width()*0.5,texture.get_height()*(235.0/727.0))*factor)
				add_sprite(cap,transform,"R3-01/solid-bed-cap")
				cap.free()
		if str(layout.rooms[index].id)=="R1-06":
			# 现有返程碰撞的后半段原本缺少可见承重像素，用已入库台根补齐母版。
			var road: Array=layout.rooms[index].surfaces[5]
			for j: int in range(7,road.size()-1):
				var a:=Vector2(road[j][0],road[j][1])+Vector2(layout.origins[index])
				var b:=Vector2(road[j+1][0],road[j+1][1])+Vector2(layout.origins[index])
				var texture: Texture2D=load("res://art/seamless-continuity-v1/ledge-oral-root.png")
				var support:=Sprite2D.new()
				support.texture=texture
				support.centered=false
				var factor: float=(a.distance_to(b)+45.0)/580.0
				var transform:=Transform2D((b-a).angle(),Vector2.ZERO).scaled_local(Vector2.ONE*factor)
				transform.origin=(a+b)*0.5-transform.basis_xform(Vector2(400,267))
				add_sprite(support,transform,"R1-06/return-support")
				support.free()
	var corridors:=CampaignStreamingCorridors.new()
	corridors.layout=layout
	viewport.add_child(corridors)
	corridors.build()
	await process_frame
	# 连接也属于同一母版；原房实体优先，连接像素只拥有房间外的区域。
	for node: Node in corridors.find_children("*","Sprite2D",true,false):
		if node.has_meta("stream_master_ledge"): add_sprite(node,node.global_transform,"shaft-root")
		elif node.get_parent().get_parent()==corridors.seam_art:
			add_sprite(node,node.global_transform,"connector/"+str(node.get_parent().name),true)
	corridors.queue_free()
	await process_frame
	WorldMasterRepaints.apply(master,items)
	var bounds: Rect2=layout.bounds.grow(300)
	var far: Sprite2D=CampaignStreamWater.create(layout)
	master.add_child(far)
	far.owner=master
	var overview_size:=Vector2i(4096,maxi(1,roundi(bounds.size.y/bounds.size.x*4096)))
	var overview: Image=await render_at(bounds,overview_size)
	overview.save_png(SOURCE+"/overview.png")
	var packed:=PackedScene.new()
	packed.pack(master)
	ResourceSaver.save(packed,SOURCE+"/master.tscn")
	# 远景保留统一视差层；下面只切地形层，不能把远景烘焙到道路Alpha里。
	far.hide()
	var plan: Array=[]
	for item: Dictionary in items:
		var copy: Dictionary=item.duplicate()
		copy.erase("node")
		copy.rect=[item.rect.position.x,item.rect.position.y,item.rect.size.x,item.rect.size.y]
		plan.append(copy)
	save_json(SOURCE+"/composition.json",{"parts":plan,"tile_size":TILE,"gutter":GUTTER,"dynamic_layers":["R1-03 membrane: original live surface, shared world coordinates"]})
	var room_plan: Array=[]
	for index: int in layout.rooms.size():
		var at: Vector2=layout.origins[index]
		room_plan.append({"id":layout.rooms[index].id,"origin":[at.x,at.y],"size":layout.rooms[index].size,"surfaces":layout.rooms[index].surfaces})
	save_json(SOURCE+"/world-layout.json",room_plan)
	var connections: Array=[]
	for link: Dictionary in layout.links:
		var points: Array=[]
		for point: Vector2 in link.path: points.append([point.x,point.y])
		connections.append({"a":layout.rooms[int(link.a)].id,"b":layout.rooms[int(link.b)].id,"path":points})
	save_json(SOURCE+"/connections.json",connections)
	print("MASTER_ASSEMBLED parts=",items.size()," bounds=",bounds)
	for y: int in range(floori(bounds.position.y/TILE),ceili(bounds.end.y/TILE)):
		for x: int in range(floori(bounds.position.x/TILE),ceili(bounds.end.x/TILE)):
			var rect:=Rect2(x*TILE,y*TILE,TILE,TILE)
			if not items.any(func(item: Dictionary)->bool:return item.rect.intersects(rect.grow(GUTTER))): continue
			var bitmap: Image=await render_at(rect.grow(GUTTER),Vector2i(TILE+GUTTER*2,TILE+GUTTER*2))
			if bitmap.is_invisible(): continue
			var name: String="tile_%d_%d.png"%[x,y]
			var error: Error=bitmap.save_png(OUT+"/"+name)
			if error!=OK:
				push_error("Master chunk export failed: "+name)
				quit(1)
				return
			chunks.append({"file":name,"x":rect.position.x,"y":rect.position.y,"width":TILE,"height":TILE})
	save_json(OUT+"/chunks.json",chunks)
	print("MASTER_SLICED chunks=",chunks.size())
	quit()

func save_json(path: String, value: Variant) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(value,"\t"))
	file.close()
