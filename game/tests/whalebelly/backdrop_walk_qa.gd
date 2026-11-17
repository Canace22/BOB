extends SceneTree
## 心室观察台用真实按键移动，逐帧核对统一背景相位，不用定点图替代连续性。
var host: WhalebellyMain
const OUT := "res://build/qa/backdrop-walk"
func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await physics_frame
func key(down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode=KEY_D
	event.keycode=KEY_D
	event.pressed=down
	Input.parse_input_event(event)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","backdrop-walk")
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(8)
	var index: int = -1
	for i: int in host.rooms.size():
		if str(host.rooms[i].id)=="R2-03": index=i
	host.load_room(index)
	host.player.global_position=host.streaming.origin(index)+Vector2(420,1418)
	host.player.invulnerable=1000
	await tick(20)
	var backdrop: Sprite2D=host.streaming.corridors.get_node("ContinuousWater")
	var identity: int=backdrop.get_instance_id()
	var anchors: PackedVector2Array=backdrop.material.get_shader_parameter("anchors")
	var trace: Array=[]
	key(true)
	for frame: int in 260:
		await tick(1)
		var at: Vector2=host.player.global_position
		if frame%12==0:
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT.path_join("walk-%03d.png"%frame))
			trace.append({"frame":frame,"position":[at.x,at.y],"same_background":identity==backdrop.get_instance_id(),"fixed_anchors":anchors==backdrop.material.get_shader_parameter("anchors")})
		if at.x-host.streaming.origin(index).x>=2240: break
	key(false)
	var file:=FileAccess.open(OUT.path_join("trace.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(trace,"\t"))
	file.close()
	print("BACKDROP_WALK frames=",trace.size()," distance=",host.player.global_position.x-host.streaming.origin(index).x-420," same_background=",identity==backdrop.get_instance_id()," fixed_anchors=",anchors==backdrop.material.get_shader_parameter("anchors"))
	await host.graceful_quit()
