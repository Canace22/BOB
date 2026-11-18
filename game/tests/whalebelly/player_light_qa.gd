extends SceneTree
## Native GPU sample. Room/pose fixtures; gameplay checks use actual key events.
const OUT := "res://build/qa/player-light"
var host: WhalebellyMain
var checks: Array[Dictionary] = []

func _initialize() -> void: run.call_deferred()

func tick(count: int) -> void:
	for i: int in count: await physics_frame

func rendered() -> void:
	await process_frame
	await RenderingServer.frame_post_draw

func check(label: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"name":label,"pass":ok,"detail":detail})
	print("PASS " if ok else "FAIL ",label," ",detail)

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func shot(label: String) -> Image:
	await rendered()
	var pixels := root.get_texture().get_image()
	pixels.save_png(OUT.path_join(label+".png"))
	return pixels

func difference(a: Image, b: Image, area: Rect2i) -> Dictionary:
	var total: float = 0.0
	var changed: int = 0
	for y: int in range(area.position.y,area.end.y):
		for x: int in range(area.position.x,area.end.x):
			var delta: float = absf(a.get_pixel(x,y).get_luminance()-b.get_pixel(x,y).get_luminance())
			total += delta
			if delta > 0.008: changed += 1
	return {"average":total/float(area.size.x*area.size.y),"changed":changed}

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("player_light_qa requires a GPU display")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUT.path_join("frames"))
	root.size = Vector2i(1280,720)
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","player-light")
	host.qa = true
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	await tick(25)
	host.load_room(5,[1240,330])
	host.player.invulnerable = 1000
	await tick(45)
	var light: CampaignPlayerLight = host.camera.player_light
	check("Loaded light and particle bitmaps",light.get_node("Beam").texture == CampaignPlayerLight.BEAM and light.get_node("SuspendedMotes").texture == CampaignPlayerLight.HALO)
	check("Light renders over the actor",light.z_index > host.player.z_index and not light.z_as_relative)
	check("Scattering stays behind solid terrain",light.beam_light.z_index<0 and not light.beam_light.z_as_relative and light.emitters[0].z_index<0)
	var isolated := SubViewport.new()
	isolated.size = Vector2i(360,650)
	isolated.transparent_bg = true
	isolated.world_2d = World2D.new()
	isolated.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(isolated)
	var sample := CampaignPlayerLight.new()
	isolated.add_child(sample)
	sample.position = Vector2(180,620)
	for particles: CPUParticles2D in sample.emitters:
		(particles.material as ShaderMaterial).set_shader_parameter("light_origin",sample.position)
		particles.restart()
	# Freeze the environment and actor so changed GPU pixels belong to the light.
	light.set_process(false)
	host.process_mode = Node.PROCESS_MODE_DISABLED
	light.process_mode = Node.PROCESS_MODE_ALWAYS
	for effect: ShaderMaterial in light.materials:
		effect.set_shader_parameter("effect_time",0.0)
	light.hide()
	var dark: Image = await shot("01-light-off")
	light.show()
	var lit: Image = await shot("02-scattering")
	var body: Dictionary = difference(dark,lit,Rect2i(605,275,70,75))
	check("Light visibly supports actor readability",float(body.average)>0.01,body)
	var floor_delta: Dictionary = difference(dark,lit,Rect2i(490,390,300,100))
	check("Light fades before underside of platform",float(floor_delta.average)<0.002,floor_delta)
	var hud_delta: Dictionary = difference(dark,lit,Rect2i(10,10,370,150))
	check("Lighting stays clear of the corner HUD",int(hud_delta.changed)==0,hud_delta)
	# Advance only the scattering clock; no scene animation or particle motion.
	for particles: CPUParticles2D in light.emitters: particles.speed_scale = 0.0
	for effect: ShaderMaterial in light.materials:
		effect.set_shader_parameter("effect_time",4.0)
	var moving: Image = await shot("03-flow-four-seconds")
	var flow: Dictionary = difference(lit,moving,Rect2i(500,30,280,260))
	check("Scattering has visible internal motion",int(flow.changed)>200,flow)
	# Isolate particles to verify the real renderer's world-space mask.
	light.get_node("Beam").hide()
	light.get_node("Halo").hide()
	var particles_only: Image = await shot("04-particles-only")
	var motes: Dictionary = difference(dark,particles_only,Rect2i(480,0,320,360))
	check("Actual particles are visible inside light",int(motes.changed)>8,motes)
	light.get_node("Beam").show()
	light.get_node("Halo").show()
	light.process_mode = Node.PROCESS_MODE_PAUSABLE
	host.process_mode = Node.PROCESS_MODE_ALWAYS
	light.set_process(true)
	for particles: CPUParticles2D in light.emitters: particles.speed_scale = 1.0
	await tick(2)
	key(KEY_ESCAPE,true)
	await rendered()
	key(KEY_ESCAPE,false)
	for i: int in 5: await rendered()
	var clock: float = light.effect_time
	await shot("05-paused")
	var paused_a: Image = isolated.get_texture().get_image()
	for i: int in 12: await rendered()
	var paused_b: Image = isolated.get_texture().get_image()
	check("Pause freezes light clock",paused and is_equal_approx(clock,light.effect_time))
	# Isolated GPU pixels exclude background shaders and the animated pause UI.
	var pause_pixels: Dictionary = difference(paused_a,paused_b,Rect2i(0,0,360,650))
	check("Pause freezes actual particle pixels",int(pause_pixels.changed)==0,pause_pixels)
	isolated.queue_free()
	key(KEY_ESCAPE,true)
	await rendered()
	key(KEY_ESCAPE,false)
	await tick(20)
	check("Resume restarts light without a clock jump",not paused and light.effect_time>clock and light.effect_time<clock+0.6)
	var start: Vector2 = host.player.global_position
	key(KEY_A,true)
	await tick(18)
	key(KEY_A,false)
	check("Real movement keeps light aligned",host.player.global_position.x<start.x-40 and light.global_position.distance_to(host.player.global_position)<1.0)
	key(KEY_SPACE,true)
	await tick(8)
	key(KEY_SPACE,false)
	check("Real jump preserves spotlight alignment",not host.player.is_on_floor() and light.global_position.distance_to(host.player.global_position)<1.0)
	await shot("06-jump")
	await tick(85)
	# User's screenshot room, selected by stable ID. Explicit pose fixture.
	var nursery: int = host.rooms.find_custom(func(room: Dictionary) -> bool: return str(room.id)=="R1-05")
	host.load_room(nursery,[970,380])
	host.player.invulnerable = 1000
	await tick(35)
	check("Room reload keeps light at the player",light.global_position.distance_to(host.player.global_position)<1.0)
	await shot("07-nursery")
	var count: int = light.get_child_count()
	var start_time: int = Time.get_ticks_usec()
	# Six seconds of actual GPU output, sampled at 12 fps; local evidence only.
	for frame: int in 72:
		await tick(5)
		await shot("frames/%03d"%frame)
	check("Sustained effect uses bounded instances",light.get_child_count()==count and light.emitters[0].amount+light.emitters[1].amount==68)
	print("CAPTURE wall_seconds=",float(Time.get_ticks_usec()-start_time)/1000000.0)
	key(KEY_F2,true)
	key(KEY_F2,false)
	await tick(3)
	clock = light.effect_time
	await tick(10)
	check("Reference view hides and freezes light",not light.visible and is_equal_approx(clock,light.effect_time) and light.emitters[0].speed_scale==0.0)
	key(KEY_F2,true)
	key(KEY_F2,false)
	await tick(3)
	check("Gameplay restores particle illumination",light.visible and light.emitters[0].speed_scale==1.0)
	# Separate unrecorded render timings; do not report capture throughput as FPS.
	var frame_ms: Array[float] = []
	var previous: int = Time.get_ticks_usec()
	for i: int in 150:
		await rendered()
		var now: int = Time.get_ticks_usec()
		frame_ms.append(float(now-previous)/1000.0)
		previous = now
	frame_ms.sort()
	var timing: Dictionary = {"samples":frame_ms.size(),"median_ms":frame_ms[75],"p95_ms":frame_ms[142]}
	print("UNRECORDED_RENDER ",timing)
	var failed: int = checks.filter(func(item: Dictionary) -> bool: return not item["pass"]).size()
	FileAccess.open(OUT.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"renderer":RenderingServer.get_video_adapter_name(),"unrecorded_render":timing},"\t"))
	print("PLAYER_LIGHT_COMPLETE failed=",failed)
	await host.graceful_quit(1 if failed else 0)
