extends TestSuite

func make_host(id: String) -> WhalebellyMain:
	var host := WhalebellyMain.new()
	host.rooms = CampaignWorld.load_rooms(JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json")))
	for i: int in host.rooms.size():
		if str(host.rooms[i].id)==id:
			host.room_index = i
			host.room = host.rooms[i]
	host.visited[id] = true
	return host

func test_junction_keeps_all_exits_and_reads_progress_without_writing() -> void:
	var host := make_host("R1-02")
	var before: int = hash([host.abilities,host.visited,host.collected,host.defeated])
	var routes: Array[Dictionary] = WhaleCampaignRouteHUD.destinations(host)
	var targets: Array[int] = []
	for door: Dictionary in host.room.doors:
		if int(door.to)>=0 and not targets.has(int(door.to)): targets.append(int(door.to))
	eq(routes.size(),targets.size(),"Junction displays every built destination, not only next_room")
	check(routes.size()>=3,"Fixture is a real multi-exit room")
	check(routes.any(func(route: Dictionary) -> bool: return route.main),"Main route is distinguished")
	check(routes.any(func(route: Dictionary) -> bool: return route.blocked),"Locked optional routes are labelled instead of hidden")
	eq(hash([host.abilities,host.visited,host.collected,host.defeated]),before,"HUD cannot discover rooms or grant progress")
	host.free()

func test_invalid_and_duplicate_targets_are_not_misleading_exits() -> void:
	var host := make_host("R1-01")
	host.room = host.room.duplicate(true)
	host.room.doors.append(host.room.doors[0].duplicate(true))
	host.room.doors.append({"to":-2,"pos":[200,500]})
	host.room.doors.append({"to":999,"pos":[300,500]})
	eq(WhaleCampaignRouteHUD.destinations(host).size(),1,"Unavailable world areas and duplicates are not shown as navigable destinations")
	host.free()

func test_projection_and_same_edge_spacing_preserve_every_marker() -> void:
	var boundary := Rect2(24,174,1232,342)
	var center := Vector2(640,360)
	for ray: Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN,Vector2(2,-3)]:
		var point: Vector2 = WhaleCampaignRouteHUD.edge_point(center,ray,boundary)
		check(boundary.grow(0.01).has_point(point),"Projected marker stays inside HUD-safe bounds")
	var hud := WhaleCampaignRouteHUD.new()
	for i: int in 4: hud.markers.append({"side":"right","at":Vector2(1256,360)})
	hud._separate(boundary)
	for i: int in hud.markers.size():
		check(boundary.grow(0.01).has_point(hud.markers[i].at),"Every exit remains in bounds")
		if i>0: check(hud.markers[i].at.distance_to(hud.markers[i-1].at)>=63,"Same-edge labels are separated")
	hud.free()
