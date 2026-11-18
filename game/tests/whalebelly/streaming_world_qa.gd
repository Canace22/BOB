extends SceneTree
## 独立档；普通跨界使用真实按键，夹具只布置连接起点。
var host: WhalebellyMain
var failures: int = 0
var checks: Array[Dictionary] = []
var worst_step: float = 0.0
var drop_direction: float = 0.0
var drop_height: float = 0.0
const OUTPUT := "res://build/qa/streaming-world"

func _initialize() -> void: run.call_deferred()
func _process(_dt: float) -> bool:
	# 路线夹具不验暂停菜单，避免外部Esc让等待physics_frame永久挂起。
	if is_instance_valid(host) and paused:
		print("QA_RESUME_EXTERNAL_PAUSE")
		paused=false
	return false
func tick(count: int) -> void:
	for i: int in count: await physics_frame
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"pass":ok})
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func press(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(label+".png"))
func wait_ready(index: int) -> bool:
	for i: int in 900:
		if host.streaming.is_ready(index): return true
		await tick(1)
	return false
func walk(target: Vector2, budget: int = 600) -> bool:
	for i: int in budget:
		var p: WhalebellyCampaignPlayer = host.player
		var before: Vector2 = p.global_position
		var gap: Vector2 = target-before
		if i>0 and i%100==0:
			var collider: Object = p.get_slide_collision(0).get_collider() if p.get_slide_collision_count()>0 else null
			print("DRIVE_TRACE target=",target," pos=",before," velocity=",p.velocity," floor=",p.is_on_floor()," wall=",p.is_on_wall()," axis=",p.movement_axis()," state=",p.state," jumps=",p.jump_count," collider=",collider.get_path() if collider is Node else collider)
		if absf(gap.x)<48 and absf(gap.y)<40 and p.is_on_floor():
			press(KEY_A,false)
			press(KEY_D,false)
			press(KEY_SPACE,false)
			return true
		if gap.y > 40 and p.is_on_floor() and absf(gap.x)<100 and drop_direction==0:
			var support: Object = p.get_slide_collision(0).get_collider() if p.get_slide_collision_count()>0 else null
			var edge: float = before.x-support.global_position.x if support is Node2D else -p.facing
			drop_direction = signf(gap.x) if absf(gap.x)>12 else signf(edge) if absf(edge)>1 else -p.facing
			drop_height = before.y
		if drop_direction != 0 and before.y>drop_height+35: drop_direction=0
		var axis: float = drop_direction if drop_direction!=0 else signf(gap.x) if absf(gap.x)>12 else 0.0
		press(KEY_A,axis<0)
		press(KEY_D,axis>0)
		if p.is_on_floor() and (gap.y < -18 or (absf(gap.x)>30 and p.is_on_wall())):
			press(KEY_SPACE,true)
		if not p.is_on_floor() and p.velocity.y>0: press(KEY_SPACE,false)
		await tick(1)
		worst_step = maxf(worst_step,before.distance_to(host.player.global_position))
	press(KEY_A,false)
	press(KEY_D,false)
	press(KEY_SPACE,false)
	return false
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","streaming-world")
	host.qa = true
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	await tick(40)
	check("19 room origins and 18 world connections",host.streaming.layout.origins.size()==19 and host.streaming.layout.links.size()==18)
	if "--all" in OS.get_cmdline_user_args():
		await all_connections()
		await finish()
		return
	host.load_room(0)
	await tick(15)
	check("Neighbour is ready before crossing",await wait_ready(1))
	var identity: int = host.player.get_instance_id()
	var light_identity: int = host.camera.player_light.get_instance_id()
	var link: Dictionary = host.streaming.layout.links.filter(func(edge: Dictionary) -> bool: return edge.a==0 and edge.b==1)[0]
	# The exit bank starts only 116px before this door; -180 starts below a gap.
	host.player.global_position = link.from-Vector2(60,8)
	host.player.invulnerable = 100
	await tick(25)
	await shot("01-before-crossing")
	var forward: bool = await walk(link.to+Vector2(130,0),1000)
	await tick(20)
	check("Walk crosses first connection without E",forward and host.room_index==1)
	check("Same player instance survives crossing",host.player.get_instance_id()==identity)
	check("No fade or transition lock",not host.continuity.transition.active and not host.player.transition_locked)
	check("Camera uses continuous world target",host.camera.get_screen_center_position().distance_to(host.camera.follow_target(host.player.global_position))<1)
	check("Light follows across room coordinates",host.camera.player_light.global_position.distance_to(host.player.global_position)<1 and host.camera.player_light.get_instance_id()==light_identity)
	check("Physical frame displacement stays continuous",worst_step<35)
	await shot("02-after-crossing")
	check("Return room remains resident",host.streaming.is_ready(0))
	var back: bool = await walk(link.from-Vector2(110,0),1000)
	await tick(20)
	check("Walk back preserves actor",back and host.room_index==0 and host.player.get_instance_id()==identity)
	check("Return preserves light and world position",host.camera.player_light.global_position.distance_to(host.player.global_position)<1 and host.camera.player_light.get_instance_id()==light_identity)
	await shot("03-return")
	await finish()

func all_connections() -> void:
	var background: Sprite2D = host.streaming.corridors.get_node("ContinuousWater")
	var background_id: int = background.get_instance_id()
	var background_anchors: PackedVector2Array = background.material.get_shader_parameter("anchors")
	for id: String in ["dash","float","anchor","pressure","bone","silence"]: host.abilities[id]=true
	for room: Dictionary in host.rooms: host.defeated[str(room.id)+":0"]=true
	for link: Dictionary in host.streaming.layout.links:
		var filters: PackedStringArray = OS.get_cmdline_user_args()
		if "--branch" in filters and not (link.a==1 and link.b==5): continue
		if "--memory" in filters and not (link.a==1 and link.b==6): continue
		if "--tail" in filters and not (link.a==14 and link.b==18): continue
		host.load_room(int(link.a))
		await tick(15)
		check("Ready %d→%d" % [link.a,link.b],await wait_ready(int(link.b)))
		var identity: int = host.player.get_instance_id()
		host.player.global_position = link.from-Vector2(0,8)
		host.player.invulnerable=1000
		host.player.velocity=Vector2.ZERO
		await tick(20)
		var path: PackedVector2Array = PackedVector2Array(link.path).duplicate()
		var measured: Dictionary=CampaignPaintedSupports.corridor_data(host.streaming.layout,link)
		var origin: Vector2=host.streaming.origin(int(link.a))
		for i: int in path.size():
			var local: Vector2=path[i]-origin
			if CampaignPaintedSupports.replaces(measured,local):
				path[i].y=origin.y+CampaignPaintedSupports.ground_y({"painted_corridors":measured.tops},local.x,local.y,local.y,150)
		var forward: bool = true
		for point: Vector2 in path:
			drop_direction=0
			if not await walk(point,210):
				forward=false
				print("ROUTE_STOP link=",link.a,"→",link.b," world=",host.player.global_position," target=",point," room=",host.room_index)
				break
		await tick(15)
		check("Continuous route %d→%d" % [link.a,link.b],forward and host.room_index==int(link.b))
		check("Actor identity %d→%d" % [link.a,link.b],host.player.get_instance_id()==identity)
		await shot("edge-%d-%d" % [link.a,link.b])
		if not forward: continue
		var backward: bool = true
		path.reverse()
		for point: Vector2 in path:
			drop_direction=0
			if not await walk(point,210):
				backward=false
				print("ROUTE_STOP return=",link.b,"→",link.a," world=",host.player.global_position," target=",point," room=",host.room_index)
				break
		await tick(15)
		check("Continuous return %d→%d" % [link.b,link.a],backward and host.room_index==int(link.a))
		var current_background: Sprite2D = host.streaming.corridors.get_node("ContinuousWater")
		check("Fixed world backdrop %d↔%d" % [link.a,link.b],current_background.get_instance_id()==background_id and current_background.material.get_shader_parameter("anchors")==background_anchors)
		if not backward: await shot("failed-return-%d-%d" % [link.b,link.a])

func finish() -> void:
	var report := FileAccess.open(OUTPUT.path_join("report.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failed":failures,"worst_step":worst_step,"stream":host.streaming.snapshot()},"\t"))
	report.close()
	print("STREAMING_WORLD_COMPLETE failed=",failures)
	await host.graceful_quit(1 if failures else 0)
