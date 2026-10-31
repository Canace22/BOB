extends SceneTree
## Actual default campaign room integration; QA saves only. Full route test remains separate.
const OUT := "res://build/qa/r1-chapter-scenes/"
var host: Node2D
var checks: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func tick(frames: int) -> void:
	for frame in frames: await physics_frame

func check(label: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"id":label,"pass":passed,"detail":detail})
	print("CHAPTER_QA ",label," ",passed," ",detail)

func shot(label: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(OUT+label+".png")
	return image

func state(environment: ChapterRoomEnvironment) -> String:
	var values: Array = [environment.elapsed]
	for flex: ChapterPinnedBitmap in environment.flex_parts: values.append(flex.elapsed)
	for group: ChapterFishGroup in environment.schools:
		for fish: Sprite2D in group.sprites: values.append([fish.position,fish.frame])
	for emitter: EnvironmentBubbleEmitter in environment.emitters:
		for bubble: Dictionary in emitter.bubbles: values.append([bubble.node.position,bubble.node.modulate])
	return var_to_str(values)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	host = (load("res://content/whalebelly/main.tscn") as PackedScene).instantiate()
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(35)
	var selected: Array[int] = [1,2,3,4,5,6]
	if "--sample" in OS.get_cmdline_user_args(): selected = [1]
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--room="):
			selected = [int(argument.trim_prefix("--room=R1-"))-1]
	for index: int in selected:
		host.load_room(index)
		await tick(40)
		var id: String = host.room.id
		var environment := host.scenery.get_node_or_null("ChapterEnvironment") as ChapterRoomEnvironment
		check(id+"_scene_bound",environment != null)
		if environment == null: continue
		check(id+"_four_independent_layers",environment.has_node("Far/Surface") and environment.has_node("Middle/Surface") and environment.has_node("World/Surface") and environment.has_node("Foreground/Surface"))
		check(id+"_old_visuals_disabled",not host.scenery.get_node("Far").visible and not host.scenery.get_node("World/WorldOriginalPixels").visible)
		check(id+"_old_particles_disabled",not host.scenery.get_node("EnvironmentMotion/AmbientBubbles").visible and not host.scenery.get_node("EnvironmentMotion/DistantFish").visible)
		check(id+"_player_grounded",host.player.is_on_floor(),host.player.position)
		environment.animate_environment = false
		environment.update_at(0)
		var base := await shot(id+"-static")
		environment.update_at(1.75)
		var moved := await shot(id+"-motion")
		check(id+"_render_changes",base.get_data()!=moved.get_data())
		for part: ChapterPinnedBitmap in environment.flex_parts:
			part.update_at(0)
		paused = true
		var rested := await shot(id+"-rest")
		for part: ChapterPinnedBitmap in environment.flex_parts: part.update_at(part.period)
		var closed := await shot(id+"-flex-loop")
		check(id+"_flex_loop_pixel_identical",rested.get_data()==closed.get_data())
		if not environment.flex_parts.is_empty():
			var part := environment.flex_parts[0]
			part.update_at(part.period*.25)
			var swayed := await shot(id+"-pinned-sample")
			var transform := part.get_global_transform_with_canvas()
			var top := transform * Vector2.ZERO
			var bottom := transform * (part.texture.get_size()*Vector2(1,.16))
			var area := Rect2i(Vector2i(top),Vector2i(bottom-top)).intersection(Rect2i(Vector2i.ZERO,swayed.get_size()))
			var root_changes := 0
			for y in range(area.position.y,area.end.y):
				for x in range(area.position.x,area.end.x):
					if swayed.get_pixel(x,y)!=closed.get_pixel(x,y): root_changes += 1
			check(id+"_root_pixels_fixed",root_changes==0,root_changes)
			check(id+"_mesh_visibly_bends",swayed.get_data()!=closed.get_data())
		paused = false
		environment.animate_environment = true
		await tick(12)
		var held := state(environment)
		paused = true
		await create_timer(.18,true).timeout
		check(id+"_pause_holds",held==state(environment))
		paused = false
		await tick(10)
		check(id+"_resume_advances",held!=state(environment))
		environment.motion_strength = 0
		await tick(2)
		held = state(environment)
		await tick(12)
		check(id+"_zero_speed_holds",held==state(environment))
		environment.motion_strength = 1
		var counts := environment.content_counts()
		for emitter: EnvironmentBubbleEmitter in environment.emitters: emitter.update_at(180)
		check(id+"_population_bounded",counts==environment.content_counts(),counts)
		var start: Vector2 = host.player.position
		Input.action_press("tp_right")
		await tick(18)
		Input.action_release("tp_right")
		check(id+"_walk",host.player.position.x>start.x+10)
		Input.action_press("tp_jump")
		await tick(8)
		Input.action_release("tp_jump")
		check(id+"_jump",not host.player.is_on_floor())
		await tick(80)
		host.zoomed = true
		host.set_process(false)
		var original_camera: Vector2 = host.camera.position
		var original_zoom: Vector2 = host.camera.zoom
		host.camera.zoom = Vector2.ONE
		for direction: int in [-1,1]:
			host.camera.position = Vector2(668 if direction<0 else float(host.room.size[0])-668,float(host.room.size[1])*.5)
			environment.set_camera_offset(Vector2(direction*6,direction*4))
			await shot(id+"-edge-"+str(direction))
		host.camera.position = original_camera
		host.camera.zoom = original_zoom
		host.set_process(true)
		host.zoomed = false
		host.load_room(0)
		await tick(5)
		host.load_room(index)
		await tick(5)
		environment = host.scenery.get_node("ChapterEnvironment")
		check(id+"_reload_counts",environment.content_counts()==counts)
		check(id+"_door_metadata_retained",host.room.doors.size()>0)
	var failed: Array[Dictionary] = checks.filter(func(item: Dictionary) -> bool: return not item.pass)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed.size(),"note":"GPU room loading and real controller input; explicit room load tests do not prove connected traversal"},"\t"))
	print("CHAPTER_COMPLETE checks=",checks.size()," failed=",failed.size())
	await host.graceful_quit(0 if failed.is_empty() else 1)
