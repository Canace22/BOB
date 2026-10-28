extends SceneTree
const OUT="res://evidence/motion_elements/"
var scene: Node2D
var checks: Array = []
func _initialize() -> void: run.call_deferred()
func check(label: String, pass_value: bool, details: Variant=null) -> void:
	checks.append({"name":label,"pass":pass_value,"details":details})
	print("MOTION_CHECK ",label,": ",pass_value)
func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png")
func state() -> Array:
	var result: Array=[]
	for n in scene.get_children():
		if n is Sprite2D: result.append([n.position,n.frame,n.modulate,n.scale,n.flip_h])
	for b in scene.bubbles: result.append([b.node.position,b.node.modulate])
	return result
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	scene=load("res://scenes/environment/xumen_reference.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	var initial=state()
	await shot("fixed-00")
	var manifest: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tools/motion_elements/element-ids.json"))
	var missing: Array=[]
	for id: String in manifest:
		if not scene.has_node(id):missing.append(id)
	check("all_%s_element_ids_instanced"%manifest.size(),missing.is_empty(),missing)
	check("no_physics_or_controller_in_environment",scene.find_children("*","CollisionObject2D",true,false).is_empty() and scene.find_children("*","CollisionShape2D",true,false).is_empty())
	var fish := scene.get_node("FISH-02-01") as Sprite2D
	check("fish_has_12_real_bitmap_frames",fish.hframes==12 and fish.texture.get_width()==1440)
	var im := fish.texture.get_image()
	check("tail_frames_differ",im.get_region(Rect2i(0,0,120,60)).get_data()!=im.get_region(Rect2i(360,0,120,60)).get_data())
	var rigid: Dictionary={}
	for id: String in ["ROAD","ROOF","WALL-L","WALL-R","PORTAL","CHARACTER","BALEEN-03-ROOT"]:rigid[id]=scene.get_node(id).transform
	var stationary := true
	var bounded := true
	for step in range(10801):
		scene.elapsed=float(step)/60.0
		scene.update_visuals()
		for id in rigid:stationary=stationary and scene.get_node(id).transform==rigid[id]
		for b in scene.bubbles:bounded=bounded and b.bounds.grow(4).has_point(b.node.position)
	check("180s_simulation_rigid_anchors",stationary)
	check("180s_bubbles_bounded_36_instances",bounded and scene.bubbles.size()==36)
	check("bubble_recycling",scene.recycled>200,scene.recycled)
	scene.elapsed=5.0;scene.update_visuals()
	check("individual_fish_move_visible_distance",fish.position.distance_to(fish.home)>20.0,fish.position.distance_to(fish.home))
	var held=state()
	scene.animate_environment=false;scene._process(0.5)
	check("pause_holds_all_elements",state()==held)
	scene.animate_environment=true;scene._process(1.0/60.0)
	check("resume_continues_clock",scene.elapsed>5 and scene.elapsed<5.02)
	scene.motion_strength=0;held=state();scene._process(1.0)
	check("zero_speed_freezes_all",held==state())
	scene.motion_strength=1.0
	for t: float in [1.0,3.0,7.0,16.0,32.0,64.0]:
		scene.elapsed=t;scene.update_visuals();await shot("time-%02d"%int(t))
	# Verify a deterministic material loop at its uniform level and fish body frame seam.
	var foliage=scene.get_node("BALEEN-LEFT")
	check("curtain_root_is_separate_rigid_texture",scene.get_node("BALEEN-03-ROOT").texture!=foliage.texture)
	var camera := Camera2D.new();root.add_child(camera)
	camera.zoom=Vector2.ONE*1.16
	scene.level_mode=true
	for side: int in [-1,1]:
		camera.position=Vector2(640+side*65,360+side*10)
		scene.level_camera_offset=Vector2(side*65,side*10)
		scene.update_visuals();await shot("pan-"+str(side))
		check("foreground_relative_parallax_"+str(side),is_equal_approx(scene.get_node("FRONT-01").position.x,-side*65*0.14))
	camera.free()
	scene.level_mode=false;scene.level_camera_offset=Vector2.ZERO
	scene.set_process(true);paused=true
	var before: float=scene.elapsed
	await create_timer(0.1,true).timeout
	check("tree_pause_stops_clock",scene.elapsed==before)
	paused=false;await process_frame;await process_frame
	check("tree_resume_advances",scene.elapsed>before)
	scene.free()
	scene=load("res://scenes/environment/xumen_reference.tscn").instantiate();root.add_child(scene);scene.set_process(false)
	check("reload_same_prewarm",state()==initial)
	var failures: Array=checks.filter(func(c):return not c.pass)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures.size(),"note":"180s is accelerated state simulation. Video/render performance are separate evidence."},"\t"))
	quit(0 if failures.is_empty() else 1)
