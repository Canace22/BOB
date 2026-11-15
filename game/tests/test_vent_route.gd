extends TestSuite

func test_vent_map_guides_normal_unlock_and_return() -> void:
	var host := WhalebellyMain.new()
	host.qa_full_abilities = false
	host.rooms = CampaignWorld.load_rooms(JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json")))
	host.visited = {"R1-02":true}
	var data := WhaleUICampaignData.new()
	data.host = host
	check(data.room_description(5).contains("鲸须记忆袋"),"Unvisited float route names the real unlock source")
	check(WhaleUIMapPage.short_detail(host,"R1-06").contains("记忆袋"),"Compact map names the unlock source")
	host.abilities.float = true
	check(data.room_description(5).contains("交替"),"Earned ability explains the authored alternating ascent before entry")
	check(WhaleUIMapPage.short_detail(host,"R1-06").contains("交替"),"Compact map identifies the alternating float route")
	host.visited["R1-06"] = true
	host.collected["R1-06"] = true
	var description := data.room_description(5)
	check(description.contains("已收集") and description.contains("原路返回"),"Collected branch keeps return information")
	check(not data.room_description(2).contains("逐层上行"),"Unrelated rooms have no vent route text")
	host.free()

func test_only_optional_upper_banks_allow_upward_passage() -> void:
	var scene: Node = load("res://content/whalebelly/r1/R1-02.tscn").instantiate()
	var recipes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://content/whalebelly/layout/recipes.json")).rooms
	var recipe: Dictionary = recipes.filter(func(value: Dictionary) -> bool: return str(value.id) == "R1-02")[0]
	var passable: Array[String] = []
	for platform: Dictionary in recipe.platforms:
		var shape: CollisionPolygon2D = scene.get_node("World/Terrain/%s/Contour" % platform.id)
		eq(shape.one_way_collision, bool(platform.get("one_way", false)), "Authored upward passage: " + str(platform.id))
		if shape.one_way_collision: passable.append(str(platform.id))
	eq(passable, ["Surface7", "Surface8", "Surface9", "Surface10"], "Three float steps and the anchor-route memory bank pass upward; main trench banks stay solid")
	for wall: Dictionary in recipe.walls:
		var shape: CollisionPolygon2D = scene.get_node_or_null("World/Terrain/%s/Contour" % wall.id)
		if wall.get("removed",false):
			check(shape==null,"User-removed column has no invisible wall: " + str(wall.id))
		else:
			check(shape!=null,"Retained wall has its collider: " + str(wall.id))
			if shape!=null: check(not shape.one_way_collision, "Bone walls remain solid from both sides: " + str(wall.id))
	scene.free()
