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

func test_prompt_clearance_cannot_reverse_exit_direction() -> void:
	# 长交互提示压低HUD安全区底线，主角仍在画面中心；不能用负交点把左门显示到右侧。
	var center := Vector2(640,360)
	var boundary := Rect2(24,108,1232,192)
	for ray: Vector2 in [Vector2(-500,60),Vector2(500,60),Vector2(-500,-60),Vector2(500,-60)]:
		var at: Vector2 = WhaleCampaignRouteHUD.edge_point(center,ray,boundary)
		check(boundary.grow(0.01).has_point(at),"Long-prompt marker remains on safe boundary")
		check((at.x-center.x)*ray.x>=0,"Projection never reverses the real horizontal direction")
	var straight_left: Vector2 = WhaleCampaignRouteHUD.edge_point(center,Vector2.LEFT,boundary)
	eq(straight_left.x,boundary.position.x,"A left exit stays on the left even if origin lies below safe area")

func test_streaming_room_switch_uses_destination_connection_end() -> void:
	var host := make_host("R1-02")
	var stream := CampaignRoomStream.new()
	stream.host = host
	stream.layout = CampaignStreamingLayout.build(host.rooms)
	host.streaming = stream
	var back: Dictionary = WhaleCampaignRouteHUD.destinations(host).filter(func(route: Dictionary) -> bool: return route.id=="R1-01")[0]
	var origin: Vector2 = stream.origin(host.room_index)
	var at_entry: Vector2 = origin+Vector2(12,700)
	check(origin.x+Vector2(back.point).x>at_entry.x,"Old room-local doorway lies ahead just after ownership switches")
	var target: Vector2 = WhaleCampaignRouteHUD.route_world_point(host,back)
	check(target.x<at_entry.x,"Return marker points toward the actual left room at seam entry")
	stream.free()
	host.free()
