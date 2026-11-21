class_name CampaignStreamingLayout
extends RefCounted
## 房间保留内部坐标；这里只安排世界原点与门外真实连接，不复用传送落点。
const GAP := 320.0
const BRANCH_GAP := 640.0
const CLEARANCE := 160.0
const MAX_RUN := 110.0
const MAX_RISE := 110.0
const LADDER_OFFSET := 95.0
const TAIL_SHAFT_LEFT := 890.0
const TAIL_SHAFT_RIGHT := 1270.0
const MAIN_IDS: Array[String] = ["R1-01","R1-02","R1-03","R1-04","R1-05","R3-01","R4-01","R4-03","R4-05","R4-06","R5-01","R5-02","R5-04"]

static func build(rooms: Array) -> Dictionary:
	var by_id: Dictionary = {}
	for i: int in rooms.size(): by_id[str(rooms[i].id)] = i
	if by_id.has("R4-06"):
		# 只替换运行表中的副本，原配方和从资源读取的字典均不写回。
		var spine: int = int(by_id["R4-06"])
		rooms[spine] = rooms[spine].duplicate(true)
		rooms[spine].surfaces = _tail_surfaces(rooms[spine].surfaces)
	var origins: Dictionary = {}
	var previous: int = -1
	for id: String in MAIN_IDS:
		if not by_id.has(id): continue
		var index: int = int(by_id[id])
		origins[index] = Vector2.ZERO if previous < 0 else _right_origin(rooms,origins,previous,index)
		previous = index
	if by_id.has("R1-02"):
		var source: int = int(by_id["R1-02"])
		var origin: Vector2 = origins[source]
		if by_id.has("R1-06"):
			var upper: int = int(by_id["R1-06"])
			origins[upper] = origin - Vector2(float(rooms[upper].size[0])+BRANCH_GAP,float(rooms[upper].size[1])+BRANCH_GAP)
		if by_id.has("R1-07"):
			var memory: int = int(by_id["R1-07"])
			origins[memory] = origin + Vector2(float(rooms[source].size[0])+GAP,-float(rooms[memory].size[1])-BRANCH_GAP)
	if by_id.has("R3-01") and by_id.has("R2-01"):
		var hub: int = int(by_id["R3-01"])
		var lung: int = int(by_id["R2-01"])
		origins[lung] = Vector2(origins[hub]) - Vector2(0,float(rooms[lung].size[1])+BRANCH_GAP)
		for id: String in ["R2-03","R2-04"]:
			if not by_id.has(id): continue
			var next: int = int(by_id[id])
			origins[next] = _right_origin(rooms,origins,lung,next)
			lung = next
	if by_id.has("R4-06") and by_id.has("R5-08"):
		var spine: int = int(by_id["R4-06"])
		origins[int(by_id["R5-08"])] = Vector2(origins[spine]) + Vector2(0,float(rooms[spine].size[1])+BRANCH_GAP)
	var bounds: Dictionary = {}
	var world_bounds := Rect2()
	for index: int in origins:
		bounds[index] = room_rect(rooms,origins,index)
		world_bounds = bounds[index] if world_bounds.size == Vector2.ZERO else world_bounds.merge(bounds[index])
	var links: Array[Dictionary] = []
	for a: int in rooms.size():
		if not origins.has(a): continue
		for door: Dictionary in rooms[a].get("doors",[]):
			var b: int = int(door.get("to",-1))
			if b <= a or not origins.has(b): continue
			var reverse: Dictionary = _door(rooms[b],a)
			if reverse.is_empty(): continue
			var from: Vector2 = Vector2(origins[a]) + _point(door.pos)
			var to: Vector2 = Vector2(origins[b]) + _point(reverse.pos)
			var path: PackedVector2Array = _stairs(_route(rooms,origins,a,b,from,to))
			links.append({"a":a,"b":b,"from":from,"to":to,"path":path,"door_a":door,"door_b":reverse,"gate_a":_outside_gate(path,rooms,origins,a,false),"gate_b":_outside_gate(path,rooms,origins,b,true)})
	var chapter_by_room: Dictionary = {}
	for entry: Dictionary in rooms:
		var chapter: Dictionary = CampaignWorld.chapter_for_room(str(entry.id))
		if not chapter.is_empty(): chapter_by_room[str(entry.id)] = chapter
	return {"origins":origins,"links":links,"rooms":rooms,"room_bounds":bounds,"bounds":world_bounds,"chapter_by_room":chapter_by_room}

static func _right_origin(rooms: Array, origins: Dictionary, a: int, b: int) -> Vector2:
	var door_a: Dictionary = _door(rooms[a],b)
	var door_b: Dictionary = _door(rooms[b],a)
	var rise: float = float(door_a.get("pos",[0,0])[1])-float(door_b.get("pos",[0,0])[1])
	return Vector2(origins[a]) + Vector2(float(rooms[a].size[0])+GAP,rise)

static func _door(room: Dictionary, target: int) -> Dictionary:
	for door: Dictionary in room.get("doors",[]):
		if int(door.get("to",-1)) == target: return door
	return {}

static func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

static func room_rect(rooms: Array, origins: Dictionary, index: int) -> Rect2:
	return Rect2(Vector2(origins[index]),_point(rooms[index].size))

static func _route(rooms: Array, origins: Dictionary, a: int, b: int, from: Vector2, to: Vector2) -> PackedVector2Array:
	var id_a: String = str(rooms[a].id)
	var id_b: String = str(rooms[b].id)
	# 运行表保留历史序号，特殊分支按稳定 ID 判断。
	if id_a == "R1-02" and id_b == "R1-06":
		var outer_x: float = Vector2(origins[a]).x-CLEARANCE
		var lower_lane: float = Vector2(origins[b]).y+float(rooms[b].size[1])+BRANCH_GAP*0.5
		var target_x: float = Vector2(origins[b]).x-CLEARANCE
		return PackedVector2Array([from,Vector2(outer_x,from.y),Vector2(outer_x,lower_lane),Vector2(target_x,lower_lane),Vector2(target_x,to.y),to])
	if id_a == "R1-02" and id_b == "R1-07":
		var gap_x: float = Vector2(origins[a]).x+float(rooms[a].size[0])+CLEARANCE
		return PackedVector2Array([from,Vector2(gap_x,from.y),Vector2(gap_x,to.y),to])
	if id_a == "R3-01" and id_b == "R2-01":
		var gap_x: float = Vector2(origins[a]).x-CLEARANCE
		return PackedVector2Array([from,Vector2(gap_x,from.y),Vector2(gap_x,to.y),to])
	if id_a == "R4-06" and id_b == "R5-08":
		var root: Vector2 = origins[a]
		var gap_x: float = root.x-CLEARANCE
		# 中段竖口先穿过已拆开的 P1/底床，再在房间下方转折；不借用左侧主线路口。
		var lower_y: float = root.y+float(rooms[a].size[1])+BRANCH_GAP*0.5
		return PackedVector2Array([from,Vector2(from.x,lower_y),Vector2(gap_x,lower_y),Vector2(gap_x,to.y),to])
	return PackedVector2Array([from,to])

static func _tail_surfaces(surfaces: Array) -> Array:
	var result: Array = []
	for surface: Array in surfaces:
		var a: Vector2 = _point(surface[0])
		var b: Vector2 = _point(surface[-1])
		if surface.size()!=2 or (not is_equal_approx(a.y,1320) and not is_equal_approx(a.y,1584)) or a.x>=TAIL_SHAFT_LEFT or b.x<=TAIL_SHAFT_RIGHT:
			result.append(surface)
			continue
		result.append([[a.x,a.y],[TAIL_SHAFT_LEFT,a.y]])
		result.append([[TAIL_SHAFT_RIGHT,b.y],[b.x,b.y]])
	return result

static func _stairs(bends: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	if bends.is_empty(): return result
	result.append(bends[0])
	for i: int in range(1,bends.size()):
		var start: Vector2 = bends[i-1]
		var end: Vector2 = bends[i]
		var delta: Vector2 = end-start
		var count: int = maxi(1,ceili(maxf(absf(delta.x)/MAX_RUN,absf(delta.y)/MAX_RISE)))
		var vertical: bool = is_zero_approx(delta.x) and not is_zero_approx(delta.y)
		var first_side: float = 1.0
		if vertical:
			count = maxi(2,count)
			# 首级朝远离来路的平台外侧，末级也避开去路的水平台面。
			# 两端要求冲突时增加一级调整交替奇偶，避免上下行仍被同层平台托住。
			if i>1 and not is_zero_approx(start.x-bends[i-2].x): first_side = signf(start.x-bends[i-2].x)
			if i+1<bends.size() and not is_zero_approx(bends[i+1].x-end.x):
				var last_side: float = -signf(bends[i+1].x-end.x)
				var predicted_last: float = first_side if (count-1)%2==1 else -first_side
				if predicted_last != last_side: count += 1
		for step: int in range(1,count+1):
			var point: Vector2 = start.lerp(end,float(step)/count)
			# 竖井用交错落脚台，既能上跳，也能走出台边向下落。
			if vertical and step<count: point.x += LADDER_OFFSET*first_side*(1.0 if step%2==1 else -1.0)
			if result[-1].distance_to(point)>0.1: result.append(point)
	return result

static func _outside_gate(path: PackedVector2Array, rooms: Array, origins: Dictionary, index: int, reverse: bool) -> Vector2:
	var rect: Rect2 = room_rect(rooms,origins,index).grow(50)
	for step: int in path.size():
		var point: Vector2 = path[path.size()-1-step] if reverse else path[step]
		if not rect.has_point(point): return point
	return path[-1] if reverse else path[0]
