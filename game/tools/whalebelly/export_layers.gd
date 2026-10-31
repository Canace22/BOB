@warning_ignore_start("untyped_declaration")
extends SceneTree
## Native Godot render/export. Original raster files remain unchanged.
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var rooms: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var manifest: Array=[]
	for room: Dictionary in rooms:
		var viewport: SubViewport=SubViewport.new()
		viewport.size=Vector2i(int(room.size[0]),int(room.size[1]))
		viewport.transparent_bg=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var scene: Node2D=load("res://content/whalebelly/r1/"+str(room.id)+".tscn").instantiate()
		viewport.add_child(scene)
		var folder: String="res://art/whalebelly/runtime/layers/"+str(room.id)
		DirAccess.make_dir_recursive_absolute(folder)
		for layer: String in ["Far","Middle","World","Foreground"]:
			for other: String in ["Far","Middle","World","Foreground"]:scene.get_node(other).visible=other==layer
			for child: Node in scene.get_node("World").get_children():
				if child.name in ["PlayerArt","EnemyArt0","EnemyArt1","RewardArt","DoorArt"]:child.visible=false
			await process_frame
			await RenderingServer.frame_post_draw
			var path: String=folder+"/"+layer+".png"
			var result: Error=viewport.get_texture().get_image().save_png(path)
			manifest.append({"room":room.id,"layer":layer,"path":path,"size":room.size,"transparent":true,"result":result})
		for other: String in ["Far","Middle","World","Foreground"]:scene.get_node(other).visible=false
		scene.get_node("World").visible=true
		scene.get_node("World/WorldOriginalPixels").visible=false
		for a: Dictionary in room.actors:
			for b: Dictionary in room.actors:scene.get_node("World/"+str(b.name)).visible=a.name==b.name
			await process_frame
			await RenderingServer.frame_post_draw
			var image: Image=viewport.get_texture().get_image()
			var bounds: Rect2i=image.get_used_rect()
			var path: String=folder+"/"+str(a.name)+".png"
			image.get_region(bounds).save_png(path)
			manifest.append({"room":room.id,"actor":a.name,"path":path,"source_rect":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"pivot_source_px":room.spawn if a.name=="PlayerArt" else []})
		viewport.queue_free()
		await process_frame
	FileAccess.open("res://docs/native-export.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	print("EXPORTED ",manifest.size()," native layers/cutouts")
	quit()
