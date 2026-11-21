class_name ChapterRunFlow
extends Node
## 顺序阶段只保存完成事实；局部任务可任意顺序，危险操作必须独立按F。
var host: ChapterRun
var index: int=0
var lines: Array=[]
var line_index: int=0
var pending_task: Dictionary={}
var talking: bool=false
var observing: bool=false
var observation_time: float=0
var observation_duration: float=0
var finished: bool=false

func stage() -> Dictionary:
	return host.data.stages[index] if index<host.data.stages.size() else {}

func restore() -> void:
	while index<host.data.stages.size() and str(host.data.stages[index].id) in host.completed: index+=1
	finished=index>=host.data.stages.size()
	enter()

func enter() -> void:
	observing=false
	observation_time=0
	pending_task={}
	var s: Dictionary=stage()
	if s.is_empty(): return
	host.encounter.clear()
	if s.has("actor_at"): host.encounter.move_retired_to(host.point(s.actor_at))
	if s.has("enemy"):
		var config: Dictionary=s.enemy.duplicate(true)
		if s.kind in ["battle","escape"]:
			config.trigger=s.at
			config.trigger_radius=s.get("radius",160)
		host.encounter.prepare(config)
	host.record("stage_entered",{"stage":s.id})

func near(value: Array, radius: float=140) -> bool:
	return host.player.position.distance_to(host.point(value))<=radius and host.player.is_on_floor()

func tick(dt: float) -> void:
	if finished or talking or host.player.health<=0: return
	var s: Dictionary=stage()
	if s.is_empty(): return
	if s.has("enemy"): host.encounter.tick(dt,s.kind=="explore")
	match str(s.kind):
		"dialogue":
			if near(s.at,float(s.get("radius",180))): speak(s.get("lines",[]))
		"battle":
			if host.encounter.won():
				host.flags[str(s.id)+"_outcome"]=host.encounter.enemy.outcome
				var ending_at: Vector2=host.encounter.enemy.position+host.offset
				host.flags[str(s.id)+"_end_at"]=[ending_at.x,ending_at.y]
				host.record("battle_completed",host.encounter.enemy.snapshot())
				host.encounter.end_combat()
				host.encounter.retire()
				complete()
		"escape":
			if host.encounter.started and host.encounter.warning<=0 and host.encounter.time>=float(s.get("min_seconds",0)) and near(s.goal,float(s.get("goal_radius",80))):
				host.encounter.end_combat()
				host.encounter.retire()
				complete()
		"observe":
			if observing:
				observation_time+=dt
				if observation_time>=observation_duration: complete()

func unlocked(task: Dictionary) -> bool:
	for id: String in task.get("requires",[]):
		if not host.flags.get(id,false): return false
	return not host.flags.get(str(task.id),false)

func active_tasks() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for task: Dictionary in stage().get("tasks",[]):
		if unlocked(task): result.append(task)
	return result

func interact() -> void:
	if finished:
		if int(host.data.get("next",0))>0: host.launch.call_deferred(int(host.data.next))
		return
	var s: Dictionary=stage()
	if s.kind=="observe":
		if observing: complete()
		elif near(s.at):
			observing=true
			observation_duration=float(s.get("duration",4))
			host.player.clear_combat_input()
			host.record("observation_started",{"stage":s.id})
	elif s.kind=="explore":
		for task: Dictionary in active_tasks():
			if near(task.at,float(task.get("radius",110))):
				pending_task=task
				if task.get("lines",[]).is_empty(): finish_task()
				else: speak(task.lines)
				break
	elif s.kind=="exit" and near(s.at): complete()

func speak(value: Array) -> void:
	if talking: return
	lines=value
	line_index=0
	if lines.is_empty():
		if not pending_task.is_empty(): finish_task()
		else: complete()
		return
	talking=true
	host.hold()
	host.hud.dialogue.show()
	show_line()

func show_line() -> void:
	var line: Array=lines[line_index]
	host.hud.dialogue.present(str(line[0]),str(line[1]))

func advance() -> void:
	line_index+=1
	if line_index>=lines.size(): close_dialogue()
	else: show_line()

func close_dialogue() -> void:
	if not talking: return
	talking=false
	host.hud.dialogue.hide()
	if not pending_task.is_empty(): finish_task()
	else: complete()
	host.release()

func finish_task() -> void:
	if pending_task.is_empty(): return
	var id: String=str(pending_task.id)
	host.flags[id]=true
	for key: String in pending_task.get("grant",[]): host.flags[key]=true
	host.record("task_completed",{"task":id})
	pending_task={}
	host.write_save()
	var s: Dictionary=stage()
	var done: bool=true
	for key: String in s.get("required",[]): done=done and bool(host.flags.get(key,false))
	if not s.get("any",[]).is_empty():
		var any_done: bool=false
		for key: String in s.any: any_done=any_done or bool(host.flags.get(key,false))
		done=done and any_done
	if done: complete()

func complete() -> void:
	var s: Dictionary=stage()
	if s.is_empty(): return
	for key: String in s.get("grant",[]): host.flags[key]=true
	host.completed.append(str(s.id))
	host.record("stage_completed",{"stage":s.id})
	host.write_save()
	host.player.clear_combat_input()
	host.player.clear_projectiles()
	index+=1
	finished=index>=host.data.stages.size()
	if finished: host.encounter.clear()
	else: enter()

func target() -> Vector2:
	var s: Dictionary=stage()
	if s.is_empty(): return host.player.position
	if s.kind=="explore":
		var tasks: Array[Dictionary]=active_tasks()
		if not tasks.is_empty():
			var nearest: Vector2=host.point(tasks[0].at)
			for task: Dictionary in tasks:
				var p: Vector2=host.point(task.at)
				if p.distance_to(host.player.position)<nearest.distance_to(host.player.position): nearest=p
			return nearest
	if s.kind=="escape" and host.encounter.started: return host.point(s.goal)
	if s.kind=="battle" and is_instance_valid(host.encounter.enemy): return host.encounter.enemy.position
	return host.point(s.get("at",host.data.spawn))
