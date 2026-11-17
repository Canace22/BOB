extends SceneTree
## 独立存档机位：房内台端和外沿不能只用门中央截图替代。
var host: WhalebellyMain
const OUT := "res://build/qa/water-edges"
func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await process_frame
func capture(label: String) -> void:
	host.camera.update_follow(1.0/60.0)
	await tick(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","water-edges-qa")
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(8)
	var all_rooms: bool = OS.get_cmdline_user_args().has("--all")
	var selected: String = "R2-01"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--room="): selected=argument.trim_prefix("--room=")
	var views: int = 0
	for index: int in host.rooms.size():
		var id: String = str(host.rooms[index].id)
		if not all_rooms and id!=selected: continue
		host.load_room(index)
		host.player.set_physics_process(false)
		host.player.invulnerable=1000
		for wait_frame: int in 300:
			var ready: bool = true
			for neighbor: int in host.streaming.neighbors(index):
				ready = ready and host.streaming.is_ready(neighbor)
			if ready: break
			await tick(1)
		var size := Vector2(float(host.rooms[index].size[0]),float(host.rooms[index].size[1]))
		var points: Array[Vector2] = [Vector2(80,80),Vector2(size.x-80,80),Vector2(80,size.y-80),size-Vector2(80,80)]
		for surface: Array in host.rooms[index].get("surfaces",[]):
			var end: Array = surface[-1]
			points.append(Vector2(float(end[0])-100,float(end[1])-6))
		if id=="R2-01": points.push_front(Vector2(2120,1658))
		if OS.get_cmdline_user_args().has("--sweep"):
			points.clear()
			for x: float in [400.0,800.0,1200.0,1600.0,2000.0,2280.0]: points.append(Vector2(x,size.y-182.0))
		for slot: int in points.size():
			host.player.global_position=host.streaming.origin(index)+points[slot]
			await capture(id+"-"+str(slot))
			views += 1
		print("WATER_VIEWS ",id," count=",points.size())
	print("WATER_VIEWS_TOTAL ",views)
	await host.graceful_quit()
