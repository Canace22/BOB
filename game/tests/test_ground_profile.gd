extends TestSuite
## Independent landmarks measured on the painted ROAD deck, not its alpha silhouette.

func test_first_room_matches_painted_deck_and_physics() -> void:
	var rooms: Array = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var surface: Array = rooms[0].surfaces[0]
	var room: Node2D = load("res://content/whalebelly/r1/R1-01.tscn").instantiate()
	var environment: Node2D = room.get_node("ReferenceEnvironment")
	var road: Sprite2D = environment.get_node("ROAD")
	var contour: CollisionPolygon2D = room.get_node("World/Terrain/Surface0/Contour")
	# Full reference-image coordinates: flat approach, crest, reported right slope, low exit.
	for landmark: Vector2 in [Vector2(310,469),Vector2(640,400),Vector2(740,410),Vector2(1000,505)]:
		var expected: Vector2 = landmark * environment.scale
		var found: bool = false
		for point: Array in surface:
			if Vector2(point[0],point[1]).distance_to(expected)<0.01: found = true
		check(found,"painted road landmark %s" % landmark)
	eq(road.position,Vector2(0,392),"road artwork remains in its authored position")
	eq(contour.polygon.size(),surface.size()*2,"closed solid road strip")
	for i in surface.size():
		var point := Vector2(surface[i][0],surface[i][1])
		check(contour.polygon[i].distance_to(point)<0.001,"save/ground lookup matches collider")
		if i>0:
			var delta: Vector2 = point-contour.polygon[i-1]
			check(absf(atan2(delta.y,delta.x))<deg_to_rad(55),"walkable slope within player limit")
	room.free()
