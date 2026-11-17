extends TestSuite

func test_every_world_connection_has_registered_art_and_keeps_aspect() -> void:
	var records: Array=JSON.parse_string(FileAccess.get_file_as_string(CampaignSeamArt.DATA))
	var world: Dictionary=CampaignStreamingLayout.build(CampaignWorld.load_rooms(JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))))
	eq(records.size(),world.links.size(),"Every connection has a joint painting")
	for record: Dictionary in records:
		var path: String="res://art/seamless-continuity-v1/"+str(record.id)+".png"
		var texture: Texture2D=load(path)
		check(texture!=null,"Joint painting loads: "+str(record.id))
		if texture==null: continue
		var ratio: float=float(record.world[2])/float(record.world[3])
		check(is_equal_approx(ratio,float(texture.get_width())/texture.get_height()),"World registration preserves aspect: "+str(record.id))
		check(record.world[2]>0 and record.world[3]>0,"Patch world size is positive")

func test_vertical_routes_use_clean_depth_and_registered_separate_ledges() -> void:
	for id: String in ["R1-02--R1-06","R1-02--R1-07","R3-01--R2-01","R4-06--R5-08"]:
		check(ResourceLoader.exists("res://art/seamless-continuity-v1/"+id+"-depth.png"),"Shaft has a clean background: "+id)
	var world: Dictionary=CampaignStreamingLayout.build(CampaignWorld.load_rooms(JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))))
	var corridors:=CampaignStreamingCorridors.new()
	corridors.layout=world
	add(corridors)
	corridors.build()
	var ledges: Array[Node]=corridors.find_children("RegisteredLedge","Sprite2D",true,false)
	check(not ledges.is_empty(),"Shaft ledges are separate bitmap drawables")
	for ledge: Sprite2D in ledges:
		check(is_equal_approx(absf(ledge.scale.x),absf(ledge.scale.y)),"Ledge keeps equal scale with optional horizontal mirror")
		check(ledge.texture!=null,"Ledge texture actually loads")

func test_ownership_patches_are_bounded_and_core_is_preserved() -> void:
	var patches: PackedVector4Array=CampaignSeamArt.patches_for(Vector2.ZERO)
	eq(patches.size(),1,"First room only owns its actual neighboring seam")
	for patch: Vector4 in patches: check(patch.z>0 and patch.w>0,"Ownership patch is a world rectangle")
	var shader: Shader=load("res://src/campaign/seam_art.gdshader")
	check(shader.code.contains("protected_rooms"),"Large U-shaped seam excludes unrelated room cores")
	check(shader.code.contains("140.0,280.0"),"Only the narrow boundary overlap replaces original room pixels")

func test_horizontal_connections_have_transparent_terrain_layers() -> void:
	var records: Array = JSON.parse_string(FileAccess.get_file_as_string(CampaignSeamArt.DATA))
	var layers: int = 0
	for record: Dictionary in records:
		var original: String = "res://art/seamless-continuity-v1/"+str(record.id)
		if ResourceLoader.exists(original+"-depth.png"): continue
		var terrain: Texture2D = load("res://art/continuous-backdrops-v1/terrain/"+str(record.id)+".png")
		check(terrain!=null,"Horizontal route has its own RGBA terrain: "+str(record.id))
		if terrain!=null:
			var source: Texture2D = load(original+".png")
			check(terrain.get_size()==source.get_size(),"Layer preserves full original canvas and pixel registration")
		layers+=1
	eq(layers,14,"All fourteen horizontal seams separate terrain from background")
