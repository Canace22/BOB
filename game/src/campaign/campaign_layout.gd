class_name CampaignLayout
extends RefCounted
## Runtime geometry contract for remapped rooms. No save file is changed here.

static func player_bounds(room: Dictionary, legacy_index: int = -1) -> Vector2:
	var size: Array = room.get("size", [1672, 941])
	var authored: Variant = room.get("layout", {}).get("player_bounds")
	if authored is Array and authored.size() == 2:
		return Vector2(float(authored[0]), float(authored[1]))
	var old_memory: bool = not room.has("layout") and (str(room.get("id", "")) == "R1-07" or legacy_index == 6)
	return Vector2(18.0, 1460.0 if old_memory else float(size[0]) - 18.0)

static func membrane(room: Dictionary, legacy_index: int = -1) -> Dictionary:
	if room.has("layout"): return room.layout.get("membrane", {})
	if str(room.get("id", "")) != "R1-03" and legacy_index != 2: return {}
	return {"load_rect":[700,580,270,140], "dive_rect":[700,-10000,270,10730],
		"rebound_rect":[700,730,270,10000], "contour_path":"World/Terrain/Surface0/Contour",
		"bend_from":680.0, "bend_to":1000.0, "max_drop":42.0,
		"art_paths":["World/WorldOriginalPixels", "ChapterEnvironment/World/Surface"]}

static func membrane_contains(room: Dictionary, zone: String, point: Vector2, legacy_index: int = -1) -> bool:
	var values: Variant = membrane(room, legacy_index).get(zone)
	if not values is Array or values.size() != 4: return false
	return point.x > float(values[0]) and point.x < float(values[0]) + float(values[2]) and point.y > float(values[1]) and point.y < float(values[1]) + float(values[3])

static func bent_polygon(original: PackedVector2Array, to_room: Transform2D, start: float, end: float, drop: float) -> PackedVector2Array:
	var result: PackedVector2Array = original.duplicate()
	var inverse: Transform2D = to_room.affine_inverse()
	for i: int in result.size():
		var point: Vector2 = to_room * original[i]
		point.y += drop * sin(clampf((point.x - start) / maxf(end - start, 0.001), 0.0, 1.0) * PI)
		result[i] = inverse * point
	return result

static func restore_point(room: Dictionary, value: Vector2) -> Vector2:
	if not room.has("layout"): return value
	var limits: Vector2 = player_bounds(room)
	var point := Vector2(clampf(value.x, limits.x, limits.y), value.y)
	var lanes: Array = room.layout.get("checkpoint_lanes", [])
	# Current door/spawn positions and new checkpoints already resting on a
	# safe lane need no legacy rescaling, even in a multi-floor room.
	for lane: Dictionary in lanes:
		var span: Array = lane.x
		if point.x >= float(span[0]) and point.x <= float(span[1]) and absf(point.y - float(lane.y)) <= 24.0:
			return Vector2(point.x, float(lane.y))
	var legacy: Variant = room.layout.get("legacy_size")
	if legacy is Array and legacy.size() == 2:
		point = Vector2(value.x * float(room.size[0]) / maxf(float(legacy[0]),1.0), value.y * float(room.size[1]) / maxf(float(legacy[1]),1.0))
	var best := Vector2.INF
	var distance: float = INF
	for lane: Dictionary in lanes:
		var span: Array = lane.x
		var left: float = maxf(limits.x, float(span[0]))
		var right: float = minf(limits.y, float(span[1]))
		if left > right: continue
		var candidate := Vector2(clampf(point.x,left,right),float(lane.y))
		var gap: float = point.distance_squared_to(candidate)
		if gap < distance:
			best = candidate
			distance = gap
	if best != Vector2.INF: return best
	var spawn: Array = room.get("play_spawn",room.get("spawn",[point.x,point.y]))
	return Vector2(clampf(float(spawn[0]),limits.x,limits.y),float(spawn[1]))
