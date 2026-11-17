extends SceneTree
## 实际碰撞落稳、按键行走与母版脚下Alpha同时检查。
var host: WhalebellyMain
var failures: int=0
var images: Dictionary={}
func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await physics_frame
func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","terrain-solidity")
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(8)
	var index: int=-1
	for i: int in host.rooms.size():
		if host.rooms[i].id=="R2-01": index=i
	host.load_room(index)
	host.player.position=Vector2(500,1640)
	host.player.invulnerable=1000
	await tick(30)
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_D
	event.keycode=KEY_D
	event.pressed=true
	Input.parse_input_event(event)
	var sampled: int=0
	var records: Array=JSON.parse_string(FileAccess.get_file_as_string(CampaignWorldTerrain.DATA))
	for frame: int in 180:
		await tick(1)
		if frame%6!=0: continue
		var point: Vector2=host.player.global_position+Vector2(0,8)
		var alpha: float=0.0
		for record: Dictionary in records:
			var rect:=Rect2(record.x,record.y,record.width,record.height)
			if not rect.has_point(point): continue
			if not images.has(record.file): images[record.file]=load("res://art/world-terrain-v1/"+str(record.file)).get_image()
			var pixel:=Vector2i(point-rect.position)+Vector2i(2,2)
			alpha=images[record.file].get_pixelv(pixel).a
		if not host.player.is_on_floor() or alpha<0.85:
			failures+=1
			print("SOLIDITY_FAIL local=",host.player.position," floor=",host.player.is_on_floor()," alpha=",alpha)
		sampled+=1
	event.pressed=false
	Input.parse_input_event(event)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/qa/terrain-solidity.png")
	print("TERRAIN_SOLIDITY samples=",sampled," failed=",failures," position=",host.player.position)
	await host.graceful_quit(1 if failures else 0)
