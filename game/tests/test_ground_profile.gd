extends TestSuite
## Current authored deck, visible bitmap and physics share one contact line.

func test_first_room_matches_painted_deck_and_physics() -> void:
	var source: Array = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var data: Dictionary = CampaignWorld.load_rooms(source)[0]
	var recipes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://content/whalebelly/layout/recipes.json")).rooms
	var recipe: Dictionary = recipes.filter(func(value: Dictionary) -> bool: return str(value.id) == "R1-01")[0]
	var room: Node2D = load(CampaignWorld.scene_path("R1-01")).instantiate()
	eq(data.spawn, [180.0, 720.0], "Safe starting bank remains at its authored height")
	eq(data.doors[0].pos, [1510.0, 790.0], "Exit remains below the jaw crest")
	eq(recipe.platforms[2].y, 510.0, "Jaw crest remains above the starting bank")
	eq(data.surfaces.size(), recipe.platforms.size(), "Every authored bank has runtime ground data")
	for index: int in recipe.platforms.size():
		var platform: Dictionary = recipe.platforms[index]
		var surface: Array = data.surfaces[index]
		var contour: CollisionPolygon2D = room.get_node("World/Terrain/%s/Contour" % platform.id)
		eq(contour.polygon.size(), surface.size() + 2, "Closed solid strip: " + str(platform.id))
		check(not Geometry2D.triangulate_polygon(contour.polygon).is_empty(), "Collision polygon has no crossing edges: " + str(platform.id))
		for i: int in surface.size():
			var point := Vector2(float(surface[i][0]), float(surface[i][1]))
			check(contour.polygon[i].distance_to(point) < 0.001, "Ground lookup matches collision: %s/%d" % [platform.id, i])
			if i > 0:
				var delta: Vector2 = point - contour.polygon[i - 1]
				check(absf(atan2(delta.y, delta.x)) < deg_to_rad(55), "Walkable deck slope stays within player limit")
			if i > 0 and i < surface.size() - 1:
				check(painted_contact(room, str(platform.id), point), "Collider rests on opaque authored deck: %s/%d" % [platform.id, i])
	room.free()

func painted_contact(room: Node2D, id: String, point: Vector2) -> bool:
	for node: Node in room.get_node("World/Art").get_children():
		if not node is Sprite2D or not str(node.name).begins_with(id + "_"): continue
		var sprite: Sprite2D = node
		check(is_equal_approx(absf(sprite.scale.x), absf(sprite.scale.y)), "Deck bitmap retains uniform scale")
		var image: Image = sprite.texture.get_image()
		var pixel: Vector2 = (point - sprite.position) / sprite.scale
		for dx: int in range(-2, 3):
			for dy: int in range(-2, 3):
				var x: int = roundi(pixel.x) + dx
				var y: int = roundi(pixel.y) + dy
				if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height() and image.get_pixel(x, y).a >= 0.45: return true
	return false
