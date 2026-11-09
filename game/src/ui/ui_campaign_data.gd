class_name WhaleUICampaignData
extends RefCounted
## Read model for the active campaign. Gameplay and saves remain host-owned.
var host: Node2D

func camp_position() -> Array:
	return host.room.get("camp", {0:[93,550],3:[80,610],4:[110,503]}.get(host.room_index, []))

func at_camp() -> bool:
	var camp: Array = camp_position()
	return is_instance_valid(host.player) and host.player.health > 0 and camp.size() == 2 and host.player.position.distance_to(host.point(camp)) < 180

func prompt() -> String:
	var p: Node2D = host.player
	if not is_instance_valid(p) or p.health <= 0: return ""
	var gate: Node = p.skill_controller.nearby_gate()
	if is_instance_valid(gate): return "使用通行节点"
	var reward: Array = host.room.get("reward", [])
	if reward.size() == 2 and p.position.distance_to(host.point(reward)) < 100 and not host.collected.get(str(host.room.id), false): return "拾取记忆 / 补给"
	if at_camp(): return "在营地歇息"
	for door: Dictionary in host.room.get("doors", []):
		if p.position.distance_to(host.point(door.pos)) < 125:
			var needed: String = door.get("ability", "")
			if needed == "boss" and not boss().is_empty(): return "先击败负壳守卫"
			if not needed.is_empty() and needed != "boss" and not host.has_ability(needed): return "需要" + ability_name(needed)
			var connected: XumenConnectedWorld=host.get("connected_world")
			if connected!=null and connected.enabled and int(door.to)>=0:return "沿通路直接前进"
			return "穿过通道（方向＋交互）"
	return ""

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
		result.append({"index":i, "id":str(r.id), "name":str(r.name), "visited":bool(host.visited.get(str(r.id), false)), "current":i == host.room_index, "doors":r.get("doors", []), "camp":r.has("camp") or i in [0,3,4]})
	return result

func room_description(index: int) -> String:
	var r: Dictionary = host.rooms[index]
	var visited: bool = host.visited.get(str(r.id), false)
	if not visited:
		var requirement := ""
		for source: Dictionary in host.rooms:
			if not host.visited.get(str(source.id), false): continue
			for door: Dictionary in source.get("doors", []):
				if int(door.to) == index and not str(door.get("ability", "")).is_empty(): requirement = "\n通路条件：" + ability_name(str(door.ability))
		return "已发现相邻通路，内部尚未探索。" + requirement
	var details: String = "已探索" + (" · 当前位置" if index == host.room_index else "")
	if r.has("camp") or index in [0,3,4]: details += "\n壳形营地：恢复生命、记录检查点"
	if host.collected.get(str(r.id), false): details += "\n本房补给 / 记忆已收集"
	if host.defeated.get(str(r.id)+":0", false): details += "\n守关者已击败"
	return details
