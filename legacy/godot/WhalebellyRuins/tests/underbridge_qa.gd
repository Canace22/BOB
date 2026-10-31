extends SceneTree
const OUT="res://evidence/underbridge/"
var checks:Array=[]
func _initialize()->void:run.call_deferred()
func check(id:String,ok:bool,detail:Variant=null)->void:checks.append({"name":id,"pass":ok,"detail":detail})
func shot(name:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run()->void:
	var scene=load("res://scenes/environment/xumen_reference.tscn").instantiate();root.add_child(scene);scene.set_process(false);scene.level_mode=true
	var camera=Camera2D.new();root.add_child(camera);camera.position=Vector2(640,360);camera.zoom=Vector2.ONE*1.16
	await shot("after")
	check("56_bubbles_instanced",scene.bubbles.size()==56,scene.bubbles.size())
	check("repaired_backing_bound",scene.get_node("FOREGROUND-BACKING").texture.resource_path.ends_with("FOREGROUND-BACKING-SOFT.png"))
	check("original_underside_restored",scene.get_node("ROAD").texture.resource_path.ends_with("ROAD-UNDERSIDE-RESTORED.png"))
	for name in ["BUBBLE-ZONE-05","BUBBLE-ZONE-06","BUBBLE-ZONE-07"]:
		var emitter=scene.get_node(name);var positions=[]
		for bubble in emitter.bubbles:positions.append(bubble.node.position)
		emitter.update_at(3.0);var moving=0;var visible_count=0
		for i in emitter.bubbles.size():
			if emitter.bubbles[i].node.position.distance_to(positions[i])>20:moving+=1
			if emitter.bubbles[i].node.modulate.a>0.15:visible_count+=1
		check(name+"_moves_and_visible",moving==emitter.population and visible_count>=3,[moving,visible_count])
		check(name+"_behind_road",emitter.z_index<scene.get_node("ROAD").z_index and not emitter.near_layer)
	var bounded=true
	for step in 10801:
		scene.elapsed=float(step)/60.0;scene.update_visuals()
		for b in scene.bubbles:bounded=bounded and b.bounds.grow(4).has_point(b.node.position)
	check("180s_bounded_fixed_population",bounded and scene.bubbles.size()==56)
	check("bubble_recycling_active",scene.recycled>300,scene.recycled)
	scene.elapsed=6;scene.update_visuals();await shot("after_6s")
	for node in scene.get_children():
		if str(node.name).begins_with("BUBBLE"):node.visible=false
	await shot("repair_without_bubbles")
	for node in scene.get_children():
		if str(node.name).begins_with("BUBBLE"):node.visible=true
	for side in [-1,1]:
		camera.zoom=Vector2.ONE*(1671.0/1280.0);camera.position=Vector2(640+side*128,360)
		scene.level_camera_offset=Vector2(side*128,0);scene.update_visuals();await shot("pan_"+str(side))
	var failures=checks.filter(func(c):return not c.pass)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures.size()},"\t"))
	print("UNDERBRIDGE_QA ",JSON.stringify(checks));quit(0 if failures.is_empty() else 1)
