class_name CampaignWorld
extends RefCounted
## Rooms beyond the first region: extra room data, door targets by stable ID,
## combined door requirements and per-region map placement.
const EXTRA := "res://content/whalebelly/world/rooms.json"
const REGIONS: Dictionary = {"R1":"须门遗港", "R2":"肺心潮庭", "R3":"胃肠沉城", "R4":"鸣肋断脊", "R5":"耳海归墟"}
const NAMES: Dictionary = {"dash":"贴流冲", "float":"浮游", "anchor":"锚定", "boss":"击败守关者", "parry":"迎珠", "fissure":"潜隙", "pressure":"潮压", "bone":"骨音", "silence":"静默"}
const UNBUILT := "后续区域未开放 · 原路返回"
static var extra_cache: Dictionary = {}

static func extra() -> Dictionary:
	if extra_cache.is_empty() and FileAccess.file_exists(EXTRA):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EXTRA))
		if parsed is Dictionary: extra_cache = parsed
	return extra_cache

## Appends later regions to the first-region list. Existing indices never move,
## so V6 checkpoints stay valid. Unknown targets keep the authored fallback.
static func load_rooms(base: Array) -> Array:
	var rooms: Array = base.duplicate(true)
	rooms.append_array(extra().get("rooms", []).duplicate(true))
	var index: Dictionary = {}
	for i: int in rooms.size(): index[str(rooms[i].id)] = i
	for link: Dictionary in extra().get("links", []):
		if not index.has(str(link.room)) or not index.has(str(link.to_id)): continue
		var doors: Array = rooms[index[str(link.room)]].get("doors", [])
		if int(link.door) < doors.size(): doors[int(link.door)].merge(link.patch, true)
	for entry: Dictionary in rooms:
		for door: Dictionary in entry.get("doors", []):
			if door.has("to_id"): door["to"] = index.get(str(door.to_id), int(door.get("to", -2)))
	return rooms

static func region(id: String) -> String:
	return id.get_slice("-", 0)

static func region_name(id: String) -> String:
	return str(REGIONS.get(region(id), region(id)))

static func scene_path(id: String) -> String:
	return "res://content/whalebelly/%s/%s.tscn" % [region(id).to_lower(), id]

static func requirements(door: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if not str(door.get("ability", "")).is_empty(): result.append(str(door.ability))
	for need: Variant in door.get("requires", []): result.append(str(need))
	return result

static func requirement_label(needs: Array[String]) -> String:
	var names: PackedStringArray = []
	for need: String in needs: names.append(str(NAMES.get(need, need)))
	return "＋".join(names)

## Empty when the door can be used now. Requirements are reported before the
## unbuilt notice so a locked gate still teaches what it will ask for.
static func restriction(host: Node2D, door: Dictionary) -> String:
	var missing: PackedStringArray = []
	for need: String in requirements(door):
		if need == "boss":
			for enemy: Dictionary in host.enemies:
				if enemy.boss and enemy.alive: return "先击败" + str(enemy.get("name", "负壳守卫"))
		elif not host.has_ability(need):
			if need == "float": return "先到鲸须记忆袋获得浮游"
			missing.append(str(NAMES.get(need, need)))
	if not missing.is_empty(): return "需要" + "＋".join(missing)
	if door.has("locked") and not host.has_ability(str(door.locked)): return str(door.get("locked_message", "通路从另一侧闩着"))
	return UNBUILT if int(door.get("to", -2)) == -2 else ""

## Normalized map position of a room on a region page, or null when unplaced.
static func map_position(page: String, id: String) -> Variant:
	var spot: Variant = extra().get("map", {}).get(page, {}).get(id)
	return Vector2(float(spot[0]), float(spot[1])) if spot is Array and spot.size() == 2 else null

static func on_map_page(page: String, id: String) -> bool:
	return region(id) == page or map_position(page, id) != null
