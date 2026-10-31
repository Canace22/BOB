@warning_ignore_start("untyped_declaration")
extends SceneTree
var checks:Array=[]
var host:Node2D
const OUT="res://build/qa/whalebelly/character-color/"
func _initialize() -> void:call_deferred("run")
func frames(n:int) -> void:
	for i in range(n):await physics_frame
func rendered() -> void:
	await process_frame;await RenderingServer.frame_post_draw
func check(name:String,ok:bool,details:Variant=null) -> void:
	checks.append({"name":name,"pass":ok,"details":details});print("PASS " if ok else "FAIL ",name," ",details)
func difference(a:Color,b:Color) -> float:return maxf(maxf(absf(a.r-b.r),absf(a.g-b.g)),maxf(absf(a.b-b.b),absf(a.a-b.a)))
func shot(name:String) -> void:
	await rendered();root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
	var fixed:Shader=load("res://src/campaign/tide_flash.gdshader")
	var legacy:=Shader.new();legacy.code=FileAccess.get_file_as_string(OUT+"before.gdshader")
	var viewport:=SubViewport.new();viewport.size=Vector2i(64,32);viewport.transparent_bg=true;viewport.world_2d=World2D.new();viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var tex_image:=Image.create_empty(8,8,false,Image.FORMAT_RGBA8);tex_image.fill(Color(.38,.6,.72,.5));var texture:=ImageTexture.create_from_image(tex_image)
	var control:=Sprite2D.new();control.texture=texture;control.centered=false;control.scale=Vector2.ONE*4;control.modulate=Color(.8,.9,.7,.75);viewport.add_child(control)
	var subject:=Sprite2D.new();subject.texture=texture;subject.centered=false;subject.scale=Vector2.ONE*4;subject.position.x=32;subject.modulate=control.modulate
	var material:=ShaderMaterial.new();material.shader=legacy;subject.material=material;viewport.add_child(subject)
	await rendered();await rendered()
	var pixels:Image=viewport.get_texture().get_image();var reference:Color=pixels.get_pixel(16,16);var old:Color=pixels.get_pixel(48,16)
	check("reproduces_double_multiply",difference(reference,old)>.05,{"unshaded":reference,"old":old})
	material.shader=fixed;await rendered();await rendered()
	pixels=viewport.get_texture().get_image();var repaired:Color=pixels.get_pixel(48,16)
	check("matches_unshaded_RGBA_with_modulation",difference(reference,repaired)<.008,{"unshaded":reference,"fixed":repaired,"max_error":difference(reference,repaired)})
	material.set_shader_parameter("flash",1.0);await rendered();await rendered()
	var flash:Color=viewport.get_texture().get_image().get_pixel(48,16)
	check("flash_preserves_alpha",absf(flash.a-repaired.a)<.008 and flash.r>repaired.r and flash.g>repaired.g,flash)
	viewport.queue_free();await frames(2)
	host=load("res://content/whalebelly/main.tscn").instantiate();host.qa=true;host.integration_external_test=true;host.qa_full_abilities=false;root.add_child(host);current_scene=host
	await frames(35)
	for room_id in [0,1]:
		host.load_room(room_id);await frames(20)
		host.set_process(false);paused=true
		var mats:Array=[]
		for node in host.player.get_node("Visual").get_children():
			if node is CanvasItem and node.material is ShaderMaterial:
				mats.append(node.material);node.material.shader=legacy
		await shot("room%d-before"%room_id)
		for mat:ShaderMaterial in mats:mat.shader=fixed
		await shot("room%d-after"%room_id)
		var walk:Node=host.player.get_node_or_null("Visual/WalkAnimation")
		check("room%d_body_and_walk_share_fix"%room_id,host.player.body.material.shader==fixed and (walk==null or walk.material.shader==fixed),{"walk_animation_present":walk!=null})
		paused=false;host.set_process(true)
	Input.action_press("tp_right");await frames(12);Input.action_release("tp_right");await shot("walk-after")
	await frames(12);host.player.request_action("strike_01");Input.action_press("tp_right");await frames(7);await shot("moving-attack-after");Input.action_release("tp_right")
	check("layered_attack_uses_fixed_material",host.player.get_node("Visual/Legs").material.shader==fixed)
	var failed:int=checks.filter(func(c):return not c.pass).size()
	var f:=FileAccess.open(OUT+"tests.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failed":failed},"\t"));f.close()
	print("CHARACTER_COLOR_COMPLETE checks=",checks.size()," failed=",failed)
	host.graceful_quit(1 if failed else 0)
