extends SceneTree
## Isolated QA save; real movement and GPU visibility at exterior edges.
var host: WhalebellyMain
var failures: int=0
var checks: Array[Dictionary]=[]
const OUT := "res://build/qa/camera-outer-edge"
func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await physics_frame
func check(label: String, passed: bool) -> void:
	checks.append({"label":label,"pass":passed})
	print("PASS " if passed else "FAIL ",label)
	if not passed: failures+=1
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))
func key(code: Key, down: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1280,720)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","camera-outer-edge")
	host.qa=true
	host.integration_external_test=true
	host.ui_interactive_in_tests=true
	root.add_child(host)
	current_scene=host
	await tick(30)
	host.player.position=Vector2(120,host.ground_y(120,600)-2)
	host.player.invulnerable=1000
	await tick(25)
	var center: Vector2=host.camera.get_screen_center_position()
	check("Left bank keeps actor centered",center.distance_to(host.player.global_position)<1.0)
	check("Actual screen center matches world target",center.distance_to(host.camera.follow_target(host.player.global_position))<1.0)
	await shot("01-left-edge")
	var start: Vector2=host.player.global_position
	var last: Vector2=center
	var peak: float=0.0
	key(KEY_D,true)
	# 主干首房是跳台布局，只在首块岸台上验证真实行走，不能持续D走入空隙。
	for i: int in 24:
		await tick(1)
		center=host.camera.get_screen_center_position()
		peak=maxf(peak,center.distance_to(last))
		last=center
	key(KEY_D,false)
	await tick(12)
	check("Real right input moves inward",host.player.global_position.x>start.x+60)
	# Position fixture scans edge-to-interior continuity separately from gameplay.
	host.player.set_physics_process(false)
	last=host.camera.get_screen_center_position()
	for x: int in range(ceili(host.player.position.x),1000,6):
		host.player.position.x=x
		await tick(1)
		center=host.camera.get_screen_center_position()
		peak=maxf(peak,center.distance_to(last))
		last=center
	check("Camera returns to centered horizontal follow",absf(host.camera.get_screen_center_position().x-host.player.global_position.x)<1)
	check("Edge-to-interior follow avoids camera jump",peak<30)
	check("Fixed gameplay zoom survives edge",host.camera.zoom==Vector2.ONE)
	host.player.position.y=host.ground_y(host.player.position.x,host.player.position.y)
	await tick(3)
	await shot("02-interior")
	var link: Dictionary=host.streaming.layout.links[0]
	host.player.set_physics_process(false)
	for point: Vector2 in [link.from,link.from.lerp(link.to,0.5),link.to]:
		host.player.global_position=point
		await tick(4)
		check("First connection keeps horizontal center "+str(point),absf(host.camera.get_screen_center_position().x-point.x)<1)
	await shot("03-cross-room")
	# 另两处世界外缘使用房内定点镜头；不是把传送夹具记成自然通关。
	for id: String in ["R5-04","R2-04","R1-06"]:
		var index: int=host.rooms.find_custom(func(room: Dictionary) -> bool: return str(room.id)==id)
		host.load_room(index)
		host.player.set_physics_process(false)
		var size: Vector2=host.point(host.room.size)
		var local: Vector2=Vector2(size.x-90,size.y*0.65) if id!="R1-06" else Vector2(size.x*0.5,40)
		host.player.position=local
		await tick(6)
		center=host.camera.get_screen_center_position()
		check(id+" exterior remains centered",center.distance_to(host.player.global_position)<1.0)
		check(id+" light tracks actual actor",host.camera.player_light.global_position.distance_to(host.player.global_position)<1.0)
		await shot("edge-"+id)
	await upper_platform()
	FileAccess.open(OUT.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failures,"peak_camera_step":peak},"\t"))
	print("CAMERA_OUTER_EDGE_COMPLETE failed=",failures," peak=",peak)
	await host.graceful_quit(1 if failures else 0)

func upper_platform() -> void:
	# Screenshot platform fixture; traversal itself uses actual key events.
	host.load_room(5,[1240,330])
	host.player.invulnerable=1000
	await tick(35)
	check("Upper platform starts grounded",host.player.is_on_floor())
	var before: Vector2=host.player.global_position
	key(KEY_A,true)
	var error: float=0.0
	for i: int in 24:
		await tick(1)
		await process_frame
		if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
		else: await create_timer(0.0).timeout
		error=maxf(error,host.camera.get_screen_center_position().distance_to(host.player.global_position))
	key(KEY_A,false)
	await tick(10)
	print("UPPER_MOVE dx=",host.player.global_position.x-before.x," camera_error=",error)
	check("Real left movement follows on screenshot platform",host.player.global_position.x<before.x-60 and error<1)
	key(KEY_SPACE,true)
	await tick(8)
	key(KEY_SPACE,false)
	check("Real jump leaves upper platform",not host.player.is_on_floor())
	await shot("04-upper-jump")
	await tick(85)
	check("Jump returns to platform with centered camera",host.player.is_on_floor() and host.camera.get_screen_center_position().distance_to(host.player.global_position)<1)
	await shot("05-upper-platform-fixed")
	var light: Node2D=host.camera.player_light
	check("Beam and halo load real bitmaps",light.get_node("Beam").texture.get_size()==Vector2(512,768) and light.get_node("Halo").texture!=null)
	check("Light is above player layer",not light.z_as_relative and light.z_index>host.player.z_index)
	if DisplayServer.get_name()!="headless":
		# Freeze scene processing so before/after pixels describe only the light.
		var previous_mode: Node.ProcessMode=root.process_mode
		root.process_mode=Node.PROCESS_MODE_DISABLED
		light.hide()
		RenderingServer.force_draw(false)
		var dark: Image=root.get_texture().get_image()
		light.show()
		RenderingServer.force_draw(false)
		var lit: Image=root.get_texture().get_image()
		var brightness: float=0.0
		for y: int in range(280,350):
			for x: int in range(610,670): brightness+=lit.get_pixel(x,y).get_luminance()-dark.get_pixel(x,y).get_luminance()
		check("GPU light visibly brightens player area",brightness/4200.0>0.01)
		root.process_mode=previous_mode
	var map: Control=host.player_ui.hud.minimap
	var original: Vector2=map.position
	map.position=Vector2(510,240)
	await tick(25)
	check("Overlapping minimap fades clear of actor",map.modulate.a<0.1)
	map.position=original
	await tick(25)
	check("Minimap restores when actor is clear",map.modulate.a>0.99)
	key(KEY_ESCAPE,true)
	for i: int in 3: await process_frame
	key(KEY_ESCAPE,false)
	for i: int in 3: await process_frame
	check("Pause opens with light fixed at actor",paused and light.global_position.distance_to(host.player.global_position)<1)
	key(KEY_ESCAPE,true)
	for i: int in 3: await process_frame
	key(KEY_ESCAPE,false)
	for i: int in 30: await process_frame
	check("Resume restores normal play",not paused and host.player.controls_enabled)
	key(KEY_F2,true)
	key(KEY_F2,false)
	await tick(4)
	check("Reference view excludes follow light",not light.visible and not host.camera.was_following)
	key(KEY_F2,true)
	key(KEY_F2,false)
	await tick(4)
	check("Gameplay restores follow and light",light.visible and host.camera.get_screen_center_position().distance_to(host.player.global_position)<1)
	await shot("06-final-follow-light")
