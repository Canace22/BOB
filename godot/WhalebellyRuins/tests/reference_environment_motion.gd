extends SceneTree
## Deterministic state checks plus real renderer snapshots; never loads gameplay saves.
const OUTPUT = "res://evidence/reference_environment/motion_refinement/"
var checks: Array[Dictionary] = []
var scene: Node2D

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"pass":passed})
	print(label, ": ", passed)

func snapshot() -> Array:
	var result: Array = []
	for child in scene.get_children():
		if child is Sprite2D: result.append([child.position,child.modulate])
	for bubble in scene.bubbles: result.append([bubble.node.position,bubble.node.modulate])
	return result

func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT+label+".png")

func run() -> void:
	scene=load("res://scenes/environment/xumen_reference.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	var baseline=snapshot()
	await shot("refined-00")
	var stable: Dictionary={}
	for id in ["ROAD","ROOF","WALL-L","WALL-R","PORTAL","CHARACTER","FRONT-01","FRONT-03"]:
		stable[id]=scene.get_node(id).transform
	var stable_ok=true
	var bounds_ok=true
	for step in range(10801):
		scene.elapsed=float(step)/60.0
		scene.update_visuals()
		for id in stable:
			stable_ok=stable_ok and scene.get_node(id).transform==stable[id]
		for bubble in scene.bubbles:
			bounds_ok=bounds_ok and bubble.bounds.grow(4.0).has_point(bubble.node.position)
	check("180s_structures_and_character_anchored",stable_ok)
	check("180s_bubbles_remain_in_bounds",bounds_ok)
	check("bounded_population_and_recycling",scene.bubbles.size()==36 and scene.recycled>100)
	scene.elapsed=7.0
	scene.update_visuals()
	var moving=snapshot()
	scene.animate_environment=false
	scene._process(0.75)
	check("disable_animation_holds_pose",snapshot()==moving and scene.elapsed==7.0)
	scene.animate_environment=true
	scene._process(1.0/60.0)
	check("resume_advances_without_reset",scene.elapsed>7.0 and scene.elapsed<7.02)
	scene.motion_strength=0.0
	var held=snapshot()
	scene._process(1.0)
	check("zero_strength_freezes_all_motion",snapshot()==held)
	scene.motion_strength=1.0
	for t in [2.0,5.0,11.0]:
		scene.elapsed=t
		scene.update_visuals()
		await shot("refined-%02d"%int(t))
	# Verify the host tree's pause behavior, not just the inspector switch.
	scene.set_process(true)
	paused=true
	var before_pause=scene.elapsed
	await create_timer(0.1,true).timeout
	check("tree_pause_stops_clock",scene.elapsed==before_pause)
	paused=false
	await process_frame
	await process_frame
	check("tree_resume_advances_clock",scene.elapsed>before_pause)
	scene.set_process(false)
	scene.free()
	scene=load("res://scenes/environment/xumen_reference.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	check("reload_has_same_prewarmed_distribution",snapshot()==baseline)
	var failed=checks.filter(func(c): return not c.pass)
	FileAccess.open(OUTPUT+"motion-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed.size(),"simulation_seconds":180,"note":"Snapshots inspected separately; simulation is not a 180-second visual recording."},"\t"))
	quit(0 if failed.is_empty() else 1)
