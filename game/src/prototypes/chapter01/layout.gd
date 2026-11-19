class_name Chapter01Layout
extends RefCounted
## 第一章空间关系沿用设计稿；探索预览用到达守口场代替战斗条件。

const DATA := "res://content/prototypes/chapter01/layout.json"
const TERRAIN := "res://art/whalebelly/rooms.json"


static func rooms() -> Array[Dictionary]:
	var layout: Array = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var terrain: Array = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN))
	var result: Array[Dictionary] = []
	for raw: Dictionary in layout:
		var room := raw.duplicate(true)
		var skin: Dictionary = terrain[int(room.skin)]
		room["size"] = Vector2(float(skin.size[0]), float(skin.size[1]))
		room["surfaces"] = skin.surfaces
		# 复用完整环境场景，包含补底与动件；单取四张分层图会留下动件挖空。
		room["environment_scene"] = "res://content/whalebelly/environment/xumen_reference.tscn" if int(room.skin)==0 else "res://content/whalebelly/environment/chapter/R1-%02d.tscn" % (int(room.skin)+1)
		for door: Dictionary in room.doors:
			var fractions: Dictionary = {"left": 0.075, "right": 0.925, "up": 0.40, "down": 0.65}
			var x := float(fractions[door.direction]) * float(skin.size[0])
			door["position"] = Vector2(x, ground_y(room, x))
		result.append(room)
	return result


static func ground_y(room: Dictionary, x: float) -> float:
	var points: Array = room.surfaces[0]
	for index in range(points.size() - 1):
		var a: Array = points[index]
		var b: Array = points[index + 1]
		if x >= float(a[0]) and x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), inverse_lerp(float(a[0]), float(b[0]), x))
	return float(points[0][1]) if x < float(points[0][0]) else float(points[-1][1])


static func by_id(data: Array[Dictionary], id: String) -> Dictionary:
	for room: Dictionary in data:
		if room.id == id:
			return room
	return {}


static func door_open(door: Dictionary, visited: Dictionary) -> bool:
	return not bool(door.get("shortcut", false)) or visited.has("jaw-arena")
