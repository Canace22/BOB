extends TestSuite

func test_xumen_painted_approach_has_collision_under_its_visible_lip() -> void:
	var host: WhalebellyMain=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true
	host.integration_external_test=true
	add(host)
	await physics_frames(5)
	host.load_room(1)
	await physics_frames(5)
	var origin: Vector2=host.streaming.origin(1)
	for x: int in range(1300,1410,10):
		var from: Vector2=origin+Vector2(x,680)
		var to: Vector2=origin+Vector2(x,735)
		var query:=PhysicsRayQueryParameters2D.create(from,to,1)
		var hit: Dictionary=host.get_world_2d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty(),"Painted approach cannot be hollow at room x="+str(x))
		if not hit.is_empty():
			check(absf(Vector2(hit.position).y-host.ground_y(x,714)-origin.y)<1.0,"Ground lookup and actual collider share the same top")

func test_prepare_is_idempotent_and_keeps_authored_platforms_unchanged() -> void:
	var source: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var room: Dictionary=CampaignWorld.load_rooms(source)[1]
	var original: Array=room.surfaces.duplicate(true)
	var scene: Node2D=load(CampaignWorld.scene_path(str(room.id))).instantiate()
	var terrain: Node=scene.get_node("World/Terrain")
	var count: int=terrain.get_child_count()
	CampaignPaintedSupports.prepare_scene(scene,room)
	CampaignPaintedSupports.prepare_scene(scene,room)
	eq(terrain.get_child_count(),count+1,"Preparing a neighbor twice adds one measured support")
	eq(room.surfaces,original,"Existing authored platforms remain unchanged")
	var support: Node=terrain.get_node("PaintedSupport0")
	var shape: CollisionPolygon2D=support.get_child(0)
	check(shape.one_way_collision,"Jumping from below still passes through the new bank")
	check(not Geometry2D.triangulate_polygon(shape.polygon).is_empty(),"Measured support has a valid collider")
	scene.free()

func test_measured_ground_query_keeps_other_heights_and_room_data_isolated() -> void:
	var source: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var first: Array=CampaignWorld.load_rooms(source)
	var second: Array=CampaignWorld.load_rooms(source)
	eq(CampaignPaintedSupports.ground_y(first[1],1340,714,714,150),714.0,"Painted top is queried at its measured height")
	eq(CampaignPaintedSupports.ground_y(first[1],1340,1000,1000,150),1000.0,"Lower authored routes are not snapped onto the upper bank")
	first[1].painted_supports[0][0][0]=0
	eq(second[1].painted_supports[0][0][0],1280,"Independent room loads do not share mutable support points")

func test_saved_point_on_painted_support_does_not_take_legacy_projection() -> void:
	var source: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var room: Dictionary=CampaignWorld.load_rooms(source)[1]
	eq(CampaignLayout.restore_point(room,Vector2(1340,714)),Vector2(1340,714),"New support checkpoint retains its current room coordinates")
	eq(CampaignLayout.restore_point(room,Vector2(1340,713.96)),Vector2(1340,714),"Physics floor tolerance restores onto the same measured support")

func test_branch_replacements_match_live_path_and_correct_screenshot_checkpoint() -> void:
	var source: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var rooms: Array=CampaignWorld.load_rooms(source)
	var layout: Dictionary=CampaignStreamingLayout.build(rooms)
	var link: Dictionary=layout.links.filter(func(edge: Dictionary) -> bool: return edge.a==1 and edge.b==6)[0]
	var measured: Dictionary=CampaignPaintedSupports.corridor_data(layout,link)
	var origin: Vector2=layout.origins[1]
	for point: Array in measured.replace:
		var local:=Vector2(point[0],point[1])
		var matched: bool=false
		for at: Vector2 in PackedVector2Array(link.path):
			if at.distance_to(origin+local)<0.1: matched=true
		check(matched,"Measured replacement names an existing corridor platform")
	check(not CampaignPaintedSupports.replaces(measured,Vector2(1705,22.3077)),"The next separate stair remains intact")
	var room: Dictionary=rooms[1]
	var expected:=Vector2(1835,137.5)
	eq(CampaignLayout.restore_point(room,expected),expected,"Current slope checkpoint stays outside the original room bounds")
	eq(CampaignLayout.restore_point(room,Vector2(1835,210)),expected,"Old floating checkpoint projects onto the painted slope")
	eq(CampaignLayout.restore_point(room,Vector2(1340,714)),Vector2(1340,714),"Existing main-route checkpoint remains unchanged")

func test_branch_physics_follows_painted_slope_without_old_horizontal_plate() -> void:
	var host: WhalebellyMain=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true
	host.integration_external_test=true
	add(host)
	await physics_frames(5)
	host.load_room(1)
	await physics_frames(5)
	var origin: Vector2=host.streaming.origin(1)
	for x: int in [1690,1740,1780,1820,1835,1860,1895,1940]:
		var expected: float=host.ground_y(x,160)
		var from: Vector2=origin+Vector2(x,expected-12)
		var to: Vector2=origin+Vector2(x,expected+8)
		var hit: Dictionary=host.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from,to,1))
		check(not hit.is_empty(),"Painted sloping lip has physical support at "+str(x))
		if not hit.is_empty(): check(absf(Vector2(hit.position).y-origin.y-expected)<0.1,"Physics and floor query agree on the slope")
	var old_top: Vector2=origin+Vector2(1835,209)
	var ghost: Dictionary=host.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(old_top,old_top+Vector2(0,4),1))
	check(ghost.is_empty(),"The invisible old horizontal platform is removed")
