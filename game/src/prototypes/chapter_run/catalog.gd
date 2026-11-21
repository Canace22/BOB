class_name ChapterRunCatalog
extends RefCounted
## 内容ID与运行规则分开；独立启动不伪造之前章节的真实存档。
static func read(id: int) -> Dictionary:
	var path: String="res://content/prototypes/chapters/ch%02d.json" % id
	if not FileAccess.file_exists(path): return {}
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

static func point(value: Array) -> Vector2: return Vector2(float(value[0]),float(value[1]))

static func origin(data: Dictionary) -> Vector2:
	for stage: Dictionary in data.get("stages",[]):
		var enemy: Dictionary=stage.get("enemy",{})
		if int(enemy.get("profile",0))>=3:
			var p: Vector2=point(enemy.at)
			# 完整复用试验场坐标约定；整章一并平移，玩家与敌人local/global保持一致。
			return Vector2(p.x-(760 if int(enemy.profile)==3 else 855),0)
	return Vector2.ZERO

static func validate(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray=[]
	if int(data.get("id",0)) not in range(4,13): errors.append("chapter id")
	if data.get("stages",[]).is_empty(): errors.append("missing stages")
	var seen: Dictionary={}
	var tasks: Dictionary={}
	for stage: Dictionary in data.get("stages",[]):
		var id: String=str(stage.get("id",""))
		if id.is_empty() or seen.has(id): errors.append("duplicate/empty stage: "+id)
		seen[id]=true
		if str(stage.get("kind","")) not in ["dialogue","explore","battle","escape","observe","exit"]: errors.append("unknown kind: "+id)
		for task: Dictionary in stage.get("tasks",[]):
			if tasks.has(str(task.id)): errors.append("duplicate task: "+str(task.id))
			tasks[str(task.id)]=true
			for granted: String in task.get("grant",[]): tasks[granted]=true
		for granted: String in stage.get("grant",[]): tasks[granted]=true
	for stage: Dictionary in data.get("stages",[]):
		for key: String in ["required","any"]:
			for id: String in stage.get(key,[]):
				if not tasks.has(id): errors.append("missing task: "+id)
		for task: Dictionary in stage.get("tasks",[]):
			for id: String in task.get("requires",[]):
				if not tasks.has(id): errors.append("missing requirement: "+id)
	# 按实际阶段顺序检查可达前置，拒绝循环或依赖未来阶段的任务。
	var available: Dictionary={}
	for stage: Dictionary in data.get("stages",[]):
		var pending: Array=stage.get("tasks",[]).duplicate()
		for pass_index: int in pending.size()+1:
			var progressed: bool=false
			for task_index: int in range(pending.size()-1,-1,-1):
				var task: Dictionary=pending[task_index]
				var ready: bool=true
				for key: String in task.get("requires",[]): ready=ready and available.has(key)
				if ready:
					available[str(task.id)]=true
					for key: String in task.get("grant",[]): available[key]=true
					pending.remove_at(task_index)
					progressed=true
			if not progressed: break
		if not pending.is_empty(): errors.append("unreachable dependencies in "+str(stage.id))
		for key: String in stage.get("grant",[]): available[key]=true
	return errors
