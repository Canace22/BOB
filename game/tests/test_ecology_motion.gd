extends TestSuite

func test_current_rooms_own_ecology_without_campaign_injection() -> void:
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CampaignRoomEcology.DATA))
	for id: String in document.rooms:
		var scene: Node2D = load(CampaignWorld.scene_path(id)).instantiate()
		var ecology: CampaignRoomEcology = scene.get_node_or_null("RoomEcology")
		check(ecology != null,"current room scene owns ecology: "+id)
		if ecology != null: eq(ecology.room_id,id,"authored ecology uses stable room id")
		add(scene)
		if ecology != null:
			check(not ecology.animated.is_empty(),"direct scene instantiation constructs ecology: "+id)
			eq(str(ecology.room_data.id),id,"direct scene resolves its current room data")
		scene.queue_free()
		await tree.process_frame

func test_xumen_uses_cool_ecology_and_r1_04_has_no_portal_art() -> void:
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CampaignRoomEcology.DATA))
	for id: String in ["R1-01", "R1-02", "R1-03", "R1-04", "R1-05", "R1-06", "R1-07"]:
		check(not bool(document.rooms[id].get("warm", true)),"Xumen ecology is cool toned: "+id)
	var portal_scene: String = FileAccess.get_file_as_string("res://content/whalebelly/r1/R1-04.tscn")
	check(not portal_scene.contains("PORTAL.png"),"R1-04 black portal texture removed")
	check(not portal_scene.contains("tunnel_texture"),"R1-04 portal visual has no tunnel texture")
	check(portal_scene.count("height = 0.0") == 2,"R1-04 doorway logic remains while art height is zero")

func test_every_room_has_environment_specific_ecology_design() -> void:
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CampaignRoomEcology.DATA))
	for room: Dictionary in document.rooms.values():
		var design: Dictionary = room.get("ecology_design", {})
		check(design.has_all(["habitat", "life", "summary", "layers"]),"ecology design fields exist: "+str(room.name))
		check(design.layers.size() == 3,"far/middle/foreground layers declared: "+str(room.name))
		check(room.has("bubble_population") and room.has("plankton_tint"),"bubble/plankton profile exists: "+str(room.name))

func test_xumen_has_no_black_portal_art() -> void:
	for path: String in DirAccess.get_files_at("res://content/whalebelly/r1"):
		if not path.ends_with(".tscn"): continue
		var source: String = FileAccess.get_file_as_string("res://content/whalebelly/r1/"+path)
		check(not source.contains("tunnel_texture"),"black portal tunnel art removed: "+path)
		check(not source.contains("height = 170.0"),"black portal height disabled: "+path)

func test_amphipod_updates_the_rendered_stream_material() -> void:
	var school := KitAmphipodSchool.new()
	school.texture = preload("res://art/world-kit/r2-pelagic-amphipod-v4.png")
	school.population = 2
	add(school)
	var sprite: Sprite2D = school.members[0].node
	var original: ShaderMaterial = sprite.material
	CampaignStreamPresentation.apply(school,Vector2.ZERO,Vector2(2000,1500))
	check(sprite.material != original,"streaming must exercise a replaced material")
	school.update_at(4.0)
	eq(sprite.material.get_shader_parameter("clock"),4.0,"local swimming follows actual rendered material")

func test_colonies_support_curved_multisegment_banks() -> void:
	var ecology := CampaignRoomEcology.new()
	ecology.room_data = {"size":[1000,800],"surfaces":[[[100,500],[200,505],[300,510],[400,500]]]}
	var point_: Vector2 = ecology.attachment_point([0.25,0.6])
	check(point_.is_finite(),"dense curve segments must retain attachment support")
	eq(point_,Vector2(250,507.5),"root follows painted surface interpolation")
	ecology.free()
