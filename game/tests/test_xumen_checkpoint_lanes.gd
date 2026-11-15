extends TestSuite
## Generated safe lanes are checked against the real scene collision polygons.

func layout_rooms() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string("res://content/whalebelly/layout/rooms.json")).rooms

func area(polygon: PackedVector2Array) -> float:
	var total: float = 0.0
	for index: int in polygon.size():
		total += polygon[index].cross(polygon[(index + 1) % polygon.size()])
	return absf(total) * 0.5

func occupied(scene: Node, left: float, right: float, foot: float, owner: String) -> String:
	var body := PackedVector2Array([Vector2(left - 18.0, foot - 94.0), Vector2(right + 18.0, foot - 94.0), Vector2(right + 18.0, foot), Vector2(left - 18.0, foot)])
	for solid: Node2D in scene.get_node("World/Terrain").get_children():
		if str(solid.name) == owner: continue
		var contour: CollisionPolygon2D = solid.get_node("Contour")
		if contour.one_way_collision: continue
		var polygon: PackedVector2Array = contour.polygon.duplicate()
		for index: int in polygon.size(): polygon[index] = solid.transform * contour.transform * polygon[index]
		for intersection: PackedVector2Array in Geometry2D.intersect_polygons(body, polygon):
			if area(intersection) > 0.01: return str(solid.name)
	return ""

func lane_at(room: Dictionary, point: Vector2) -> Dictionary:
	for lane: Dictionary in room.layout.checkpoint_lanes:
		if is_equal_approx(point.y, float(lane.y)) and point.x >= float(lane.x[0]) and point.x <= float(lane.x[1]): return lane
	return {}

func test_entire_generated_lane_body_envelopes_avoid_real_solid_polygons() -> void:
	var recipes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://content/whalebelly/layout/recipes.json")).rooms
	var rooms: Array = layout_rooms()
	for index: int in rooms.size():
		var room: Dictionary = rooms[index]
		var scene: Node = load("res://content/whalebelly/r1/%s.tscn" % room.id).instantiate()
		check(not room.layout.checkpoint_lanes.is_empty(), "At least one safe lane survives: " + str(room.id))
		for lane: Dictionary in room.layout.checkpoint_lanes:
			var owner: String = str(lane.get("surface_id", ""))
			check(not owner.is_empty(), "Generated lane names its supporting surface: " + str(room.id))
			var matches: Array = recipes[index].platforms.filter(func(spec: Dictionary) -> bool: return str(spec.id) == owner)
			if matches.is_empty():
				check(false, "Supporting platform exists: %s/%s" % [room.id, owner])
				continue
			var source: Dictionary = matches[0]
			check(float(lane.x[0]) >= float(source.x) + 35.0 and float(lane.x[1]) <= float(source.x) + float(source.w) - 35.0 and float(lane.x[0]) <= float(lane.x[1]), "Continuous lane remains within the original safe span: %s/%s" % [room.id, owner])
			eq(float(lane.y), float(source.y), "Safe-lane generation never moves a platform")
			var blocker: String = occupied(scene, float(lane.x[0]), float(lane.x[1]), float(lane.y), owner)
			check(blocker.is_empty(), "Full +/-18 by 94px lane envelope avoids %s: %s/%s" % [blocker, room.id, owner])
		scene.free()

func test_legacy_and_overlapping_checkpoint_points_project_to_unoccupied_lanes() -> void:
	for room: Dictionary in layout_rooms():
		var scene: Node = load("res://content/whalebelly/r1/%s.tscn" % room.id).instantiate()
		var original: Dictionary = room.duplicate(true)
		var probes: Array[Vector2] = [Vector2(-500, -500), Vector2(float(room.size[0]) + 100, float(room.size[1]) + 100)]
		if str(room.id) == "R1-03":
			probes.append_array([Vector2(1120, 225), Vector2(810, 746), Vector2(900, 680)])
		for probe: Vector2 in probes:
			var restored: Vector2 = CampaignLayout.restore_point(room, probe)
			var lane: Dictionary = lane_at(room, restored)
			check(not lane.is_empty(), "Checkpoint projects onto a retained safe span: %s/%s" % [room.id, probe])
			if not lane.is_empty():
				check(occupied(scene, restored.x, restored.x, restored.y, str(lane.surface_id)).is_empty(), "Restored player body avoids real walls and other solid platforms: %s/%s" % [room.id, probe])
		eq(room, original, "Checkpoint projection preserves layout/save metadata")
		scene.free()

func test_current_default_and_internal_door_spawns_are_not_migrated() -> void:
	var rooms: Array = layout_rooms()
	for room: Dictionary in rooms:
		var spawn := Vector2(float(room.spawn[0]), float(room.spawn[1]))
		eq(CampaignLayout.restore_point(room, spawn), spawn, "New default spawn remains exactly authored: " + str(room.id))
		for door: Dictionary in room.doors:
			var target_index: int = int(door.to)
			if target_index < 0 or target_index >= rooms.size(): continue
			var target: Dictionary = rooms[target_index]
			var arrival := Vector2(float(door.spawn[0]), float(door.spawn[1]))
			eq(CampaignLayout.restore_point(target, arrival), arrival, "New internal door arrival remains exactly authored: %s to %s" % [room.id, target.id])
