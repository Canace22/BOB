extends SceneTree
const OUT="res://evidence/motion_elements/water-surface/"
func _initialize() -> void: run.call_deferred()
func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	var scene=load("res://scenes/environment/xumen_reference.tscn").instantiate()
	root.add_child(scene);scene.set_process(false)
	var water=scene.get_node("WATER-SURFACE")
	var before: Image=await frame_image()
	before.save_png(OUT+"water-00.png")
	water.update_at(3.0)
	var after: Image=await frame_image()
	after.save_png(OUT+"water-03.png")
	var top_changed:=0
	var outside_changed:=0
	var ivory_changed:=0
	var translucent_edge_changed:=0
	var opaque_baleen:=PackedByteArray()
	opaque_baleen.resize(1280*720)
	for child in scene.get_children():
		if not str(child.name).begins_with("BALEEN"):continue
		var mask: Image=child.texture.get_image()
		for yy in range(mask.get_height()):
			for xx in range(mask.get_width()):
				var pos:=Vector2i(child.position)+Vector2i(xx,yy)
				if Rect2i(0,0,1280,720).has_point(pos) and mask.get_pixel(xx,yy).a>=0.995:opaque_baleen[pos.y*1280+pos.x]=1
	for y in range(720):
		for x in range(1280):
			var a:=before.get_pixel(x,y);var b:=after.get_pixel(x,y)
			var d:=maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
			if d<=2.0/255.0:continue
			if Rect2i(350,0,740,150).has_point(Vector2i(x,y)):top_changed+=1
			else:outside_changed+=1
			if opaque_baleen[y*1280+x]==1:ivory_changed+=1
			elif a.r>0.65 and a.r>a.b*0.98:translucent_edge_changed+=1
	water.update_at(10.0)
	var loop: Image=await frame_image()
	var d0:=before.get_data();var d1:=loop.get_data();var max_diff:=0
	for i in range(d0.size()):max_diff=maxi(max_diff,absi(int(d0[i])-int(d1[i])))
	var checks: Array=[
		{"name":"painted_upper_water_changes","pass":top_changed>100,"pixels":top_changed},
		{"name":"no_changes_outside_water_rect","pass":outside_changed==0,"pixels":outside_changed},
		{"name":"opaque_baleen_occludes_water","pass":ivory_changed==0,"pixels":ivory_changed,"translucent_edge_pixels_showing_background":translucent_edge_changed},
		{"name":"behind_midground_and_curtains","pass":water.z_index<scene.get_node("MID-01").z_index and water.z_index<scene.get_node("BALEEN-03").z_index},
		{"name":"floating_caustic_instances_removed","pass":not scene.has_node("CAUSTIC-01") and not scene.has_node("CAUSTIC-02")},
		{"name":"10s_rendered_loop","pass":max_diff<=2,"maximum_channel_error":max_diff}
	]
	scene.elapsed=3.0;scene.update_visuals()
	var composite: Image=await frame_image();composite.save_png(OUT+"composite.png")
	for child in scene.get_children():
		if str(child.name).begins_with("BALEEN"):child.visible=false
	var revealed: Image=await frame_image();revealed.save_png(OUT+"water-revealed.png")
	var failed: Array=checks.filter(func(c):return not c.pass)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed.size(),"method":"Actual rendered frame comparison. Other animation clocks held fixed for water scope test."},"\t"))
	print("WATER_QA ",JSON.stringify(checks))
	quit(0 if failed.is_empty() else 1)
