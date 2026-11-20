extends SceneTree
## Isolated render/time fixtures. Route Input QA is a separate suite.
const OUT := "res://build/qa/ecology-in-scene-v2"
var host: WhalebellyMain
var checks: Array[Dictionary] = []
var failures: int = 0
var observations: Array[Dictionary] = []
func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await process_frame
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"pass":ok})
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func frame() -> Image:
	await process_frame
	RenderingServer.force_draw()
	return root.get_texture().get_image()
func differences(a: Image, b: Image) -> int:
	var count: int = 0
	for y: int in range(0,a.get_height(),2):
		for x: int in range(0,a.get_width(),2):
			if a.get_pixel(x,y)!=b.get_pixel(x,y): count += 1
	return count
func write_image(image_: Image, label: String) -> void:
	image_.save_png(OUT.path_join(label+".png"))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await attachment_probe()
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","ecology-in-scene-v2")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(12)
	var sample: bool = "--sample" in OS.get_cmdline_user_args()
	for index: int in host.rooms.size():
		if sample and index!=0: continue
		paused = false
		host.set_process(true)
		host.load_room(index,[],false)
		await tick(8)
		host.player.invulnerable = 99999
		host.player.set_physics_process(false)
		var ecology: CampaignRoomEcology = host.scenery.get_node("RoomEcology")
		check(str(host.room.id)+" exactly one scene-owned ecology",host.scenery.find_children("RoomEcology","CampaignRoomEcology",false,false).size()==1)
		var geometry: String = JSON.stringify(host.room.get("surfaces",[]))
		var flags: String = JSON.stringify(host.abilities)
		paused = true
		host.set_process(false)
		var held: float = ecology.elapsed
		await tick(5)
		check(str(host.room.id)+" pauses with room",ecology.elapsed==held)
		var size_: Vector2 = host.point(host.room.size)
		host.camera.zoom = Vector2.ONE*minf(1280.0/size_.x,720.0/size_.y)
		host.camera.global_position = host.scenery.global_position + size_*0.5
		host.camera.player_light.hide()
		host.camera.force_update_scroll()
		await tick(2)
		ecology.update_at(0.0)
		var a: Image = await frame()
		write_image(a,str(host.room.id)+"-overview")
		ecology.hide()
		var without: Image = await frame()
		ecology.show()
		check(str(host.room.id)+" ecology contributes painted pixels",differences(a,without)>5)
		ecology.update_at(4.0)
		if str(host.room.id) == "R2-01":
			var school: KitAmphipodSchool = ecology.get_node("NurseryAmphipods")
			var sprite: Sprite2D = school.members[0].node
			check("R2-01 rendered swimming shader follows clock",is_equal_approx(float(sprite.material.get_shader_parameter("clock")),4.0))
		var b: Image = await frame()
		check(str(host.room.id)+" ecology visibly moves",differences(a,b)>5)
		write_image(b,str(host.room.id)+"-motion")
		var count: int = int(ecology.snapshot().nodes)
		ecology.update_at(600.0)
		check(str(host.room.id)+" bounded after 600s seek",int(ecology.snapshot().nodes)==count)
		check(str(host.room.id)+" no gameplay writes",geometry==JSON.stringify(host.room.get("surfaces",[])) and flags==JSON.stringify(host.abilities))
		var finite: bool = true
		for node: Node in ecology.find_children("*","Node2D",true,false):
			finite = finite and (node as Node2D).position.is_finite()
		check(str(host.room.id)+" finite positions",finite)
		ecology.update_at(4.0)
		host.camera.zoom = Vector2.ONE
		host.player.position = view_point()
		host.camera.global_position = host.scenery.global_position + host.player.position + Vector2(0,-70)
		host.camera.force_update_scroll()
		await tick(2)
		var normal_a: Image = await frame()
		ecology.hide()
		var normal_without: Image = await frame()
		ecology.show()
		var contribution: int = differences(normal_a,normal_without)
		check(str(host.room.id)+" visible ecology at normal play scale",contribution>20)
		ecology.update_at(9.0)
		var normal_b: Image = await frame()
		check(str(host.room.id)+" moving ecology at normal play scale",differences(normal_a,normal_b)>20)
		write_image(normal_b,str(host.room.id)+"-play")
		print("PLAY_CONTRIBUTION ",host.room.id," sampled_pixels=",contribution)
		observations.append(ecology.snapshot())
		paused = false
		ecology.speed = 0.0
		var stopped: float = ecology.elapsed
		await tick(6)
		check(str(host.room.id)+" zero speed holds pose",ecology.elapsed==stopped)
		ecology.speed = 1.0
		await tick(6)
		check(str(host.room.id)+" resumes clock",ecology.elapsed>stopped)
		# Preloaded neighbor ecology must not advance until activated.
		for entry: Dictionary in host.streaming.cached.values():
			var neighbor: CampaignRoomEcology = entry.scene.get_node("RoomEcology")
			var before: float = neighbor.elapsed
			await tick(3)
			check(str(host.room.id)+" sleeping neighbor "+str(neighbor.room_data.id),neighbor.elapsed==before)
		print("ECOLOGY_ROOM_DONE ",host.room.id)
	paused = false
	host.set_process(true)
	FileAccess.open(OUT.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"rooms":observations,"failures":failures},"\t"))
	print("ECOLOGY_19 failures=",failures)
	await host.graceful_quit(1 if failures>0 else 0)

func attachment_probe() -> void:
	for path: String in ["res://art/world-kit/habitat-fungus-bed.png","res://art/ecology-19-v2/r4-attached-colony.png","res://art/ecology-19-v2/r5-attached-colony.png"]:
		await probe_texture(path)

func probe_texture(path: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512,256)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var sprite := Sprite2D.new()
	sprite.texture = load(path) as Texture2D
	sprite.centered = false
	sprite.scale = Vector2.ONE*minf(512.0/sprite.texture.get_width(),256.0/sprite.texture.get_height())
	var material_ := ShaderMaterial.new()
	material_.shader = CampaignRoomEcology.ATTACHED_SHADER
	material_.set_shader_parameter("glow_strength",0.0 if path.contains("/r4-") else 0.02)
	sprite.material = material_
	viewport.add_child(sprite)
	await process_frame
	RenderingServer.force_draw()
	var a: Image = viewport.get_texture().get_image()
	material_.set_shader_parameter("clock",4.0)
	await process_frame
	RenderingServer.force_draw()
	var b: Image = viewport.get_texture().get_image()
	check(path+" painted root pixels fixed",differences(a.get_region(Rect2i(0,192,512,64)),b.get_region(Rect2i(0,192,512,64)))==0)
	check(path+" painted tips animate locally",differences(a,b)>10)
	viewport.queue_free()
	await process_frame

func view_point() -> Vector2:
	var desired: Vector2 = host.point(host.room.get("play_spawn",host.room.spawn))
	var distance: float = INF
	for surface: Array in host.room.get("surfaces",[]):
		var a: Vector2 = host.point(surface[0])
		var b: Vector2 = host.point(surface[-1])
		if b.x-a.x < 150.0: continue
		var middle: Vector2 = (a+b)*0.5
		var score: float = absf(middle.x-float(host.room.size[0])*0.5)
		if score<distance: desired=middle;distance=score
	return Vector2(desired.x,host.ground_y(desired.x,desired.y))
