class_name WhaleUICampaignData
extends RefCounted
## Read model for the active campaign. Gameplay and saves remain host-owned.
const MEMORY_TEXT := "水流穿过旧须，托起归港人的灯。\n松开攥紧的手，让潮水送你向上。"
var host: Node2D

func camp_position() -> Array:
	return _room_camp(host.room)

static func _room_camp(room: Dictionary) -> Array:
	return room.get("camp", {"R1-01":[93,550],"R1-04":[80,610],"R1-05":[110,503]}.get(room.get("id",""), []))

func at_camp() -> bool:
	var camp: Array = camp_position()
	return is_instance_valid(host.player) and host.player.health > 0 and camp.size() == 2 and host.player.position.distance_to(host.point(camp)) < 180

func prompt() -> String:
	var p: Node2D = host.player
	if not is_instance_valid(p) or p.health <= 0 or host.continuity.travelling: return ""
	if is_instance_valid(host.get("story")) and host.story.running():
		var story_prompt: String=host.story.prompt()
		if not story_prompt.is_empty(): return story_prompt
	var speaker: WhaleDialogueTrigger = host.dialogue.nearby()
	if speaker!=null: return speaker.prompt
	var gate: Node = p.skill_controller.nearby_gate()
	if is_instance_valid(gate): return "使用通行节点"
	var reward: Array = host.room.get("reward", [])
	if reward.size() == 2 and p.position.distance_to(host.point(reward)) < 100 and not host.collected.get(str(host.room.id), false): return str(host.room.get("reward_prompt", "拾取" + CampaignRelics.reward_name(str(host.room.id))))
	var resident: KitInteractable = KitInteractable.nearest(host)
	if resident != null: return resident.prompt()
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
	if KitInteractable.nearest(host) != null: return null
	return host.continuity.nearby_door()

func boss() -> Dictionary:
	if is_instance_valid(host.get("story")) and host.story.running():
		var enemy: EnemyLabEnemy=host.story.encounter.enemy
		if is_instance_valid(enemy) and enemy.outcome.is_empty():
			return {"name":enemy.profile.title,"hp":enemy.health,"max_hp":enemy.maximum}
	for enemy: Dictionary in host.enemies:
		if enemy.boss and enemy.alive: return enemy
	return {}

static func ability_name(id: String) -> String:
	return str(CampaignWorld.NAMES.get(id, id))

func map_rooms() -> Array[Dictionary]:
	var next: String = CampaignGuidance.next_room(host)
	var result: Array[Dictionary] = []
	for i: int in range(host.rooms.size()):
		var r: Dictionary = host.rooms[i]
		result.append({"index":i, "id":str(r.id), "name":str(r.name), "visited":bool(host.visited.get(str(r.id), false)),
			"current":i == host.room_index, "doors":r.get("doors", []), "camp":_room_camp(r).size() == 2,
			"route_kind":CampaignGuidance.route_kind(str(r.id)), "next":str(r.id) == next, "objectives":map_objectives(i)})
	return result

static func visit_label(room: Dictionary) -> String:
	if room.current: return "当前位置"
	return "已到达" if room.visited else "未到达"

func map_objectives(index: int) -> Dictionary[String, String]:
	var room: Dictionary = host.rooms[index]
	var id := str(room.id)
	var details: Dictionary[String, String] = {}
	if is_instance_valid(host.get("story")) and host.story.running():
		for chapter: Dictionary in host.story.catalog.chapters:
			for stage: Dictionary in chapter.stages:
				if str(stage.room_id)==id:
					details["第%d章 · %s" % [int(chapter.id),str(chapter.title)]]="已完成" if str(stage.id) in host.story.completed else "进行中 / 待到访"
		return details
	for i: int in room.get("enemies", []).size():
		if room.enemies[i].get("boss", false):
			details["守关者"] = "已击败" if host.defeated.get("%s:%d" % [id, i], false) else "待击败"
	if room.get("reward_grants", "") == "ending":
		details["导流闸"] = "已打开" if host.collected.get(id, false) else "待开启"
	elif not room.get("reward", []).is_empty() and not CampaignRelics.ITEMS.has(id):
		var grant := str(room.get("reward_grants","float" if id == "R1-07" else ""))
		var title := str(CampaignWorld.NAMES.get(grant, "奖励"))
		details[title] = "已领取" if host.collected.get(id, false) else "待领取"
	for key: String in CampaignRelics.ITEMS:
		if key.get_slice(":", 0) == id:
			details[str(CampaignRelics.ITEMS[key].name)] = "已收集" if host.collected.get(key, false) else "待收集"
	return details

func room_description(index: int) -> String:
	var r: Dictionary = host.rooms[index]
	var visited: bool = host.visited.get(str(r.id), false)
	if not visited:
		var requirement := ""
		for source: Dictionary in host.rooms:
			if not host.visited.get(str(source.id), false): continue
			for door: Dictionary in source.get("doors", []):
				var needs: Array[String] = CampaignWorld.requirements(door)
				if int(door.to) == index and not needs.is_empty():
					var available: bool = needs.all(func(need: String) -> bool: return bool(host.defeated.get(str(source.id) + ":0", false)) if need == "boss" else host.has_ability(need))
					requirement = ("\n已具备：" if available else "\n需要：") + CampaignWorld.requirement_label(needs)
		return CampaignGuidance.description(host, str(r.id)) + "\n未到达" + requirement
	var details: String = CampaignGuidance.description(host, str(r.id)) + "\n已探索" + (" · 当前位置" if index == host.room_index else "")
	if _room_camp(r).size() == 2: details += "\n壳形营地：恢复生命、记录检查点"
	if host.collected.get(str(r.id), false):
		details += "\n本房补给 / 记忆已收集"
		if str(r.id) == "R1-07":
			details += "\n已获得浮游：空中按住 %s，短暂浮升。\n记忆：" % WhaleUIStyle.key("float") + MEMORY_TEXT
	for id: String in CampaignRelics.ITEMS:
		if id.get_slice(":",0) == str(r.id) and host.collected.get(id, false):
			details += "\n已获得：" + CampaignRelics.description(id)
	if host.defeated.get(str(r.id)+":0", false): details += "\n守关者已击败"
	return details
