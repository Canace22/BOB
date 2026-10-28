extends SceneTree
var host: Node2D
var report: Dictionary={"method":"Actual render/physics frames, frozen reference and live near camera","audio_driver":"Dummy","rooms":[],"checks":[]}
func _initialize() -> void: run.call_deferred()
func frames(n: int) -> void:
	for i: int in range(n):await process_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidence/dynamic-"+name+".png")
func run() -> void:
	host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	host.qa=true
	for i: int in range(7):
		host.load_room(i)
		host.player.set_physics_process(false)
		await frames(12)
		var e: Node2D=host.scenery.get_node("EnvironmentMotion")
		var m: Node2D=host.scenery.get_node("VisualMechanisms")
		var before: float=e.phase
		var before_sway: float=m.phase
		await frames(24)
		var material: ShaderMaterial=host.scenery.get_node("Middle/MiddleOriginalPixels").material
		report.rooms.append({"id":host.room.id,"bubbles":e.bubbles.size(),"dust":e.dust.size(),"fish":e.fish.size(),"mist":e.fog_node.get_child_count(),"particles_advance":e.phase>before,"canopy_clock_advance":m.phase>before_sway,"shader_clock_matches":absf(float(material.get_shader_parameter("clock"))-m.phase)<0.01,"doors":m.trigger_nodes.size(),"rings":m.rings_node.get_child_count()})
	host.load_room(0,[300,610])
	host.zoomed=true
	host.player.set_physics_process(true)
	await frames(20)
	var positions_before: Array=[]
	for layer: String in ["Far","Middle","Foreground"]:positions_before.append(host.scenery.get_node(layer).position)
	await shot("camera-left")
	Input.action_press("right")
	await frames(160)
	Input.action_release("right")
	await frames(10)
	var positions_after: Array=[]
	for layer: String in ["Far","Middle","Foreground"]:positions_after.append(host.scenery.get_node(layer).position)
	await shot("camera-right")
	var changed: bool=false
	for i: int in range(3):changed=changed or positions_before[i].distance_to(positions_after[i])>0.05
	report.checks.append({"id":"real_camera_parallax","pass":changed,"before":str(positions_before),"after":str(positions_after),"player_x":host.player.position.x})
	var e: Node2D=host.scenery.get_node("EnvironmentMotion")
	var m: Node2D=host.scenery.get_node("VisualMechanisms")
	var t0: float=e.phase
	var m0: float=m.phase
	var p0: Vector2=host.player.position
	paused=true
	Input.action_press("right")
	await frames(20)
	report.checks.append({"id":"pause_all_motion","pass":e.phase==t0 and m.phase==m0 and host.player.position==p0})
	Input.action_release("right")
	paused=false
	await frames(8)
	report.checks.append({"id":"resume_all_motion","pass":e.phase>t0 and m.phase>m0})
	await shot("motion-a")
	await frames(60)
	await shot("motion-b")
	host.reference_visible=true
	var old: float=e.phase
	var old_m: float=m.phase
	await frames(20)
	report.checks.append({"id":"reference_camera_freezes_motion","pass":e.phase==old and m.phase==old_m})
	FileAccess.open("res://evidence/dynamics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("DYNAMICS ",JSON.stringify(report))
	await host.graceful_quit()
