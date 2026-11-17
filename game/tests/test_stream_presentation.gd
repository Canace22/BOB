extends TestSuite

const Presentation = preload("res://src/campaign/stream_presentation.gd")

func test_plain_drawables_keep_hierarchy_z_and_independent_room_uniforms() -> void:
	var root := Node2D.new()
	var parent := Node2D.new()
	root.add_child(parent)
	var first := Sprite2D.new()
	first.z_index = -30
	parent.add_child(first)
	var second := Sprite2D.new()
	second.z_index = 20
	parent.add_child(second)
	var origin := Vector2(5600,-1200)
	Presentation.apply(root,origin,Vector2(1672,941))
	var material: ShaderMaterial = first.material
	check(root.material == null and parent.material == null,"Empty room containers retain their rendering inheritance")
	check(first.get_parent() == parent and first.z_index == -30 and second.z_index == 20,"Presentation preserves hierarchy and draw ordering")
	eq(material.get_shader_parameter("stream_room_origin"),origin,"Fade uses the room world origin")
	eq(material.get_shader_parameter("stream_room_size"),Vector2(1672,941),"Fade uses the authored room size")
	eq(material.get_shader_parameter("stream_fade_width"),100.0,"Fade occupies only the 100px edge strip")
	check(first.material != second.material and material.shader == (second.material as ShaderMaterial).shader,"Drawables share a shader but retain independent uniforms")
	Presentation.apply(root,origin,Vector2(1672,941))
	eq(first.material,material,"Crossing reuses already prepared materials rather than duplicating the room again")
	root.free()

func test_injection_preserves_existing_shader_logic_parameters_and_nested_blocks() -> void:
	var source := Shader.new()
	source.code = "shader_type canvas_item;\nuniform float clock = 0.0;\nvoid vertex() { if (VERTEX.x > 0.0) { VERTEX.x += clock; } }\nvoid fragment() { /* } must not close the body */ if (UV.x > 0.5) { COLOR.rgb *= 0.5; } }\n"
	var original := ShaderMaterial.new()
	original.shader = source
	original.set_shader_parameter("clock",7.5)
	var room := Node2D.new()
	var first := Sprite2D.new()
	first.material = original
	room.add_child(first)
	var second := Sprite2D.new()
	second.material = original
	room.add_child(second)
	Presentation.apply(room,Vector2(2000,0),Vector2(1600,900))
	var material: ShaderMaterial = first.material
	check(material != original and first.material != second.material,"Existing materials are duplicated per node")
	check(material.shader != source and material.shader == (second.material as ShaderMaterial).shader,"Source shader is unchanged and injected shader is cached")
	eq(material.get_shader_parameter("clock"),7.5,"Original uniform values survive shader injection")
	material.set_shader_parameter("clock",8.0)
	eq(material.get_shader_parameter("clock"),8.0,"Environment scripts can continue updating the node material")
	eq((second.material as ShaderMaterial).get_shader_parameter("clock"),7.5,"Updating one material does not affect another node")
	check(material.shader.code.contains("VERTEX.x += clock;") and material.shader.code.contains("COLOR.rgb *= 0.5;"),"Original vertex and fragment calculations are preserved")
	var first_shader: Shader = material.shader
	Presentation.apply(room,Vector2.ZERO,Vector2(1600,900))
	check((first.material as ShaderMaterial).shader.code.count("uniform vec2 stream_room_origin") == 1,"Reapplying presentation does not inject uniforms twice")
	check(first_shader.code == (first.material as ShaderMaterial).shader.code,"Reapplying presentation preserves the generated calculations")
	room.free()

func test_existing_additive_material_keeps_its_blend_mode() -> void:
	var room := Node2D.new()
	var light := Sprite2D.new()
	var original := CanvasItemMaterial.new()
	original.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	original.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	light.material = original
	room.add_child(light)
	Presentation.apply(room,Vector2.ZERO,Vector2(1600,900))
	var material: ShaderMaterial = light.material
	check(material.shader.code.contains("render_mode blend_add, unshaded;"),"Converting a light preserves its blend and lighting modes")
	room.free()
