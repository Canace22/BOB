extends SceneTree
## GPU pixels and actual campaign views; room/pose fixtures are explicit.
const OUT := "res://build/qa/resource-color"
const FLASH := preload("res://src/combat/hit_flash.gdshader")
const LEGACY_FLASH := "shader_type canvas_item; render_mode unshaded; void fragment(){COLOR=texture(TEXTURE,UV)*COLOR;}"
var checks: Array[Dictionary] = []
var host: WhalebellyMain

func _initialize() -> void: run.call_deferred()

func tick(count: int) -> void:
	for i: int in count: await physics_frame

func rendered() -> void:
	await process_frame
	await RenderingServer.frame_post_draw

func check(label: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"name":label,"pass":ok,"detail":detail})
	print("PASS " if ok else "FAIL ",label," ",detail)

func error(a: Color, b: Color) -> float:
	return maxf(maxf(absf(a.r-b.r),absf(a.g-b.g)),maxf(absf(a.b-b.b),absf(a.a-b.a)))

func viewport(size: Vector2i) -> SubViewport:
	var view := SubViewport.new()
	view.size = size
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	return view

func flash_pixels() -> void:
	var view := viewport(Vector2i(64,32))
	var bitmap := Image.create_empty(8,8,false,Image.FORMAT_RGBA8)
	bitmap.fill(Color(0.38,0.60,0.72,0.5))
	var plain := Sprite2D.new()
	plain.texture = ImageTexture.create_from_image(bitmap)
	plain.centered = false
	plain.scale = Vector2.ONE*4
	plain.modulate = Color(0.8,0.9,0.7,0.75)
	view.add_child(plain)
	var subject := plain.duplicate() as Sprite2D
	subject.position.x = 32
	var material := ShaderMaterial.new()
	var legacy := Shader.new()
	legacy.code = LEGACY_FLASH
	material.shader = legacy
	subject.material = material
	view.add_child(subject)
	await rendered()
	await rendered()
	var pixels := view.get_texture().get_image()
	var reference := pixels.get_pixel(16,16)
	check("legacy reproduces dark RGB and thin alpha",error(reference,pixels.get_pixel(48,16))>0.05)
	for shader: Shader in [FLASH,load("res://tests/whitebox_combat/hit_flash.gdshader")]:
		material.shader = shader
		await rendered()
		await rendered()
		pixels = view.get_texture().get_image()
		var repaired := pixels.get_pixel(48,16)
		check(shader.resource_path+" matches plain modulated RGBA",error(reference,repaired)<0.008,error(reference,repaired))
	material.shader = FLASH
	material.set_shader_parameter("flash",1.0)
	await rendered()
	await rendered()
	var flashed := view.get_texture().get_image().get_pixel(48,16)
	check("hit flash brightens without changing alpha",absf(flashed.a-reference.a)<0.008 and flashed.r>reference.r and flashed.g>reference.g)
	view.queue_free()
	await tick(2)

func foreground_pixels() -> void:
	var view := viewport(Vector2i(658,404))
	var sprite := Sprite2D.new()
	sprite.texture = load("res://art/r1-chapter-scenes/R1-05/Foreground.png")
	sprite.centered = false
	sprite.scale = Vector2.ONE*0.4
	var material := ShaderMaterial.new()
	material.shader = load("res://src/world/scenery/layout/foreground_clearance.gdshader")
	material.set_shader_parameter("shadow_water",Vector3.ZERO)
	sprite.material = material
	view.add_child(sprite)
	await rendered()
	await rendered()
	var before := view.get_texture().get_image()
	material.set_shader_parameter("shadow_water",Vector3(0.14,0.30,0.35))
	await rendered()
	await rendered()
	var after := view.get_texture().get_image()
	var alpha_error := 0.0
	var lifted := 0
	var retained := true
	for y: int in before.get_height():
		for x: int in before.get_width():
			var a := before.get_pixel(x,y)
			var b := after.get_pixel(x,y)
			alpha_error = maxf(alpha_error,absf(a.a-b.a))
			if a.a>0.5 and b.g>a.g+0.02: lifted += 1
			retained = retained and b.r+0.008>=a.r and b.g+0.008>=a.g and b.b+0.008>=a.b
	check("foreground silhouette and clearance alpha preserved",alpha_error<0.004,alpha_error)
	check("foreground deep shadows receive water light",lifted>1000,lifted)
	check("foreground retains original texture channels",retained)
	view.queue_free()
	await tick(2)

func shot(label: String) -> void:
	await rendered()
	await rendered()
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))

func campaign_views() -> void:
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","resource-color")
	host.qa = true
	host.integration_external_test = true
	host.qa_full_abilities = false
	root.add_child(host)
	current_scene = host
	await tick(45)
	for room_index: int in [4,1,3,0,2,5,6]:
		host.load_room(room_index)
		await tick(45)
		host.camera.set_process(false)
		host.camera.set_physics_process(false)
		host.camera.position_smoothing_enabled = false
		host.camera.zoom = Vector2.ONE
		var center := Vector2(900,760)
		if room_index in [1,3]:
			var actor: Node2D = host.enemies[0].actor
			center = actor.position+Vector2(0,-220)
		host.camera.global_position = host.scenery.global_position+center
		host.camera.reset_smoothing()
		host.player.position = center+Vector2(0,-20)
		host.player.velocity = Vector2.ZERO
		host.player.invulnerable = 100.0
		await tick(2)
		paused = true
		var foreground: Sprite2D = host.scenery.get_node("Foreground/OriginalNearBone")
		var foreground_material := foreground.material as ShaderMaterial
		check("R1-%02d uses graded live foreground"%(room_index+1),foreground_material.shader.code.contains("shadow_water") and not foreground.texture.resource_path.is_empty())
		if room_index in [4,1,3]:
			foreground_material.set_shader_parameter("shadow_water",Vector3.ZERO)
			var actor_material: ShaderMaterial
			var actor_shader: Shader
			if room_index in [1,3]:
				actor_material = host.enemies[0].actor.visual.material
				actor_shader = actor_material.shader
				var legacy := Shader.new()
				legacy.code = LEGACY_FLASH
				actor_material.shader = legacy
			await shot("R1-%02d-before"%(room_index+1))
			foreground_material.set_shader_parameter("shadow_water",Vector3(0.14,0.30,0.35))
			if actor_material != null:
				actor_material.shader = actor_shader
				check("R1-%02d real enemy uses corrected streamed shader"%(room_index+1),actor_shader.code.contains("vec4 source = COLOR;") and host.enemies[0].actor.feedback.materials.has(actor_material))
		await shot("R1-%02d-after"%(room_index+1))
		if room_index in [1,3]:
			var actor: Node2D = host.enemies[0].actor
			actor.feedback.receive(0.05,1.0,3.0)
			check("R1-%02d hit flash reaches live material"%(room_index+1),is_equal_approx(float(actor.visual.material.get_shader_parameter("flash")),1.0))
			await shot("R1-%02d-flash"%(room_index+1))
			actor.feedback.clear()
		paused = false
		if room_index == 4:
			var start: Vector2 = host.player.position
			var event := InputEventKey.new()
			event.keycode = KEY_D
			event.physical_keycode = KEY_D
			event.pressed = true
			Input.parse_input_event(event)
			await tick(12)
			event.pressed = false
			Input.parse_input_event(event)
			check("actual D key still moves player in nursery",host.player.position.x>start.x+10)

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("resource_color_qa requires a GPU display")
		quit(1)
		return
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await flash_pixels()
	await foreground_pixels()
	await campaign_views()
	var failed: int = checks.filter(func(c: Dictionary) -> bool: return not c.pass).size()
	FileAccess.open(OUT.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"method":"GPU pixel comparison, explicit room/pose fixtures and D key; isolated QA save"},"\t"))
	print("RESOURCE_COLOR_COMPLETE checks=",checks.size()," failed=",failed)
	await host.graceful_quit(1 if failed else 0)
