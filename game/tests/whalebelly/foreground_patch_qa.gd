extends SceneTree
## Real opaque cutout, GPU composites and user-pose regression; isolated QA save.
const OUT := "res://build/qa/foreground-patch"
const SHADER := preload("res://src/world/scenery/layout/foreground_clearance.gdshader")
var host: WhalebellyMain
var checks: Array[Dictionary] = []

func _initialize() -> void: run.call_deferred()

func tick(count: int) -> void:
	for frame: int in count: await physics_frame

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=down
	Input.parse_input_event(event)

func check(label: String, passed: bool, detail: Variant=null) -> void:
	checks.append({"name":label,"pass":passed,"detail":detail})
	print("PASS " if passed else "FAIL ",label," ",detail)

func render(view: Viewport) -> Image:
	for frame: int in 2:
		await process_frame
		await RenderingServer.frame_post_draw
	return view.get_texture().get_image()

func shot(label: String) -> Image:
	var bitmap := await render(root)
	bitmap.save_png(OUT.path_join(label+".png"))
	return bitmap

func shade(material: ShaderMaterial, legacy: bool) -> void:
	material.set_shader_parameter("shadow_water",Vector3(0.07,0.14,0.17) if legacy else Vector3(0.14,0.30,0.35))
	material.set_shader_parameter("foreground_opacity",1.0 if legacy else 0.55)

func texture_pixels() -> void:
	var texture: Texture2D=load("res://art/whalebelly/foreground_edges/FRONT-BOTTOM-PAD.png")
	var source := texture.get_image()
	var dark := source.get_pixel(400,650)
	check("Actual source contains opaque near-black fill",dark.r<0.015 and dark.g<0.015 and dark.b<0.015 and dark.a==1.0,dark)
	var view := SubViewport.new()
	view.size=Vector2i(source.get_width(),source.get_height())
	view.transparent_bg=true
	view.world_2d=World2D.new()
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var sprite := Sprite2D.new()
	sprite.centered=false
	sprite.texture=texture
	var material := ShaderMaterial.new()
	material.shader=SHADER
	sprite.material=material
	view.add_child(sprite)
	shade(material,true)
	var before := await render(view)
	shade(material,false)
	var after := await render(view)
	var alpha_error := 0.0
	var transparent_error := 0.0
	for y: int in after.get_height():
		for x: int in after.get_width():
			var a := before.get_pixel(x,y)
			var b := after.get_pixel(x,y)
			alpha_error=maxf(alpha_error,absf(b.a-a.a*0.55))
			if a.a==0.0: transparent_error=maxf(transparent_error,b.a)
	check("Opacity scales existing silhouette without adding a rectangle",alpha_error<0.008 and transparent_error==0.0,alpha_error)
	var pixel := after.get_pixel(400,650)
	check("Opaque black source receives visible blue-green water light",pixel.g>0.14 and pixel.b>0.17 and pixel.a<0.56,pixel)
	view.queue_free()
	await tick(2)

func compare_patch(before: Image, after: Image, clear: Image) -> void:
	var old_darkening := 0.0
	var new_darkening := 0.0
	var samples := 0
	# Left of the recovery platform: the black patch in the user's screenshot.
	for y: int in range(360,500):
		for x: int in range(35,275):
			var background := clear.get_pixel(x,y).get_luminance()
			var old_value := before.get_pixel(x,y).get_luminance()
			if background-old_value<0.02: continue
			old_darkening+=background-old_value
			new_darkening+=maxf(0.0,background-after.get_pixel(x,y).get_luminance())
			samples+=1
	var ratio := new_darkening/maxf(old_darkening,0.00001)
	check("User-pose black patch loses at least 60 percent of its darkening",samples>1000 and ratio<0.40,{"samples":samples,"ratio":ratio})
	var platform_delta := 0.0
	for y: int in range(355,385):
		for x: int in range(440,600):
			var a := before.get_pixel(x,y)
			var b := after.get_pixel(x,y)
			platform_delta=maxf(platform_delta,maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))))
	check("Platform top and authored bone shading stay unchanged",platform_delta<0.008,platform_delta)

func campaign() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","foreground-patch")
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	host.ui_interactive_in_tests=true
	root.add_child(host)
	current_scene=host
	await tick(50)
	var save_before := FileAccess.get_file_as_bytes(host.save_path()) if FileAccess.file_exists(host.save_path()) else PackedByteArray()
	host.player.position=Vector2(650,950)
	host.player.velocity=Vector2.ZERO
	host.player.invulnerable=1000
	await tick(30)
	paused=true
	var foreground: Sprite2D=host.scenery.get_node("Foreground/OriginalNearBone")
	var material := foreground.material as ShaderMaterial
	shade(material,true)
	var before := await shot("01-user-pose-before")
	shade(material,false)
	var after := await shot("02-user-pose-after")
	foreground.hide()
	var clear := await shot("03-user-pose-without-near")
	foreground.show()
	compare_patch(before,after,clear)
	paused=false
	var start: Vector2=host.player.position
	key(KEY_D,true)
	await tick(12)
	key(KEY_D,false)
	await tick(4)
	check("Real D input walks on affected platform",host.player.position.x>start.x+10 and host.player.is_on_floor())
	key(KEY_SPACE,true)
	await tick(8)
	key(KEY_SPACE,false)
	check("Real Space jumps above platform",not host.player.is_on_floor() and host.player.position.y<start.y-15)
	await tick(90)
	check("Jump lands on the same platform",host.player.is_on_floor() and absf(host.player.position.y-start.y)<4)
	key(KEY_ESCAPE,true)
	await tick(2)
	key(KEY_ESCAPE,false)
	await tick(3)
	var held: float=host.clock
	await tick(12)
	check("Real Escape opens pause and stops environment",paused and is_equal_approx(host.clock,held))
	key(KEY_ESCAPE,true)
	await tick(2)
	key(KEY_ESCAPE,false)
	await tick(20)
	check("Real Escape resumes gameplay",not paused and host.clock>held)
	for index: int in 7:
		host.load_room(index)
		await tick(45)
		foreground=host.scenery.get_node("Foreground/OriginalNearBone")
		material=foreground.material as ShaderMaterial
		check("R1-%02d uses softened live near material"%(index+1),is_equal_approx(float(material.get_shader_parameter("foreground_opacity")),0.55) and material.get_shader_parameter("shadow_water")==Vector3(0.14,0.30,0.35))
		host.player.set_physics_process(false)
		host.player.position=Vector2(float(host.room.size[0])*0.5,float(host.room.size[1])*0.70)
		host.player.velocity=Vector2.ZERO
		await tick(8)
		await shot("R1-%02d-after"%(index+1))
	var save_after := FileAccess.get_file_as_bytes(host.save_path()) if FileAccess.file_exists(host.save_path()) else PackedByteArray()
	check("Visual regression leaves isolated save bytes unchanged",save_before==save_after)

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("foreground_patch_qa requires GPU rendering")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1280,720)
	await texture_pixels()
	await campaign()
	var failures: int=checks.filter(func(entry: Dictionary)->bool:return not entry.pass).size()
	FileAccess.open(OUT.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"Native GPU; explicit seven-room fixtures; real D/Space/Escape; isolated QA save"},"\t"))
	print("FOREGROUND_PATCH_COMPLETE checks=",checks.size()," failures=",failures)
	await host.graceful_quit(1 if failures else 0)
