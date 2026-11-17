extends SceneTree
## 从完整母版取同坐标补绘参考，背景与地形分别保存，不把背景烘焙进承重层。
func _initialize() -> void: run.call_deferred()

func run() -> void:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(1536,1024)
	viewport.transparent_bg=true
	viewport.world_2d=World2D.new()
	root.add_child(viewport)
	var packed: PackedScene=load(ProjectSettings.globalize_path("res://../assets/source/world-terrain-v2/master.tscn"))
	var master: Node2D=packed.instantiate()
	viewport.add_child(master)
	DirAccess.make_dir_recursive_absolute("res://build/qa/seam-repaint")
	var base: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var layout: Dictionary=CampaignStreamingLayout.build(CampaignWorld.load_rooms(base))
	var entries: Array=[]
	for link: Dictionary in layout.links:
		var id: String=str(layout.rooms[int(link.a)].id)+"--"+str(layout.rooms[int(link.b)].id)
		var is_shaft: bool=ResourceLoader.exists("res://art/seamless-continuity-v1/"+id+"-depth.png")
		if is_shaft:
			for side: int in 2:
				var foot: Vector2=link.path[0] if side==0 else link.path[-1]
				entries.append({"id":id+("--start" if side==0 else "--end"),"world":[foot.x-780,foot.y-520,1560,1040],"size":[1536,1024]})
		else:
			var bounds:=Rect2(link.path[0],Vector2.ZERO)
			for point: Vector2 in link.path: bounds=bounds.expand(point)
			bounds=bounds.grow(520)
			var width: float=maxf(bounds.size.x,bounds.size.y*1.5)
			bounds=Rect2(bounds.get_center()-Vector2(width,width/1.5)*0.5,Vector2(width,width/1.5))
			entries.append({"id":id,"world":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"size":[1536,1024]})
	var file:=FileAccess.open("res://build/qa/seam-repaint/new-registration.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(entries,"\t"))
	for entry: Dictionary in entries:
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
