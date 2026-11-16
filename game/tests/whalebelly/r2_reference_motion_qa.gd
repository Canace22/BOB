extends "res://tests/whalebelly/remaining_19_qa.gd"
## Current campaign with isolated position/time/progress fixtures.
class MotionCampaign extends WhalebellyMain:
	func save_path() -> String:
		return "user://whalebelly/r2-reference-motion-v4-%s.json" % str(ProjectSettings.globalize_path("res://").hash())

func frame() -> Image:
	await process_frame
	# A paused static scene with a disabled camera can stop scheduling redraws.
	RenderingServer.force_draw()
	return root.get_texture().get_image()
func component_time(node: Node) -> float:
	return float(node.get("elapsed")) if "elapsed" in node else float(node.get("time"))

func view(follow: bool) -> void:
	host.zoomed=follow
	if follow:host.camera.zoom=Vector2.ONE*float(host.room.get("camera_zoom",1.0))
	host.update_camera()
	host.camera.force_update_scroll()
	for layer: KitParallaxLayer in host.scenery.find_children("*","KitParallaxLayer",true,false):
		layer.position=layer.offset_for(host.camera.get_screen_center_position())
	await frame()

func local_surface_probe(sprite: KitReferenceMotionSprite) -> void:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(512,384)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var local:=Sprite2D.new()
	local.texture=sprite.texture
	local.centered=false
	local.scale=Vector2.ONE*minf(512.0/local.texture.get_width(),384.0/local.texture.get_height())
	local.material=sprite.material.duplicate()
	viewport.add_child(local)
	local.material.set_shader_parameter("clock",0.0)
	await RenderingServer.frame_post_draw
	var a: Image=viewport.get_texture().get_image()
	local.material.set_shader_parameter("clock",3.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var b: Image=viewport.get_texture().get_image()
	if sprite.motion_kind=="membrane":
		var height_: int=int(sprite.texture.get_height()*local.scale.y*.28)
		check("membrane attached root pixels stay exactly fixed",differences(a.get_region(Rect2i(0,0,512,height_)),b.get_region(Rect2i(0,0,512,height_)))==0)
		check("membrane tips bend independently of their root",differences(a,b)>20)
	else:
		check("pearl stalk light changes painted pixels",differences(a,b)>10)
		var alpha_equal: bool=true
		for y: int in range(0,384,3):
			for x: int in range(0,512,3):
				if a.get_pixel(x,y).a!=b.get_pixel(x,y).a:alpha_equal=false
		check("pearl light preserves its silhouette and alpha",alpha_equal)
	viewport.queue_free()
	await process_frame

func clip(id: String, motion: KitDepthMotion) -> void:
	if not "--clip" in OS.get_cmdline_user_args():return
	# The campaign is ALWAYS for menus; freeze its camera interpolation as well
	# as the paused gameplay, so this clip isolates environment motion.
	host.set_process(false)
	var frozen_camera: Transform2D=root.canvas_transform
	host.camera.enabled=false
	var count: int=160
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--clip-frames="):count=clampi(int(argument.trim_prefix("--clip-frames=")),2,160)
	var folder: String=output.path_join("motion" if count==160 else "debug-motion").path_join(id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var camera_fixed: bool=true
	for i: int in count:
		root.canvas_transform=frozen_camera
		motion.update_at(float(i)/20.0)
		var captured: Image=await frame()
		camera_fixed=camera_fixed and root.canvas_transform==frozen_camera
		captured.save_png(folder.path_join("%04d.png"%i))
		captured=null
	check(id+" preview camera remains fixed",camera_fixed)
	host.camera.enabled=true
	host.set_process(true)

func review_reference(id: String) -> void:
	host.load_room(host.rooms.find_custom(func(r: Dictionary)->bool:return r.id==id),[VIEWS[id].x,VIEWS[id].y],false)
	host.player_ui.close_all()
	host.player.automatic_doors=false
	host.player.invulnerable=99999.0
	host.zoomed=true
	await tick(65)
	paused=true
	var motion: KitDepthMotion=host.scenery.get_node("PresentationMotion")
	var schools: Array[Node]=host.scenery.find_children("BackgroundSchool*","KitAmphipodSchool",true,false)
	var surfaces: Array[Node]=host.scenery.find_children("*","KitReferenceMotionSprite",true,false)
	check(id+" correct dedicated original-style plate",(host.scenery.get_node("Far/Organs/Art") as Sprite2D).texture.resource_path.ends_with("r2-observation-depth-v4.png" if id=="R2-03" else "r2-bloodnest-depth-v4.png"))
	check(id+" all new ambience shares one clock",motion.unified_ambient and motion.ambient.size()>=10)
	var held: float=motion.elapsed
	await tick(10)
	check(id+" paused clock and children freeze",motion.elapsed==held and motion.ambient.all(func(n: Node)->bool:return is_equal_approx(component_time(n),held)))
	await shot(id+"-follow")
	var a: Image=await frame()
	motion.update_at(held+4.0)
	check(id+" environment visibly animates in the real room",differences(a,await frame())>50)
	check(id+" bounded background school count",schools.size()==(2 if id=="R2-03" else 1) and schools.reduce(func(sum: int,n: Node)->int:return sum+n.members.size(),0)==(54 if id=="R2-03" else 20))
	await view(false)
	for school: KitAmphipodSchool in schools:
		var old_positions: Array=school.members.map(func(m: Dictionary)->Vector2:return m.node.position)
		var base: Image=await frame()
		for member: Dictionary in school.members:member.material.set_shader_parameter("clock",held+5.1)
		check(id+" body motion independent of group path",differences(base,await frame())>1)
		check(id+" body test leaves school positions fixed",old_positions==school.members.map(func(m: Dictionary)->Vector2:return m.node.position))
		check(id+" school cannot deal damage",school.find_children("*","CollisionObject2D",true,false).is_empty())
	for kind: String in ["membrane","glow"]:
		var found: Node=surfaces.filter(func(n: Node)->bool:return n.motion_kind==kind)[0]
		await local_surface_probe(found)
	# Hide only the environmental layers, then advance their clock. World/UI must
	# remain byte-identical; this is not a screen-wide distortion/exposure pass.
	for path: String in ["Far","Middle","Framing","Foreground"]:host.scenery.get_node(path).hide()
	var protected: Image=await frame()
	motion.update_at(held+7.0)
	check(id+" actors footing combat and UI remain protected",differences(protected,await frame())==0)
	for path: String in ["Far","Middle","Framing","Foreground"]:host.scenery.get_node(path).show()
	motion.update_at(held)
	await view(true)
	await clip(id,motion)
	await view(false)
	await shot(id+"-overview")
	var base: Image=await frame()
	for path: String in ["Far/Organs","Middle","Framing","World","Foreground"]:
		check(id+" "+path+" contributes",await contribution(host.scenery.get_node(path),base)>5)
	if id=="R2-04":
		host.abilities.pressure=true
		motion.update_at(motion.elapsed+4.0)
		check("background school fades after actual pressure flag",schools[0].hidden_mix>.99)
		check("ambient fade awards no boss defeat",not host.defeated.get("R2-04:0",false))
		host.abilities.pressure=false
		motion.update_at(0.0)
	motion.speed=0.0
	var stopped: float=motion.elapsed
	paused=false
	await tick(15)
	check(id+" zero speed freezes all registered ambience",motion.elapsed==stopped and motion.ambient.all(func(n: Node)->bool:return is_equal_approx(component_time(n),stopped)))
	motion.speed=1.0
	await tick(15)
	check(id+" resume advances from held time",motion.elapsed>stopped)

func run() -> void:
	root.size=Vector2i(1280,720)
	output="res://build/qa/r2-reference-motion-v4/current"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(MotionCampaign)
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(30)
	for id: String in ["R2-03","R2-04"]:await review_reference(id)
	paused=false
	host.load_room(host.rooms.find_custom(func(r: Dictionary)->bool:return r.id=="R2-03"),[],false)
	await tick(10)
	var motion: KitDepthMotion=host.scenery.get_node("PresentationMotion")
	check("room reload resets the single clock and bounded school",motion.elapsed<1.0 and host.scenery.get_node("Middle/Ambient/BackgroundSchool0").members.size()==24)
	var failures: int=checks.filter(func(c: Dictionary)->bool:return not c["pass"]).size()
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"Real campaign; isolated position/time/progress fixtures. Clips advance the registered environment only at 20fps, no natural-play or performance claim."},"\t"))
	print("R2_REFERENCE_COMPLETE failures=",failures)
	host.graceful_quit.call_deferred(1 if failures else 0)
