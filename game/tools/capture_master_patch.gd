extends SceneTree
## 从完整母版取同坐标补绘参考，背景与地形分别保存，不把背景烘焙进承重层。
func _initialize() -> void: run.call_deferred()

func run() -> void:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(1536,1024)
	viewport.transparent_bg=true
	viewport.world_2d=World2D.new()
	root.add_child(viewport)
	var packed: PackedScene=load(ProjectSettings.globalize_path("res://../assets/source/world-terrain-v1/master.tscn"))
	var master: Node2D=packed.instantiate()
	viewport.add_child(master)
	# 母版不烘焙会下垂的舌台；绘画参考仍须显示它的静止位置，避免把缺层当成空地重画。
	var base: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var layout: Dictionary=CampaignStreamingLayout.build(CampaignWorld.load_rooms(base))
	for index: int in layout.rooms.size():
		if layout.rooms[index].id!="R1-03": continue
		var scene: Node2D=load(CampaignWorld.scene_path("R1-03")).instantiate()
		var original: Sprite2D=scene.get_node("ChapterEnvironment/World/Surface")
		var transform: Transform2D=original.transform
		var ancestor: Node=original.get_parent()
		while ancestor is Node2D or ancestor is Control:
			transform=ancestor.get_transform()*transform
			ancestor=ancestor.get_parent()
		var reference:=Sprite2D.new()
		reference.texture=original.texture
		reference.centered=original.centered
		reference.transform=transform
		reference.position+=Vector2(layout.origins[index])
		var material:=ShaderMaterial.new()
		material.shader=load("res://tools/terrain_master.gdshader")
		material.set_shader_parameter("use_mask",true)
		material.set_shader_parameter("content_mask",load("res://art/continuous-backdrops-v1/chapter/R1-03-World.png"))
		reference.material=material
		master.add_child(reference)
		scene.free()
	DirAccess.make_dir_recursive_absolute("res://build/qa/seam-repaint")
	var entries: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/seamless-continuity-v1/registration.json"))
	if OS.get_cmdline_user_args().has("--shaft-ends"):
		entries=[]
		for link: Dictionary in layout.links:
			var id: String=str(layout.rooms[int(link.a)].id)+"--"+str(layout.rooms[int(link.b)].id)
			if not ResourceLoader.exists("res://art/seamless-continuity-v1/"+id+"-depth.png"): continue
			for side: int in 2:
				var foot: Vector2=link.path[0] if side==0 else link.path[-1]
				entries.append({"id":id+("--start" if side==0 else "--end"),"world":[foot.x-780,foot.y-520,1560,1040],"size":[1536,1024]})
		var file:=FileAccess.open("res://build/qa/seam-repaint/shaft-ends.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(entries,"\t"))
	for entry: Dictionary in entries:
		if not OS.get_cmdline_user_args().has("--all") and not OS.get_cmdline_user_args().has("--shaft-ends") and entry.id!="R1-01--R1-02": continue
		var area:=Rect2(entry.world[0],entry.world[1],entry.world[2],entry.world[3])
		viewport.size=Vector2i(entry.size[0],entry.size[1])
		var factor: Vector2=Vector2(viewport.size)/area.size
		viewport.canvas_transform=Transform2D(Vector2(factor.x,0),Vector2(0,factor.y),-area.position*factor)
		for terrain_only: bool in [false,true]:
			master.get_node("ContinuousWater").visible=not terrain_only
			viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
			await process_frame
			await RenderingServer.frame_post_draw
			var suffix: String="terrain" if terrain_only else "scene"
			viewport.get_texture().get_image().save_png("res://build/qa/seam-repaint/"+str(entry.id)+"-"+suffix+".png")
	quit()
