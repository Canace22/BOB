extends SceneTree
## Real action input in the main scene; isolated QA save. No player teleport during walking.
var host: WhalebellyMain
var failures: int = 0
var unsupported: int = 0
var max_error: float = 0.0
var samples: Array = []
const OUTPUT := "res://build/qa/ground-contact/"

func _initialize() -> void: run.call_deferred()
func tick(n: int) -> void:
	for i in n: await physics_frame
func check(label: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(OUTPUT+label+".png")
func walk(target: float) -> void:
	var p: WhalebellyCampaignPlayer = host.player
	var direction: float = signf(target-p.position.x)
	var action: String = "tp_right" if direction>0 else "tp_left"
	Input.action_press(action)
	for i in 600:
		await tick(1)
		if not p.is_on_floor(): unsupported += 1
		max_error=maxf(max_error,absf(p.position.y-host.ground_y(p.position.x,p.position.y)))
		samples.append([p.position.x,p.position.y,p.is_on_floor(),p.run_visual.current_key])
		if (p.position.x-target)*direction>=0: break
	Input.action_release(action)
	await tick(25)
	check("walk_%s" % target,absf(p.position.x-target)<30 and p.is_on_floor())

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(45)
	host.player.automatic_doors=false
	await walk(110)
	await walk(950)
	await shot("right-slope")
	var start_y: float = host.player.position.y
	Input.action_press("tp_jump")
	await tick(12)
	Input.action_release("tp_jump")
	check("jump_leaves_slope",not host.player.is_on_floor() and host.player.position.y<start_y-40)
	await tick(100)
	check("jump_lands_on_painted_slope",host.player.is_on_floor() and absf(host.player.position.y-start_y)<4)
	await walk(1580)
	await walk(850)
	await shot("crest-return")
	await walk(420)
	await shot("left-approach")
	await walk(110)
	# A rounded capsule lifts its bottom above the vertical surface sample on steep slopes.
	var radius: float = host.player.collision_size.x*0.5
	var slope_clearance: float = radius*(1.0/cos(host.player.floor_max_angle)-1.0)+0.1
	check("both_directions_stay_grounded",unsupported==0 and max_error<slope_clearance)
	# Old V6 height is deliberately below the corrected crest; loading must project it.
	host.load_room(0,[971.0,557.0])
	await tick(40)
	check("old_checkpoint_projects_to_new_surface",host.player.is_on_floor() and absf(host.player.position.y-host.ground_y(971,557))<4)
	FileAccess.open(OUTPUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"unsupported_frames":unsupported,"max_ground_error":max_error,"samples":samples}))
	print("GROUND_CONTACT_COMPLETE failed=",failures," unsupported=",unsupported," error=",max_error)
	await host.graceful_quit(1 if failures else 0)
