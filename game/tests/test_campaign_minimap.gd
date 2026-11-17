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
	map.data = WhaleUICampaignData.new()
	map.data.host = host
	map.refresh()
	return map

func release_map(map: WhaleCampaignMinimap) -> void:
	map.data.host.free()
	map.free()

func test_discovery_and_stable_room_positions() -> void:
	var map := make_map("R1-01")
	eq(map.rooms.size(),2,"Opening only reveals start and its neighbour")
	var start: Vector2 = map.positions[0]
	map.data.host.visited["R1-02"] = true
	map.refresh()
	eq(map.rooms.size(),5,"Exploring the junction reveals its branches")
	eq(map.positions[0],start,"New discoveries never move existing rooms")
	check(not map.positions.has(3),"Undiscovered Boss room stays hidden")
	release_map(map)

func test_every_region_has_non_overlapping_cells_and_current_room() -> void:
	for id: String in ["R1-01","R2-03","R3-01","R4-06","R5-08"]:
		var map := make_map(id)
		check(map.positions.has(map.data.host.room_index),"Current room is visible in " + id)
		var points: Array = []
		for point: Vector2 in WhaleCampaignMinimap.CELLS[map.page].values():
			check(not points.has(point),"Room cells do not overlap in " + map.page)
			points.append(point)
		release_map(map)

func test_gate_and_boss_status_use_the_owning_room() -> void:
	var map := make_map("R3-01")
	check(map._blocked("R1-04",{"ability":"boss"}),"Remote Boss door stays restricted before victory")
	map.data.host.defeated["R1-04:0"] = true
	check(not map._blocked("R1-04",{"ability":"boss"}),"Remote Boss victory opens its own door")
	check(map._blocked("R3-01",{"requires":["pressure"]}),"Missing mark restricts passage")
	map.data.host.abilities.pressure = true
	check(not map._blocked("R3-01",{"requires":["pressure"]}),"Granted mark opens passage")
	release_map(map)
