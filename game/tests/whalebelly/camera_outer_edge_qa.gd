extends SceneTree
## 独立QA档；固定出生点后用真实键事件向内走，检查实际视口中心与外边缘。
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
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))
func key(code: Key, down: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","camera-outer-edge")
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(30)
	host.player.position=Vector2(120,host.ground_y(120,600)-2)
	host.player.invulnerable=1000
	await tick(25)
	var half: Vector2=root.get_visible_rect().size*0.5
	var center: Vector2=host.camera.get_screen_center_position()
	check("Left world border stays outside the viewport",center.x-half.x>=-1.0)
	check("Actor is left of center at outer bank",host.player.global_position.x<center.x-100)
	check("Actual screen center matches world target",center.distance_to(host.camera.follow_target(host.player.global_position))<1.0)
	await shot("01-left-edge")
	var start: Vector2=host.player.global_position
	var last: Vector2=center
	var peak: float=0.0
	key(KEY_D,true)
	for i: int in 160:
		await tick(1)
		center=host.camera.get_screen_center_position()
		peak=maxf(peak,center.distance_to(last))
		last=center
	key(KEY_D,false)
	await tick(12)
	check("Real right input moves inward",host.player.global_position.x>start.x+400)
	check("Camera returns to centered horizontal follow",absf(host.camera.get_screen_center_position().x-host.player.global_position.x)<1)
	check("Soft edge transition avoids camera jump",peak<30)
	check("Fixed gameplay zoom survives edge",host.camera.zoom==Vector2.ONE)
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
		var origin: Vector2=host.streaming.origin(index)
		var local: Vector2=Vector2(size.x-90,size.y*0.65) if id!="R1-06" else Vector2(size.x*0.5,40)
		host.player.position=local
		await tick(6)
		center=host.camera.get_screen_center_position()
		if id=="R1-06": check("Upper branch top stays outside viewport",center.y-half.y>=origin.y-1)
		else: check(id+" closed right end stays outside viewport",center.x+half.x<=origin.x+size.x+1)
		check(id+" actor stays inside viewport",absf(center.x-host.player.global_position.x)<=half.x and absf(center.y-host.player.global_position.y)<=half.y)
		await shot("edge-"+id)
	FileAccess.open(OUT.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failures,"peak_camera_step":peak},"\t"))
	print("CAMERA_OUTER_EDGE_COMPLETE failed=",failures," peak=",peak)
	await host.graceful_quit(1 if failures else 0)
