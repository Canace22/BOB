extends SceneTree
const IDS=["BALEEN-LEFT","BALEEN-CENTER","BALEEN-RIGHT","BALEEN-DISTANT"]
const OUT="res://evidence/baleen_blender/"
func _initialize() -> void: run.call_deferred()
func render_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var scene=load("res://scenes/environment/xumen_reference.tscn").instantiate()
	root.add_child(scene);scene.set_process(false)
	var checks: Array=[]
	var a: Image=await render_image();a.save_png(OUT+"frame-00.png")
	for id: String in IDS:
		var n=scene.get_node(id)
		checks.append({"name":id+"_atlas_bound","pass":n.hframes==8 and n.vframes==9 and n.frame_count==72 and n.material==null,"resource":n.texture.resource_path})
		n.update_at(1.5)
		checks.append({"name":id+"_quarter_cycle_frame18","pass":n.frame==18 and n.position==n.home})
	var b: Image=await render_image();b.save_png(OUT+"frame-18.png")
	var changed_inside:=0;var changed_below:=0
	for y in range(720):
		for x in range(1280):
			if a.get_pixel(x,y)!=b.get_pixel(x,y):
				if y>=400:changed_below+=1
				else:changed_inside+=1
	checks.append({"name":"visible_curtain_motion","pass":changed_inside>500,"changed_pixels":changed_inside})
	checks.append({"name":"road_foreground_unchanged_by_curtains","pass":changed_below==0,"changed_pixels":changed_below})
	for id: String in IDS:scene.get_node(id).update_at(6.0)
	var c: Image=await render_image()
	checks.append({"name":"6s_rendered_loop_exact","pass":a.get_data()==c.get_data()})
	for i in range(1,7):checks.append({"name":"old_shader_instance_removed_%02d"%i,"pass":not scene.has_node("BALEEN-%02d"%i)})
	var failed: Array=checks.filter(func(v):return not v.pass)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed.size()},"\t"))
	print("BALEEN_RUNTIME_CHECKS ",JSON.stringify(checks))
	quit(0 if failed.is_empty() else 1)
