extends TestSuite

func test_world_panorama_replaces_room_water_and_far_organs_together() -> void:
	var room := Node2D.new()
	var water := Sprite2D.new()
	water.texture = load("res://art/world-kit/r2-water-base.png")
	room.add_child(water)
	var organs := Sprite2D.new()
	organs.texture = load("res://art/world-kit/r2-lung-far-layer.png")
	room.add_child(organs)
	CampaignStreamPresentation.apply(room,Vector2.ZERO,Vector2(2240,1840))
	check(not water.visible and water.material==null,"Finite opaque water yields to the shared world plane")
	check(not organs.visible and organs.material==null,"Room organ cutouts yield to the continuous anatomical panorama")
	check(not CampaignStreamWater.owns(load("res://art/r1-chapter-scenes/R1-02/underpaint.png")),"Structural chapter underpaint is never mistaken for plain water")
	room.free()

func test_terrain_outline_survives_room_edge_but_retains_patch_ownership() -> void:
	var scene: Node2D = load("res://content/whalebelly/r2/R2-01.tscn").instantiate()
	CampaignStreamPresentation.apply(scene,Vector2.ZERO,Vector2(2240,1840))
	var bed: Sprite2D = scene.get_node("World/Art/Bed0_2")
	check(not bed.visible and bed.get_meta("stream_master_terrain",false),"Original bed yields to the same pixels in world master chunks")
	check(not scene.get_node("Far/Organs/Art").visible,"Old far cutout cannot reappear at the room border")
	check(bed.material==null,"Baked ground no longer receives a room or seam fade material")
	scene.free()

func test_world_water_covers_every_biome_without_resident_room_state() -> void:
	var base: Array = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var layout: Dictionary = CampaignStreamingLayout.build(CampaignWorld.load_rooms(base))
	var sprite: Sprite2D = CampaignStreamWater.create(layout)
	var material: ShaderMaterial = sprite.material
	eq(material.get_shader_parameter("room_count"),19,"All room rectangles participate even when unloaded")
	eq(CampaignStreamWater.biome("R5-08"),5,"Tail uses its own full panorama")
	check(Rect2(sprite.position,sprite.region_rect.size).encloses(layout.bounds),"One world plane covers all camera edge views")
	sprite.free()

func test_six_complete_panorama_assets_and_world_anchors_cover_all_regions() -> void:
	eq(CampaignStreamWater.BACKDROPS.size(),6,"Mouth, lung, gastric, spine, cranial and tail each have a full background")
	for path: String in CampaignStreamWater.BACKDROPS:
		var texture: Texture2D = load(path)
		check(texture!=null and texture.get_width()==texture.get_height()*3,"Production panorama loads at its original 3:1 aspect")
	var scene: Node2D = load("res://content/whalebelly/r1/R1-03.tscn").instantiate()
	CampaignStreamPresentation.apply(scene,Vector2.ZERO,Vector2(1672,941))
	check(not scene.get_node("Far/Depth/Paint").visible,"World panorama replaces the finite structural background")
	check(not scene.get_node("Far/Depth/OriginalFar").visible,"Finite far painting also yields to the same panorama")
	check(scene.get_node("World/Art/MembraneArt").visible,"Dynamic membrane stays live")
	check(scene.get_node("Middle").visible,"Room environmental motion remains")
	scene.free()
