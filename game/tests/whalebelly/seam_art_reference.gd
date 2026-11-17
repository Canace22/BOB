extends SceneTree
## 输出实际两房同坐标参考；路线线条仅作补绘约束，不进入正式美术。
var host: WhalebellyMain
var viewport: SubViewport
var capture_camera: Camera2D
const OUT := "res://build/qa/seam-art-references"

func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","seam-art")
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(8)
	host.set_process(false)
	host.player_ui.hide()
	host.ui.hide()
	viewport=SubViewport.new()
	viewport.size=Vector2i(1536,1024)
	viewport.world_2d=root.world_2d
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	capture_camera=Camera2D.new()
	viewport.add_child(capture_camera)
	capture_camera.make_current()
	var records: Array[Dictionary]=[]
	for link: Dictionary in host.streaming.layout.links:
		if "--first" in OS.get_cmdline_user_args() and not (link.a==0 and link.b==1): continue
		host.load_room(int(link.a))
		host.player.set_physics_process(false)
		host.actor_frame.hide()
		for i: int in 300:
			if host.streaming.is_ready(int(link.b)): break
			await tick(1)
		for index: int in host.streaming.cached: host.streaming.cached[index].scene.visible=index==int(link.b)
		for room: Node2D in [host.scenery,host.streaming.cached[int(link.b)].scene]:
			for child: Node in room.find_children("*","Node",true,false):
				if child is CampaignCorpseCrab or child is CampaignCrabBoss or child is KitEncounter or child is ChapterFishGroup: child.hide()
			var doorways: Node=room.get_node_or_null("Doorways")
			if doorways!=null: doorways.hide()
		host.streaming.gates.hide()
		for child: Node in host.streaming.corridors.get_children():
			if str(child.name).begins_with("Connection_"): child.hide()
		var bounds:=Rect2(link.path[0],Vector2.ZERO)
		for point: Vector2 in link.path: bounds=bounds.expand(point)
		bounds=bounds.grow(520)
		var portrait: bool=bounds.size.y>bounds.size.x*1.3
		viewport.size=Vector2i(1024,1536) if portrait else Vector2i(1536,1024)
		var ratio: float=float(viewport.size.x)/viewport.size.y
		var width: float=maxf(bounds.size.x,bounds.size.y*ratio)
		bounds=Rect2(bounds.get_center()-Vector2(width,width/ratio)*0.5,Vector2(width,width/ratio))
		capture_camera.global_position=bounds.get_center()
		capture_camera.zoom=Vector2.ONE*viewport.size.x/bounds.size.x
		host.camera.global_position=capture_camera.global_position
		host.camera.zoom=capture_camera.zoom
		host.camera.force_update_scroll()
		capture_camera.force_update_scroll()
		var guide:=Line2D.new()
		guide.points=link.path
		guide.width=3.0/capture_camera.zoom.x
		guide.default_color=Color(0.2,1.0,0.2)
		guide.z_index=200
		host.add_child(guide)
		await tick(10)
		await RenderingServer.frame_post_draw
		var name: String="%s--%s" % [host.rooms[int(link.a)].id,host.rooms[int(link.b)].id]
		viewport.get_texture().get_image().save_png(OUT.path_join(name+".png"))
		var pixels: Array=[]
		for point: Vector2 in link.path: pixels.append([(point.x-bounds.position.x)/bounds.size.x*viewport.size.x,(point.y-bounds.position.y)/bounds.size.y*viewport.size.y])
		records.append({"id":name,"a":link.a,"b":link.b,"world":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"size":[viewport.size.x,viewport.size.y],"path":pixels})
		guide.queue_free()
		print("REFERENCE ",name)
	var file:=FileAccess.open(OUT.path_join("references.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"\t"))
	file.close()
	viewport.queue_free()
	await host.graceful_quit()
