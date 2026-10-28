extends SceneTree
const OUT="res://evidence/foreground_edges/"
var checks:Array=[]
var scene:Node2D
func _initialize()->void:run.call_deferred()
func check(id:String,ok:bool,detail:Variant=null)->void:checks.append({"name":id,"pass":ok,"detail":detail})
func shot(name:String)->Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var im=root.get_texture().get_image();im.save_png(OUT+name+".png");return im
func run()->void:
	scene=load("res://scenes/environment/xumen_reference.tscn").instantiate();root.add_child(scene);scene.set_process(false);scene.level_mode=true
	var camera=Camera2D.new();root.add_child(camera);camera.position=Vector2(640,360)
	if not scene.has_node("FRONT-TOP-LEFT"):
		await shot("before");quit();return
	var names=["FRONT-01","FRONT-TOP-LEFT","FRONT-BOTTOM-RIGHT"]
	var base:Dictionary={}
	for name in names:
		var node=scene.get_node(name);base[name]=node.position
		check(name+"_foreground_and_same_motion",node.z_index>=50 and is_equal_approx(node.parallax_amount,-0.14))
	check("backing_behind_player",scene.get_node("FOREGROUND-CORNER-BACKING").z_index==-1)
	await shot("fixed")
	# Show only the three extracted images against the viewport clear color.
	var visibility:Dictionary={}
	for node in scene.get_children():
		if node is CanvasItem:visibility[node]=node.visible;node.visible=str(node.name) in names
	await shot("isolated")
	for node in visibility:node.visible=visibility[node]
	for name in names:scene.get_node(name).visible=false
	await shot("backing_revealed")
	for name in names:scene.get_node(name).visible=true
	for side in [-1,0,1]:
		# Match the main map's 1671/1280 art scale and its source-space camera offsets.
		camera.zoom=Vector2.ONE*(1671.0/1280.0);camera.position=Vector2(640+side*128,360+side*18)
		scene.level_camera_offset=Vector2(side*128,side*18);scene.update_visuals()
		for name in names:check(name+"_pan_"+str(side),scene.get_node(name).position.is_equal_approx(base[name]+scene.level_camera_offset*-0.14))
		await shot("pan_"+str(side))
	# Full view at maximum relative parallax, used to check padded outer edges separately.
	camera.zoom=Vector2.ONE;camera.position=Vector2(640,360)
	await shot("edge_stress")
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://../../assets/source/xumen-foreground-edges/manifest.json"))
	for row in manifest.cleaned_static_layers:
		check(row.node+"_clean_asset_bound",scene.get_node(row.node).texture.resource_path==row.path)
	var missing=[]
	for id in JSON.parse_string(FileAccess.get_file_as_string("res://tools/motion_elements/element-ids.json")):
		if not scene.has_node(id):missing.append(id)
	check("all_manifest_ids_instanced",missing.is_empty(),missing)
	var fails=checks.filter(func(c):return not c.pass)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":fails.size()},"\t"))
	print("FOREGROUND_QA failures=",fails.size());quit(0 if fails.is_empty() else 1)
