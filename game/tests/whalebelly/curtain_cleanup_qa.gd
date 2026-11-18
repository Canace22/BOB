extends SceneTree
## GPU art review and real keys from an explicit room fixture; isolated QA save.
const OUT := "res://build/qa/curtain-cleanup/"
const SOURCE := "res://../assets/source/r1-02-curtain-cleanup-v1/"
var host: WhalebellyMain
var checks: Array[Dictionary] = []

func _initialize() -> void: run.call_deferred()

func tick(count: int) -> void:
	for frame: int in count: await physics_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)

func check(label: String, passed: bool, detail: Variant=null) -> void:
	checks.append({"name":label,"pass":passed,"detail":detail})
	print("PASS " if passed else "FAIL ",label," ",detail)

func shot(label: String) -> Image:
	await process_frame
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	image.save_png(OUT+label+".png")
	return image

func png(path: String) -> Image:
	var image := Image.new()
	image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	return image

func source_checks() -> void:
	# Compare source exports; the importer may rewrite invisible RGB at alpha zero.
	var before := png(SOURCE+"Middle-original.png")
	var after := png("res://art/r1-chapter-scenes/R1-02/Middle.png")
	var altered_outside := 0
	var cleared := 0
	for y: int in after.get_height():
		for x: int in after.get_width():
			var a := before.get_pixel(x,y)
			var b := after.get_pixel(x,y)
			if a==b: continue
			if x<548 or x>=1380 or y>444: altered_outside+=1
			if a.a>0.1 and b.a==0.0: cleared+=1
	check("static curtain removed without changing distant walls",altered_outside==0 and cleared>50000,{"cleared":cleared,"outside":altered_outside})
	var image: Image=(load("res://art/r1-chapter-scenes/R1-02/R1-02-BALEEN-1.png") as Texture2D).get_image()
	check("original crop dimensions retained",image.get_size()==Vector2i(814,399))
	var gaps := 0
	var fibers := 0
	for y: int in range(30,150):
		for x: int in range(400,700):
			var alpha := image.get_pixel(x,y).a
			if alpha<0.05: gaps+=1
			if alpha>0.2: fibers+=1
	check("upper right has both rooted fibers and clear gaps",gaps>1500 and fibers>3000,{"gaps":gaps,"fibers":fibers})
	var border := 0.0
	for x: int in image.get_width():
		border=maxf(border,maxf(image.get_pixel(x,0).a,image.get_pixel(x,398).a))
	for y: int in image.get_height():
		border=maxf(border,maxf(image.get_pixel(0,y).a,image.get_pixel(813,y).a))
	check("all four texture borders transparent",border==0.0)

func loop_checks(fringe: ChapterPinnedBitmap) -> void:
	# Isolate the subject: the ALWAYS player/UI may still change while paused.
	var view := SubViewport.new()
	view.size=Vector2i(814,399)
	view.transparent_bg=true
	view.world_2d=World2D.new()
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var subject := ChapterPinnedBitmap.new()
	subject.texture=fringe.texture
	subject.amplitude=fringe.amplitude
	subject.period=fringe.period
	subject.phase=fringe.phase
	subject.root_profile=fringe.root_profile
	subject.modulate=fringe.modulate
	view.add_child(subject)
	var phases: Array[Image]=[]
	for time: float in [0.0,4.5,9.0]:
		subject.update_at(time)
		await process_frame
		RenderingServer.force_draw(false)
		phases.append(view.get_texture().get_image())
	check("isolated GPU curtain visibly sways",phases[0].get_data()!=phases[1].get_data())
	check("isolated GPU nine second loop returns to rest",phases[0].get_data()==phases[2].get_data())
	check("fixed root band does not move",phases[0].get_region(Rect2i(0,0,814,60)).get_data()==phases[1].get_region(Rect2i(0,0,814,60)).get_data())
	view.queue_free()

func visual_checks() -> void:
	var fringe := host.scenery.get_node("Middle/Fringe0") as ChapterPinnedBitmap
	var middle := host.scenery.get_node("Middle/OriginalChamber") as Sprite2D
	var old_texture: Texture2D=middle.texture
	var new_texture: Texture2D=fringe.texture
	var tint := fringe.modulate
	paused=true
	middle.texture=ImageTexture.create_from_image(Image.load_from_file(SOURCE+"Middle-original.png"))
	fringe.texture=ImageTexture.create_from_image(Image.load_from_file(SOURCE+"curtain-original.png"))
	fringe.modulate=Color(0.88,0.91,0.94,1)
	fringe.update_at(0)
	await shot("01-before")
	middle.texture=old_texture
	fringe.texture=new_texture
	fringe.modulate=tint
	fringe.update_at(0)
	await shot("02-after")
	for time: float in [2.25,4.5,6.75]:
		fringe.update_at(time)
		await shot("03-phase-"+str(time))
	fringe.update_at(9.0)
	await shot("04-loop")
	fringe.hide()
	await shot("05-static-without-duplicate")
	fringe.show()
	paused=false
	check("live scene binds repaired source",fringe.texture.resource_path.ends_with("R1-02-BALEEN-1.png") and fringe.material is ShaderMaterial)
	await loop_checks(fringe)

func input_checks() -> void:
	var saved := FileAccess.get_file_as_string(host.save_path())
	var start: Vector2=host.player.position
	key(KEY_D,true)
	await tick(12)
	key(KEY_D,false)
	check("real D traverses ledge beside curtain",host.player.position.x>start.x+15)
	start=host.player.position
	key(KEY_SPACE,true)
	await tick(8)
	key(KEY_SPACE,false)
	check("real Space jumps beside curtain",not host.player.is_on_floor() and host.player.position.y<start.y-15)
	await tick(90)
	check("jump lands back on real support",host.player.is_on_floor())
	key(KEY_ESCAPE,true)
	await tick(2)
	key(KEY_ESCAPE,false)
	await tick(8)
	var held: float=host.clock
	await tick(20)
	check("real Escape pauses environment",paused and is_equal_approx(host.clock,held))
	key(KEY_ESCAPE,true)
	await tick(2)
	key(KEY_ESCAPE,false)
	await tick(20)
	check("real Escape resumes environment",not paused and host.clock>held)
	check("art rehearsal leaves saved progress untouched",FileAccess.get_file_as_string(host.save_path())==saved)
	await shot("06-playable")
	host.camera.global_position=host.scenery.global_position+Vector2(820,450)
	await shot("07-room-overview")

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("curtain_cleanup_qa requires a GPU display")
		quit(1)
		return
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUT)
	source_checks()
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","curtain-cleanup")
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	host.ui_interactive_in_tests=true
	root.add_child(host)
	current_scene=host
	await tick(30)
	host.load_room(1,[1160,210])
	await tick(35)
	host.player.invulnerable=1000
	host.camera.set_process(false)
	host.camera.set_physics_process(false)
	host.camera.position_smoothing_enabled=false
	host.camera.zoom=Vector2.ONE
	host.camera.global_position=host.scenery.global_position+Vector2(1160,210)
	host.camera.reset_smoothing()
	await visual_checks()
	await input_checks()
	var failed: int=checks.filter(func(c: Dictionary) -> bool: return not c.pass).size()
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"scope":"explicit R1-02 start fixture; GPU phases and real D/Space/Escape; isolated save"},"\t"))
	print("CURTAIN_CLEANUP_COMPLETE checks=",checks.size()," failed=",failed)
	await host.graceful_quit(1 if failed else 0)
