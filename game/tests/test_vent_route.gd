extends TestSuite

func test_vent_map_guides_normal_unlock_and_return() -> void:
	var host := WhalebellyMain.new()
	host.qa_full_abilities = false
	host.rooms = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	host.visited = {"R1-02":true}
	var data := WhaleUICampaignData.new()
	data.host = host
	check(data.room_description(5).contains("鲸须记忆袋"),"Unvisited float route names the real unlock source")
	check(WhaleUIMapPage.short_detail(host,"R1-06").contains("记忆袋"),"Compact map names the unlock source")
	host.abilities.float = true
	check(data.room_description(5).contains("逐层上行"),"Earned ability exposes ascent instructions before entry")
	check(WhaleUIMapPage.short_detail(host,"R1-06").contains("左侧"),"Compact map identifies the ascent side")
	host.visited["R1-06"] = true
	host.collected["R1-06"] = true
	var description := data.room_description(5)
	check(description.contains("已收集") and description.contains("原路返回"),"Collected branch keeps return information")
	check(not data.room_description(2).contains("逐层上行"),"Unrelated rooms have no vent route text")
	host.free()

func test_only_left_branch_platforms_allow_upward_passage() -> void:
	var scene: Node = load("res://content/whalebelly/r1/R1-02.tscn").instantiate()
	for index in range(5):
		var shape: CollisionPolygon2D = scene.get_node("World/Terrain/Surface%d/Contour" % index)
		eq(shape.one_way_collision,index in [1,2,3],"Only the three stacked float platforms are one-way")
	scene.free()
