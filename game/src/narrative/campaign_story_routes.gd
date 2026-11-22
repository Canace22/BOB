class_name CampaignStoryRoutes
extends RefCounted
## 复用真实双向房门拓扑；剧情只给目标，不用传送跳过中继与返程。
static func path(host: Node2D, destination: String) -> Array[String]:
	var origin: String=str(host.room.get("id",""))
	var queue: Array[String]=[origin]
	var previous: Dictionary={origin:""}
	var by_id: Dictionary={}
	for room: Dictionary in host.rooms: by_id[str(room.id)]=room
	while not queue.is_empty():
		var id: String=queue.pop_front()
		if id==destination: break
		for door: Dictionary in by_id.get(id,{}).get("doors",[]):
			var target: int=int(door.get("to",-1))
			if target<0 or target>=host.rooms.size(): continue
			var next: String=str(host.rooms[target].id)
			if previous.has(next): continue
			previous[next]=id
			queue.append(next)
	var result: Array[String]=[]
	if not previous.has(destination): return result
	var cursor: String=destination
	while not cursor.is_empty():
		result.push_front(cursor)
		cursor=str(previous[cursor])
	return result

static func next_room(story: CampaignStory) -> String:
	var route: Array[String]=path(story.host,str(story.target().get("room_id",story.stage().get("room_id",""))))
	return route[1] if route.size()>1 else ""

static func objective(story: CampaignStory) -> String:
	var stage: Dictionary=story.stage()
	if stage.is_empty(): return "十二章已完成 · 可回访遗城"
	var prefix: String="第%d章 · %s\n" % [int(stage.chapter),str(stage.chapter_title)]
	var target: Dictionary=story.target()
	var target_room: String=str(target.get("room_id",stage.room_id))
	if str(story.host.room.id)!=target_room:
		var route: Array[String]=path(story.host,target_room)
		if route.size()<2: return prefix+"通往目标房间的连接缺失"
		var names: PackedStringArray=[]
		for id: String in route.slice(1):
			for room: Dictionary in story.host.rooms:
				if str(room.id)==id: names.append(str(room.name))
		return prefix+"前往"+" → ".join(names)
	return prefix+str(stage.get("objective","完成当前事件"))

static func gate_reason(story: CampaignStory, source: String, target: String) -> String:
	if story.stage().is_empty(): return ""
	# 允许已走路线与当前目标的真实中继房；仅阻止跳过尚未发生的章节。
	if bool(story.host.visited.get(target,false)): return ""
	if source==str(story.host.room.id) and target==next_room(story): return ""
	var current: int=int(story.stage().chapter)
	for stage: Dictionary in story.catalog.stages:
		if str(stage.room_id)==target and int(stage.chapter)<=current: return ""
	for stage: Dictionary in story.catalog.stages:
		if str(stage.room_id)==target: return "先完成当前章节 · "+str(story.stage().chapter_title)
	return ""
