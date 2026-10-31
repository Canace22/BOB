extends SceneTree
var out: String = "res://evidence/fish_schools_main/"
var host: Node2D
var checks: Array = []
func _initialize() -> void: run.call_deferred()
func tick(n: int) -> void:
	for i in n: await physics_frame
func check(id: String, ok: bool) -> void:
	checks.append({"id":id,"pass":ok})
func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+label+".png")
func states(env: Node) -> Array:
	var values: Array = []
	for i in [1,2,3]:
		for fish in env.get_node("FISH-SCHOOL-%02d" % i).sprites:
			values.append([fish.position,fish.frame,fish.scale,fish.modulate])
	return values
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fish-out="): out=arg.trim_prefix("--fish-out=").trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(out)
	host=load("res://scenes/main.tscn").instantiate()
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(45)
	var env: Node2D=host.scenery.get_node("ReferenceEnvironment")
	check("three_schools_62_fish",states(env).size()==62)
	check("legacy_instances_removed",not env.has_node("FISH-02-01") and not env.has_node("FISH-03-01"))
	check("environment_owns_clock",not env.get_node("FISH-SCHOOL-01").autoplay)
	check("single_player_retained",not env.has_node("CHARACTER"))
	var start: Array=states(env)
	await tick(25)
	check("fish_move_and_animate",start!=states(env))
	var held: Array=states(env)
	paused=true
	await create_timer(0.25,true).timeout
	check("scene_pause_freezes_fish",held==states(env))
	paused=false
	await tick(12)
	check("resume_continues_fish",held!=states(env))
	env.motion_strength=0.0
	await tick(2)
	held=states(env)
	await tick(15)
	check("zero_speed_holds_fish",held==states(env))
	env.motion_strength=1.0
	var actor_start: Vector2=host.player.position
	Input.action_press("tp_right")
	await tick(90)
	Input.action_release("tp_right")
	await tick(8)
	check("player_walks",host.player.position.x>actor_start.x+100.0)
	await shot("walk-camera")
	var y: float=host.player.position.y
	Input.action_press("tp_jump")
	await tick(12)
	Input.action_release("tp_jump")
	check("player_jumps",host.player.position.y<y-20.0)
	await shot("jump-camera")
	await tick(90)
	# Verify real camera offset is applied once at the intended far-water depth.
	env.set_process(false)
	var group: Node2D=env.get_node("FISH-SCHOOL-01")
	group.update_at(8.0,Vector2.ZERO)
	var base: Vector2=group.sprites[0].position
	group.update_at(8.0,Vector2(100.0,10.0))
	check("parallax_offset_correct",group.sprites[0].position.distance_to(base+Vector2(4.5,0.45))<0.001)
	group.update_at(0.0)
	check("loop_recycle_hidden",is_zero_approx(group.sprites[0].modulate.a))
	env.elapsed=8.0
	env.update_visuals()
	host.reference_follow=false
	await tick(3)
	await shot("full-room")
	env.set_process(true)
	host.load_room(1)
	await tick(30)
	check("other_room_unchanged",not host.scenery.has_node("ReferenceEnvironment"))
	host.load_room(0)
	await tick(30)
	env=host.scenery.get_node("ReferenceEnvironment")
	check("return_has_exactly_62_fish",states(env).size()==62)
	check("all_three_atlases_loaded",env.get_node("FISH-SCHOOL-03").sprites[0].texture.get_width()==2560)
	await shot("return")
	var failed: Array=checks.filter(func(c):return not c.pass)
	FileAccess.open(out+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed.size(),"scope":"actual main scene, walk/jump/camera/pause, explicit room load-return; no user save modified"},"\t"))
	print("FISH_MAIN ",JSON.stringify(checks))
	host.release_controls()
	await host.graceful_quit(0 if failed.is_empty() else 1)
