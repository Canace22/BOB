@warning_ignore_start("untyped_declaration")
extends SceneTree
const IDS=["BALEEN-LEFT","BALEEN-CENTER","BALEEN-RIGHT","BALEEN-DISTANT"]
const OUT="res://build/qa/whalebelly/evidence/baleen_wan22/"
var checks:Array=[]
func _initialize()->void:run.call_deferred()
func check(id:String,ok:bool,detail:Variant=null)->void:
	checks.append({"id":id,"pass":ok,"detail":detail})
func capture(name:String)->Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var im=root.get_texture().get_image();im.save_png(OUT+name+".png");return im
func run()->void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var scene=load("res://content/whalebelly/environment/xumen_reference.tscn").instantiate();root.add_child(scene);scene.set_process(false)
	var initial=await capture("frame-00")
	for id in IDS:
		var n=scene.get_node(id)
		check(id+"_bound",n.texture.resource_path.begins_with("res://art/whalebelly/baleen_wan22/") and n.frame_count==36 and n.playback_fps==12 and n.hframes==6 and n.vframes==6)
		n.update_at(1.0/12.0-0.00001);check(id+"_holds_until_next_tick",n.frame==0)
		n.update_at(1.0/12.0);check(id+"_12fps_tick",n.frame==1)
		n.update_at(1.5);check(id+"_frame18_root_anchor",n.frame==18 and n.position==n.home)
	var moved=await capture("frame-18")
	var inside=0;var outside=0
	for y in 720:
		for x in 1280:
			if initial.get_pixel(x,y)!=moved.get_pixel(x,y):
				if y>=400:outside+=1
				else:inside+=1
	check("curtains_visibly_change",inside>500,inside)
	check("bridge_and_foreground_unchanged",outside==0,outside)
	for id in IDS:scene.get_node(id).update_at(6.0)
	var twice=await capture("two-loops")
	check("two_3s_cycles_return",initial.get_data()==twice.get_data())
	for t in [0.5,1.0,2.0,2.5,2.916667]:
		for id in IDS:scene.get_node(id).update_at(t)
		await capture("sample-"+str(t))
	var camera=Camera2D.new();root.add_child(camera);camera.zoom=Vector2.ONE*(1671.0/1280.0);scene.level_mode=true
	for side in [-1,1]:
		camera.position=Vector2(640+side*128,360);scene.level_camera_offset=Vector2(side*128,0);scene.update_visuals();await capture("pan-"+str(side))
	var failed=checks.filter(func(c):return not c.pass)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed.size()},"\t"))
	print("WAN_BALEEN_QA ",JSON.stringify(checks));quit(0 if failed.is_empty() else 1)
