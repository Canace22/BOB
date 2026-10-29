extends SceneTree
## Rendered, current-controller integration tests; QA mode avoids player saves.
const IDS = ["BALEEN-LEFT", "BALEEN-CENTER", "BALEEN-RIGHT"]
var out: String = "res://evidence/baleen_loop_v3/"
var mode: String = "environment"
var checks: Array = []
var host: Node2D

func _initialize() -> void: run.call_deferred()
func check(id: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"id":id, "pass":ok, "detail":detail})
func tick(n: int) -> void:
	for i in n: await physics_frame
func shot(label: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var im: Image = root.get_texture().get_image()
	im.save_png(out + label + ".png")
	return im
func frames(env: Node) -> Array:
	var result: Array = []
	for id in IDS: result.append(env.get_node(id).frame)
	return result
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--baleen-mode="): mode = arg.trim_prefix("--baleen-mode=")
		if arg.begins_with("--baleen-out="): out = arg.trim_prefix("--baleen-out=").trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(out)
	if mode == "main": await main_test()
	else: await environment_test()
	var failed: Array = checks.filter(func(c): return not c.pass)
	FileAccess.open(out + mode + "-checks.json", FileAccess.WRITE).store_string(JSON.stringify({"checks":checks, "failures":failed.size(), "engine":Engine.get_version_info().string, "renderer":RenderingServer.get_video_adapter_name(), "scope":"three near baleen replacements; original blue distant pillar retained; main tests use explicit load_room, not doorway traversal"}, "\t"))
	print("BALEEN_V3_", mode.to_upper(), " ", JSON.stringify(checks))
	if is_instance_valid(host):
		host.release_controls()
		await host.graceful_quit(0 if failed.is_empty() else 1)
	else: quit(0 if failed.is_empty() else 1)
func environment_test() -> void:
	var env: Node2D = load("res://scenes/environment/xumen_reference.tscn").instantiate()
	root.add_child(env)
	env.set_process(false)
	env.elapsed = 0.0
	env.update_visuals()
	if mode == "baseline":
		await shot("before-fixed")
		check("baseline_rendered", true)
		return
	var original: Image = await shot("after-fixed")
	var home: Dictionary = {}
	for id in IDS:
		var n: Sprite2D = env.get_node(id)
		home[id] = n.transform
		check(id + "_new_atlas", n.texture.resource_path == "res://assets/baleen_loop_v3/baleen-sway-atlas.png")
		check(id + "_48_frames_12fps", n.frame_count == 48 and n.playback_fps == 12.0 and n.period == 4.0 and n.hframes == 8 and n.vframes == 6)
		check(id + "_uniform_scale", is_equal_approx(n.scale.x, n.scale.y))
		var initial: int = n.frame
		n.update_at(1.0/12.0 - 0.00001)
		check(id + "_holds_frame", n.frame == initial)
		n.update_at(1.0/12.0)
		check(id + "_ticks_at_12fps", n.frame == (initial + 1) % 48)
		n.update_at(0.0)
	check("three_distinct_phases", frames(env) == [0,13,29], frames(env))
	check("original_distant_pillar_retained", env.get_node("BALEEN-DISTANT").texture.resource_path == "res://assets/baleen_wan22/BALEEN-DISTANT.png")
	# Freeze everything except the three new elements to isolate visual change.
	for id in IDS: env.get_node(id).update_at(1.5)
	var moved: Image = await shot("after-phase-18")
	var top_changed: int = 0
	var lower_changed: int = 0
	for y in 720:
		for x in 1280:
			if original.get_pixel(x,y) != moved.get_pixel(x,y):
				if y < 365: top_changed += 1
				else: lower_changed += 1
	check("three_curtains_visibly_animate", top_changed > 500, top_changed)
	check("road_and_foreground_unmodified", lower_changed == 0, lower_changed)
	for t in [0.0, 0.5, 1.0, 2.0, 3.0, 3.916667]:
		for id in IDS: env.get_node(id).update_at(t)
		await shot("phase-" + str(t))
	for id in IDS: env.get_node(id).update_at(8.0)
	var closed: Image = await shot("after-two-cycles")
	check("two_cycles_identical_render", original.get_data() == closed.get_data())
	for id in IDS: check(id + "_attachment_stable", env.get_node(id).transform == home[id])
	var camera := Camera2D.new()
	root.add_child(camera)
	camera.zoom = Vector2.ONE * (1671.0/1280.0)
	env.level_mode = true
	for side in [-1,1]:
		camera.position = Vector2(640 + side * 128,360)
		env.level_camera_offset = Vector2(side*128,0)
		env.update_visuals()
		await shot("pan-" + str(side))
func main_test() -> void:
	host = load("res://scenes/main.tscn").instantiate()
	host.qa = true
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(45)
	var env: Node2D = host.scenery.get_node("ReferenceEnvironment")
	for id in IDS:
		check(id + "_main_binding", env.get_node(id).texture.resource_path == "res://assets/baleen_loop_v3/baleen-sway-atlas.png")
	check("single_gameplay_player", not env.has_node("CHARACTER"))
	var held: Array = frames(env)
	await tick(20)
	check("main_animation_advances", held != frames(env))
	held = frames(env)
	var elapsed: float = env.elapsed
	paused = true
	await create_timer(.25,true).timeout
	check("tree_pause_holds_frames_and_clock", held == frames(env) and elapsed == env.elapsed)
	paused = false
	await tick(12)
	check("resume_continues_clock", env.elapsed > elapsed)
	env.animate_environment = false
	await tick(2)
	held = frames(env)
	await tick(20)
	check("environment_toggle_holds_pose", held == frames(env))
	env.animate_environment = true
	env.motion_strength = 0.0
	await tick(2)
	held = frames(env)
	await tick(20)
	check("zero_speed_holds_pose", held == frames(env))
	env.motion_strength = 1.0
	var start: Vector2 = host.player.position
	Input.action_press("tp_right")
	await tick(90)
	Input.action_release("tp_right")
	await tick(8)
	check("existing_controller_walks", host.player.position.x > start.x + 100)
	await shot("main-walk")
	var y: float = host.player.position.y
	Input.action_press("tp_jump")
	await tick(12)
	Input.action_release("tp_jump")
	check("existing_controller_jumps", host.player.position.y < y - 20)
	await shot("main-jump")
	await tick(90)
	host.reference_follow = false
	await tick(3)
	await shot("main-full-room")
	host.load_room(1)
	await tick(25)
	check("other_room_unchanged", not host.scenery.has_node("ReferenceEnvironment"))
	host.load_room(0)
	await tick(25)
	env = host.scenery.get_node("ReferenceEnvironment")
	check("return_reloads_new_animation", env.get_node("BALEEN-LEFT").frame_count == 48)
	check("new_fish_schools_preserved", env.has_node("FISH-SCHOOL-01") and env.get_node("FISH-SCHOOL-01").sprites.size() == 28)
	await shot("main-return")
