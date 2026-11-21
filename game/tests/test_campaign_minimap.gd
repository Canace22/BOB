extends TestSuite

func make_map(id: String) -> WhaleCampaignMinimap:
	var host := WhalebellyMain.new()
	host.rooms = CampaignWorld.load_rooms(JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json")))
	for i: int in host.rooms.size():
		if str(host.rooms[i].id) == id:
			host.room_index = i
			host.room = host.rooms[i]
	host.visited[id] = true
	var map := WhaleCampaignMinimap.new()
	map.size = Vector2(292,204)
	map.data = WhaleUICampaignData.new()
	map.data.host = host
	map.refresh()
	return map

func release_map(map: WhaleCampaignMinimap) -> void:
	map.data.host.free()
	map.free()

func test_hub_exits_preserve_real_height_and_uniform_scale() -> void:
	var map := make_map("R3-01")
	eq(map.exits.size(),3,"Hub has its three actual exits")
	var lower: Vector2 = map.project(map.exits[0].point)
	var upper: Vector2 = map.project(map.exits[2].point)
	check(upper.y < lower.y-20,"Strong-current exit visibly sits above the lower return")
	check(is_equal_approx(lower.y-upper.y,720*map.scale_factor),"Exit height uses the actual 720px difference")
	check(is_equal_approx(map.plot.size.x/map.plot.size.y,map.room_size.x/map.room_size.y),"Room and platforms retain their real aspect ratio")
	eq(map.exits[2].label,"组合门","Exit legend names its actual destination")
	release_map(map)

func test_each_room_only_shows_its_actual_exits_without_future_discovery() -> void:
	var first := make_map("R1-01")
	var rooms: Array = first.data.host.rooms.duplicate(true)
	release_map(first)
	for room: Dictionary in rooms:
		var map := make_map(str(room.id))
		eq(map.exits.size(),room.get("doors",[]).size(),"Only current-room exits appear in "+str(room.id))
		for exit: Dictionary in map.exits:
			check(map.plot.grow(1).has_point(map.project(exit.point)),"Exit lies inside the proportional room plan")
			check(not exit.label.is_empty(),"Each number has a destination legend")
		eq(map.data.host.visited.size(),1,"Drawing routes does not discover other rooms")
		release_map(map)

func test_gate_and_boss_status_use_the_owning_room() -> void:
	var map := make_map("R3-01")
	check(map._blocked("R1-04",{"to":4,"ability":"boss"}),"Remote Boss door stays restricted before victory")
	map.data.host.defeated["R1-04:0"] = true
	check(not map._blocked("R1-04",{"to":4,"ability":"boss"}),"Remote Boss victory opens its own door")
	check(map.exits[2].blocked,"Missing mark restricts the actual hub exit")
	map.data.host.abilities.pressure = true
	map.refresh()
	check(not map.exits[2].blocked,"Granted mark clears the exit without changing discovery")
	check(map._blocked("R3-01",{"to":-2}),"Unbuilt exit is visibly closed")
	release_map(map)
