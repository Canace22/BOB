class_name CampaignStory
extends Node
## 正式十二章唯一进度所有者：阶段/任务事实进V6扩展字段，未完成对话与战斗不保存半途。
var host: WhalebellyMain
var enabled: bool=true
var allow_in_tests: bool=false
var catalog:=CampaignStoryCatalog.new()
var encounter: CampaignStoryEncounter
var view: CampaignStoryView
var cinematic: CampaignCinematic
var index: int=0
var completed: Array[String]=[]
var facts: Dictionary={}
var pending_task: Dictionary={}
var queued_lines: Array=[]
var dialogue_token: String=""
var observing: bool=false
var observation_time: float=0.0
var last_caption: int=-1
var auto_queued: bool=false
var previous_position: Vector2=Vector2.INF
var interaction_armed: bool=true
var configured: bool=false
var pending_restore: Dictionary={}

func setup(value: WhalebellyMain) -> void:
	host=value
	# 旧存档测试及迁移会在宿主入树/房间加载前读档，不能把空房表误报为缺失全城。
	if configured or not host.is_inside_tree() or host.rooms.is_empty(): return
	process_mode=Node.PROCESS_MODE_PAUSABLE
	catalog.load_data(host.rooms)
	if not host.qa:
		for error: String in catalog.errors: push_error("CampaignStory: "+error)
	if not catalog.errors.is_empty(): enabled=false
	encounter=CampaignStoryEncounter.new()
	encounter.setup(host)
	add_child(encounter)
	view=CampaignStoryView.new()
	view.story=self
	add_child(view)
	cinematic=CampaignCinematic.new()
	add_child(cinematic)
	cinematic.setup(self)
	host.dialogue.committed.connect(_dialogue_committed)
	configured=true
	if not pending_restore.is_empty():
		var saved: Dictionary=pending_restore
		pending_restore={}
		restore(saved)
func running() -> bool:
	return configured and enabled and (not host.qa or allow_in_tests) and not host.practice and not host.room_preview and host.capture_path.is_empty()

func stage() -> Dictionary:
	return catalog.stages[index] if index<catalog.stages.size() else {}
func current_room() -> bool:
	if stage().is_empty(): return false
	var id: String=str(host.room.get("id",""))
	if str(stage().room_id)==id: return true
	return active_tasks().any(func(task: Dictionary) -> bool: return str(task.get("room_id",stage().room_id))==id)

func target() -> Dictionary:
	var tasks: Array[Dictionary]=active_tasks()
	for task: Dictionary in tasks:
		if str(task.get("room_id",stage().get("room_id","")))==str(host.room.get("id","")): return task
	return tasks[0] if not tasks.is_empty() else stage()
func task_near(task: Dictionary) -> bool:
	return str(task.get("room_id",stage().room_id))==str(host.room.id) and near(task.at,float(task.get("radius",110)))
func near(point: Array, radius: float=125.0) -> bool:
	if not is_instance_valid(host.player) or not host.player.is_on_floor(): return false
	var delta: Vector2=host.player.position-host.point(point)
	return absf(delta.x)<=radius and absf(delta.y)<=130.0

func enter_room() -> void:
	previous_position=Vector2.INF
	if not running(): return
	view.rebuild()
	# 战后再次进入只恢复已完成身体，绝不重新开战或再次发奖励。
	for previous: Dictionary in catalog.stages:
		if str(previous.id) not in completed or previous.get("kind")!="battle" or str(previous.room_id)!=str(host.room.id): continue
		var ending: String=str(facts.get(str(previous.id)+"_outcome",""))
		if ending not in ["kill","surrender"]: continue
		var config: Dictionary=previous.enemy.duplicate(true)
		config.room_id=previous.room_id
		config.at=facts.get(str(previous.id)+"_end_at",config.at)
		config.auto_attack=false
		var body: EnemyLabEnemy=encounter.spawn(config)
		if body!=null:
			encounter.end_combat(ending)
			encounter.clear(true)
	view.rebuild()

func leave_room() -> void:
	if is_instance_valid(cinematic): cinematic.cancel()
	if not is_instance_valid(encounter): return
	if running() and is_instance_valid(host.music): host.music.set_story_encounter(false)
	encounter.clear_room()
	view.clear()
	queued_lines.clear()
	pending_task={}
	dialogue_token=""
	observing=false
	auto_queued=false
	previous_position=Vector2.INF

func _process(dt: float) -> void:
	if not running() or not is_instance_valid(host.player) or host.player.health<=0 or host.quitting: return
	if not Input.is_action_pressed("tp_interact"): interaction_armed=true
	view.visible=not host.reference_visible and host.layer_solo<0
	if not current_room() or host.reference_visible or host.layer_solo>=0: return
	if not queued_lines.is_empty():
		if host.dialogue.play_script(dialogue_token,queued_lines): queued_lines=[]
		return
	if not host.dialogue.available() or not host.dialogue.active.is_empty(): return
	var s: Dictionary=stage()
	var p: Vector2=host.player.position
	var radius: float=float(s.get("radius",150))
	if str(s.kind) in ["dialogue","battle","escape"]:
		if near(s.at,radius): auto_queued=true
		elif previous_position!=Vector2.INF and previous_position.distance_to(p)<650:
			var closest: Vector2=Geometry2D.get_closest_point_to_segment(host.point(s.at),previous_position,p)
			if closest.distance_to(host.point(s.at))<radius: auto_queued=true
	previous_position=p
	match str(s.kind):
		"dialogue":
			if auto_queued and host.player.is_on_floor(): _speak(s.get("lines",[]))
		"battle","escape": _combat(s)
		"explore":
			if s.has("enemy") and not is_instance_valid(encounter.enemy) and near(s.enemy.get("trigger",s.enemy.at),140): _spawn(s,true)
		"observe":
			if observing:
				observation_time+=dt
				var captions: Array=s.get("captions",[])
				var cursor: int=mini(captions.size()-1,int(observation_time/maxf(0.1,float(s.get("duration",5)))*captions.size()))
				if cursor>=0 and cursor!=last_caption:
					last_caption=cursor
					host.dialogue.subtitle_changed.emit(str(captions[cursor]))
				if observation_time>=float(s.get("duration",5)): complete()

func _combat(s: Dictionary) -> void:
	if not is_instance_valid(encounter.enemy) and auto_queued and host.player.is_on_floor(): _spawn(s)
	if str(s.kind)=="escape" and is_instance_valid(encounter.enemy) and encounter.elapsed>=float(s.get("min_seconds",0)) and near(s.goal,float(s.get("goal_radius",100))):
		encounter.end_combat("surrender")
		complete()
	elif str(s.kind)=="battle" and encounter.won():
		facts[str(s.id)+"_outcome"]=encounter.result
		facts[str(s.id)+"_end_at"]=[encounter.enemy.position.x,encounter.enemy.position.y]
		complete()

func _spawn(s: Dictionary, optional: bool=false) -> void:
	var config: Dictionary=s.enemy.duplicate(true)
	config.room_id=s.room_id
	config.optional=optional
	# 正式撤离方向可能向左；只由阶段near(goal)确认，禁用试验场向右出口的独立结算。
	if str(s.kind)=="escape": config.erase("exit_x")
	encounter.spawn(config)
	host.music.set_story_encounter(true)
	view.rebuild()
	host.record_event("story_encounter_started",{"stage":s.id,"room":s.room_id})

func active_tasks() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for task: Dictionary in stage().get("tasks",[]):
		if bool(facts.get(str(task.id),false)): continue
		var unlocked: bool=true
		for id: String in task.get("requires",[]): unlocked=unlocked and bool(facts.get(id,false))
		if unlocked: result.append(task)
	# 已满足观察任选后，优先指向仍欠缺的必做事项，不把另一路误当作必做指引。
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		return str(a.id) in stage().get("required",[]) and str(b.id) not in stage().get("required",[]))
	return result

func prompt() -> String:
	if not running() or not current_room(): return ""
	var s: Dictionary=stage()
	for task: Dictionary in active_tasks():
		if task_near(task): return str(task.get("label","查看")).trim_prefix("F ")
	if str(s.kind) in ["observe","exit"] and near(s.at):
		return "结束观察" if observing else ("观察" if s.kind=="observe" else "继续前行")
	return ""

func interact() -> bool:
	if prompt().is_empty(): return false
	if not interaction_armed: return true
	interaction_armed=false
	var s: Dictionary=stage()
	match str(s.kind):
		"explore":
			for task: Dictionary in active_tasks():
				if task_near(task):
					pending_task=task
					_speak(task.get("lines",[]))
					break
		"observe":
			if observing: complete()
			else:
				if not cinematic.play(str(s.id),complete):
					observing=true
					observation_time=0
					last_caption=-1
		"exit": complete()
	return true

func _speak(lines: Array) -> void:
	var key: String=str(pending_task.get("id",stage().get("id","")))
	if cinematic.play(key,_queue_speech.bind(lines.duplicate(true))): return
	_queue_speech(lines)

func _queue_speech(lines: Array) -> void:
	if lines.is_empty():
		if pending_task.is_empty(): complete()
		else: finish_task()
		return
	dialogue_token="formal_story/"+str(stage().id)+("/"+str(pending_task.id) if not pending_task.is_empty() else "")
	queued_lines=lines.duplicate(true)

func _dialogue_committed(id: String) -> void:
	if id!=dialogue_token or dialogue_token.is_empty(): return
	dialogue_token=""
	if pending_task.is_empty(): complete()
	else: finish_task()

func finish_task() -> void:
	if pending_task.is_empty(): return
	facts[str(pending_task.id)]=true
	for id: String in pending_task.get("grant",[]): facts[id]=true
	pending_task={}
	var s: Dictionary=stage()
	var done: bool=true
	for id: String in s.get("required",[]): done=done and bool(facts.get(id,false))
	if not s.get("any",[]).is_empty():
		var one: bool=false
		for id: String in s.any: one=one or bool(facts.get(id,false))
		done=done and one
	if done: complete()
	else:
		view.rebuild()
		host.save_progress(false)

func complete() -> void:
	if stage().is_empty(): return
	CampaignStoryProgress.complete(self)
func to_save() -> Dictionary:
	return {"version":1,"completed":completed.duplicate(),"facts":facts.duplicate(true)}

func restore(value: Dictionary) -> void:
	if not configured:
		pending_restore=value.duplicate(true)
		return
	CampaignStoryProgress.restore(self,value)
	if is_instance_valid(cinematic): cinematic.session_seen.clear()
