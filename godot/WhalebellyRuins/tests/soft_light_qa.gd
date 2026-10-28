extends SceneTree
const OUT="res://evidence/soft_light/"
var checks:Array=[]
func _initialize() -> void:run.call_deferred()
func check(id:String,ok:bool,detail:Variant=null) -> void:
	checks.append({"name":id,"pass":ok,"detail":detail})
func shot(name:String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var img=root.get_texture().get_image()
	img.save_png(OUT+name+".png")
	return img
func run() -> void:
	var scene=load("res://scenes/environment/xumen_reference.tscn").instantiate()
	root.add_child(scene);scene.set_process(false);scene.level_mode=true
	var camera=Camera2D.new();root.add_child(camera)
	camera.position=Vector2(640,360)
	var lights=[]
	for id in ["BEAM-01","BEAM-02","BEAM-03"]:
		var light=scene.get_node(id);lights.append(light)
		check(id+"_uses_independent_light",light.texture.resource_path=="res://assets/soft_light/UNDERWATER-SOFT-LIGHT.png" and light.z_index==-54)
	check("background_restored",scene.get_node("ENV-DEPTH").texture.resource_path.ends_with("ENV-DEPTH-RESTORED.png"))
	var img=lights[0].texture.get_image()
	var edge=0.0
	for x in img.get_width():edge=maxf(edge,maxf(img.get_pixel(x,0).a,img.get_pixel(x,img.get_height()-1).a))
	for y in img.get_height():edge=maxf(edge,maxf(img.get_pixel(0,y).a,img.get_pixel(img.get_width()-1,y).a))
	check("fully_transparent_texture_boundary",edge==0.0,edge)
	var initial=await shot("fixed")
	for light in lights:light.update_at(3)
	var moving=await shot("light_t3")
	var changed=0
	for y in 720:
		for x in 1280:
			if initial.get_pixel(x,y)!=moving.get_pixel(x,y):changed+=1
	check("light_animation_visible",changed>300,changed)
	for light in lights:light.update_at(12)
	var loop=await shot("loop12")
	check("12_second_rendered_loop",loop.get_data()==initial.get_data())
	for side in [-1,0,1]:
		camera.zoom=Vector2.ONE*1.28;camera.position=Vector2(640+side*128,310)
		scene.level_camera_offset=Vector2(side*128,0);scene.update_visuals()
		var before=[]
		for light in lights:before.append(light.transform)
		await shot("after_%s"%side)
		for light in lights:light.visible=false
		await shot("new_lights_hidden_%s"%side)
		for i in lights.size():
			lights[i].visible=true
			check("camera_%s_keeps_light_geometry_%s"%[side,i],lights[i].transform==before[i])
	# Isolated light over viewport clear color, with no sampled environment geometry.
	for child in scene.get_children():
		if child is CanvasItem:child.visible=child in lights
	camera.zoom=Vector2.ONE;camera.position=Vector2(640,360)
	await shot("light_only")
	var failures=checks.filter(func(c):return not c.pass)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures.size()},"\t"))
	print("SOFT_LIGHT_QA ",JSON.stringify(checks))
	quit(0 if failures.is_empty() else 1)
