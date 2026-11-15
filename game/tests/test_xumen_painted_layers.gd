extends TestSuite

func test_authored_root_profile_reaches_the_actual_shader() -> void:
	var part := ChapterPinnedBitmap.new()
	part.texture = load("res://art/r1-chapter-scenes/R1-02/R1-02-BALEEN-1.png")
	part.root_profile = PackedFloat32Array([.01,.01,.01,.01,.01,.01,.01,.01,.016,.024,.033,.079,.128])
	part._ready()
	var surface := part.material as ShaderMaterial
	eq(surface.get_shader_parameter("root_heights"),part.root_profile,"Non-flat authored root line must reach the shader, not its default zeros")
	part.free()

func test_original_layer_camera_response_is_bounded_at_room_edges() -> void:
	var layer := XumenPaintedLayer.new()
	layer.room_center = Vector2(820,560)
	for p: Vector2 in [Vector2(-500,-500),Vector2(3000,3000),Vector2(820,560)]:
		var offset := layer.offset_for(p)
		check(absf(offset.x)<=8 and absf(offset.y)<=5,"Painted roof/root registration stays inside its prepared margin")
	layer.free()
