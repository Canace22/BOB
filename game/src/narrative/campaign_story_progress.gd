class_name CampaignStoryProgress
extends RefCounted
## 阶段完成与存档在同一路径收口；跳过只提交当前谈话，不代做后续危险操作。
static func complete(story: CampaignStory) -> void:
	var s: Dictionary=story.stage()
	var host: WhalebellyMain=story.host
	for id: String in s.get("grant",[]): story.facts[id]=true
	for ability: String in s.get("reward_abilities",[]):
		if not host.has_ability(ability):
			host.abilities[ability]=true
			host.record_event("ability_unlocked",{"id":ability,"stage":s.id})
	story.completed.append(str(s.id))
	host.record_event("story_stage_completed",{"id":s.id,"chapter":s.chapter,"room":s.room_id})
	# 可绕遭遇与撤离也在离开阶段时停伤害；不把它们写成击杀。
	story.encounter.clear(true)
	host.music.set_story_encounter(false)
	story.queued_lines.clear()
	story.pending_task={}
	story.observing=false
	story.auto_queued=false
	story.previous_position=Vector2.INF
	host.dialogue.subtitle_changed.emit("")
	host.player.clear_projectiles()
	story.index+=1
	if int(s.chapter)==1 and (story.stage().is_empty() or int(story.stage().chapter)>1): host.completed=true
	if str(s.kind)=="battle":
		host.player.health=host.player.max_health
		host.health=host.player.health
		host.player.stats_changed.emit(host.player.health,host.player.soul)
	if host.player.is_on_floor():
		host.checkpoint={"room":host.room_index,"pos":[host.player.position.x,host.player.position.y]}
	story.view.rebuild()
	if story.stage().is_empty():
		host.abilities.ending=true
		host.music.play_ending()
		if not host.qa: host.player_ui.open.call_deferred("ending",false)
	host.save_progress(false)

static func restore(story: CampaignStory, value: Dictionary) -> void:
	story.leave_room()
	story.completed.clear()
	story.facts={}
	if int(value.get("version",0))==1 and value.get("completed",[]) is Array and value.get("facts",{}) is Dictionary:
		for id: Variant in value.completed:
			if id is String and story.catalog.has_stage(id) and id not in story.completed: story.completed.append(id)
		story.facts=value.facts.duplicate(true)
	story.index=0
	# 只恢复连续完成前缀，损坏或未来阶段记录不能越过尚未完成的前置。
	while story.index<story.catalog.stages.size() and str(story.catalog.stages[story.index].id) in story.completed:
		story.index+=1
	var accepted: Array[String]=[]
	for i: int in story.index: accepted.append(str(story.catalog.stages[i].id))
	story.completed=accepted
