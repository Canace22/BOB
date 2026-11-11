class_name WhaleUICampaignData
extends RefCounted
## Read model for the active campaign. Gameplay and saves remain host-owned.
const MEMORY_TEXT := "水流穿过旧须，托起归港人的灯。\n松开攥紧的手，让潮水送你向上。"
var host: Node2D

func camp_position() -> Array:
	return host.room.get("camp", {0:[93,550],3:[80,610],4:[110,503]}.get(host.room_index, []))

func at_camp() -> bool:
	var camp: Array = camp_position()
	return is_instance_valid(host.player) and host.player.health > 0 and camp.size() == 2 and host.player.position.distance_to(host.point(camp)) < 180

func prompt() -> String:
	var p: Node2D = host.player
	if not is_instance_valid(p) or p.health <= 0 or host.continuity.travelling: return ""
	var gate: Node = p.skill_controller.nearby_gate()
	if is_instance_valid(gate): return "使用通行节点"
	var reward: Array = host.room.get("reward", [])
	if reward.size() == 2 and p.position.distance_to(host.point(reward)) < 100 and not host.collected.get(str(host.room.id), false): return "拾取记忆 / 补给"
	var entrance: CampaignDoorway = prompt_door()
	if entrance != null: return entrance.prompt()
	if at_camp(): return "在营地歇息"
	return ""

func prompt_door() -> CampaignDoorway:
	var p: Node2D = host.player
	if not is_instance_valid(p) or p.health <= 0: return null
	if is_instance_valid(p.skill_controller.nearby_gate()): return null
	var reward: Array = host.room.get("reward", [])
	if reward.size() == 2 and p.position.distance_to(host.point(reward)) < 100 and not host.collected.get(str(host.room.id), false): return null
	return host.continuity.nearby_door()

func boss() -> Dictionary:
	for enemy: Dictionary in host.enemies:
		if enemy.boss and enemy.alive: return enemy
	return {}

static func ability_name(id: String) -> String:
	return {"dash":"贴流冲", "float":"浮游", "anchor":"锚定", "boss":"击败守关者"}.get(id, id)

func map_rooms() -> Array[Dictionary]:
	var known: Dictionary = {}
	for i: int in range(host.rooms.size()):
		var r: Dictionary = host.rooms[i]
		if host.visited.get(str(r.id), false):
			known[i] = true
			for door: Dictionary in r.get("doors", []):
				var target: int = int(door.to)
				if target >= 0 and target < host.rooms.size(): known[target] = true
	var result: Array[Dictionary] = []
	for i: int in range(host.rooms.size()):
		if not known.has(i): continue
		var r: Dictionary = host.rooms[i]
		result.append({"index":i, "id":str(r.id), "name":str(r.name), "visited":bool(host.visited.get(str(r.id), false)), "current":i == host.room_index, "doors":r.get("doors", []), "camp":r.has("camp") or i in [0,3,4], "route_kind":CampaignGuidance.route_kind(str(r.id)), "next":str(r.id) == CampaignGuidance.next_room(host)})
	return result

func room_description(index: int) -> String:
	var r: Dictionary = host.rooms[index]
	var visited: bool = host.visited.get(str(r.id), false)
	if not visited:
		var requirement := ""
		for source: Dictionary in host.rooms:
			if not host.visited.get(str(source.id), false): continue
			for door: Dictionary in source.get("doors", []):
				if int(door.to) == index and not str(door.get("ability", "")).is_empty():
					var available: bool = bool(host.defeated.get(str(source.id) + ":0", false)) if str(door.ability) == "boss" else host.has_ability(str(door.ability))
					requirement = ("\n已具备：" if available else "\n需要：") + ability_name(str(door.ability))
		return CampaignGuidance.description(host, str(r.id)) + "\n已发现，尚未探索。" + requirement
	var details: String = CampaignGuidance.description(host, str(r.id)) + "\n已探索" + (" · 当前位置" if index == host.room_index else "")
	if r.has("camp") or index in [0,3,4]: details += "\n壳形营地：恢复生命、记录检查点"
	if host.collected.get(str(r.id), false):
		details += "\n本房补给 / 记忆已收集"
		if str(r.id) == "R1-07":
			details += "\n已获得浮游：空中按住 %s，短暂浮升。\n记忆：" % WhaleUIStyle.key("float") + MEMORY_TEXT
	if host.defeated.get(str(r.id)+":0", false): details += "\n守关者已击败"
	return details
