extends SceneTree
## 默认全程真实输入；显式战斗夹具只检查战后与跨章接线，不能证明战斗通关。
const OUTPUT: String="res://build/qa/chapters-route"
const FRAME_LIMIT: int=10000
const COMBAT_FRAME_LIMIT: int=12000
const KEYS: Array[Key]=[KEY_A,KEY_D,KEY_I,KEY_J,KEY_K,KEY_SPACE,KEY_F]
var host: ChapterRun
var held: Dictionary={}
var first_chapter: int=4
var last_chapter: int=12
var fixture_combat: bool=false
var screenshots: bool=false
var frames: int=0
var failures: int=0
var checks: int=0
var target: Vector2=Vector2.ZERO
var current_stage: String=""
var captured: Dictionary={}

func _initialize() -> void: run.call_deferred()

func tick(count: int=1) -> void:
	for frame: int in count:
		await physics_frame
		frames+=1

func key(code: Key, down: bool) -> void:
	# 只发真实状态边沿，避免反复松键改变原输入缓冲的时序。
	if bool(held.get(code,false))==down: return
	held[code]=down
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)

func release() -> void:
	for code: Key in KEYS: key(code,false)

func tap(code: Key) -> void:
	key(code,true)
	await tick(2)
	key(code,false)
	await tick(3)

func check(label: String, ok: bool) -> void:
	checks+=1
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures+=1

func diagnose(reason: String) -> void:
	var detail: Dictionary={"reason":reason,"frames":frames,"target":str(target),"stage":current_stage}
	if is_instance_valid(host):
		detail.merge({"chapter":host.chapter_id,"position":str(host.player.position),"health":host.player.health,"index":host.flow.index,"flags":host.flags,"paused":paused})
		if is_instance_valid(host.encounter.enemy): detail.enemy=host.encounter.enemy.snapshot()
	print("CHAPTERS_ROUTE_DIAGNOSTIC ",JSON.stringify(detail))
	var file:=FileAccess.open(OUTPUT.path_join("diagnostic.json"),FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(detail))

func shot(label: String) -> void:
	if not screenshots or DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(label+".png"))

func parse_args() -> bool:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--from="): first_chapter=int(arg.trim_prefix("--from="))
		elif arg.begins_with("--to="): last_chapter=int(arg.trim_prefix("--to="))
		elif arg=="--fixture-combat": fixture_combat=true
		elif arg=="--screenshots": screenshots=true
		else:
			check("unknown argument: "+arg,false)
			return false
	check("chapter range 4..12",first_chapter>=4 and last_chapter<=12 and first_chapter<=last_chapter)
	return failures==0

func run() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	if not parse_args():
		quit(1)
		return
	print("CHAPTERS_ROUTE_MODE ","FIXTURE: enemy.finish only; does NOT prove combat completion" if fixture_combat else "REAL INPUT: no health, invulnerability or position injection")
	set_meta("chapter_run_launch",{"id":first_chapter,"suffix":"route-qa","save":false,"restore":false})
	change_scene_to_file("res://content/prototypes/chapters/main.tscn")
	await tick(40)
	host=current_scene as ChapterRun
	while failures==0 and is_instance_valid(host):
		if not is_instance_valid(host.flow):
			check("chapter runtime initialized",false)
			break
		if not await play_chapter(): break
		var chapter: int=host.chapter_id
		check("chapter %d finished" % chapter,host.flow.finished)
		await shot("ch%02d-finished" % chapter)
		if chapter>=last_chapter: break
		check("chapter %d next link" % chapter,int(host.data.get("next",0))==chapter+1)
		if failures>0: break
		release()
		await tick(12)
		await tap(KEY_F)
		for wait_frame: int in 300:
			var next_host: ChapterRun=current_scene as ChapterRun
			if is_instance_valid(next_host) and next_host.chapter_id==chapter+1: break
			await tick()
		host=current_scene as ChapterRun
		check("real F transitions %d to %d" % [chapter,chapter+1],is_instance_valid(host) and host.chapter_id==chapter+1)
		await tick(30)
	if failures>0: diagnose("route failed")
	release()
	paused=false
	print("CHAPTERS_ROUTE_QA checks=",checks," failures=",failures," fixture_combat=",fixture_combat," frames=",frames)
	quit(1 if failures else 0)

func play_chapter() -> bool:
	var stage_start: int=frames
	current_stage=""
	while not host.flow.finished:
		if host.player.health<=0:
			check("survived chapter %d" % host.chapter_id,false)
			return false
		var stage: Dictionary=host.flow.stage()
		if stage.is_empty():
			check("unfinished flow has a stage",false)
			return false
		if str(stage.id)!=current_stage:
			if not current_stage.is_empty(): check("completed "+current_stage,true)
			current_stage=str(stage.id)
			stage_start=frames
			release()
			print("ROUTE_STAGE ch=",host.chapter_id," stage=",current_stage," position=",host.player.position)
			await shot("ch%02d-%s" % [host.chapter_id,current_stage])
		# 当前最慢防守样本为鳗约67秒；200秒预算还包含场地接近和正常换位。
		var frame_budget: int=COMBAT_FRAME_LIMIT if str(stage.kind)=="battle" else FRAME_LIMIT
		if frames-stage_start>=frame_budget:
			check("stage timeout after %d frames: %s" % [frame_budget,current_stage],false)
			diagnose("stage timeout")
			return false
		if host.hud.dialogue.visible:
			release()
			await tap(KEY_F)
			await tick(12)
			continue
		if paused or host.resume_wait>0:
			release()
			await tick()
			continue
		var kind: String=str(stage.kind)
		if kind=="battle" and is_instance_valid(host.encounter.enemy):
			if fixture_combat:
				release()
				print("FIXTURE_COMBAT ch=",host.chapter_id," stage=",current_stage," profile=",host.encounter.enemy.profile.id,"; not a combat pass")
				host.encounter.enemy.finish()
			else:
				combat_input(frames-stage_start)
				var enemy: EnemyLabEnemy=host.encounter.enemy
				var shot_key: String="ch%02d-battle" % host.chapter_id
				if screenshots and enemy.state=="tell" and not captured.has(shot_key):
					captured[shot_key]=true
					await shot(shot_key)
				if screenshots and enemy is EnemyLabElder and enemy.move_key=="elder_mimic" and enemy.state=="active" and not captured.has("elder-copy"):
					captured["elder-copy"]=true
					await shot("ch12-elder-copy")
			await tick()
			continue
		target=host.point(stage.at)
		if kind=="explore":
			var task: Dictionary=choose_task(stage)
			if task.is_empty():
				check("unlocked required task exists: "+current_stage,false)
				return false
			target=host.point(task.at)
		elif kind=="escape" and host.encounter.started and host.encounter.warning<=0:
			target=host.point(stage.goal)
		move_to(target,frames-stage_start)
		if host.player.is_on_floor() and host.player.position.distance_to(target)<65:
			release()
			if kind in ["explore","observe","exit"]:
				# 每次交互后回到主循环读取新阶段，不能对下一阶段连发F。
				await tap(KEY_F)
				await tick(8)
				continue
		await tick()
	check("completed "+current_stage,true)
	release()
	return true

func choose_task(stage: Dictionary) -> Dictionary:
	var wanted: Dictionary={}
	for id: String in stage.get("required",[]): add_requirement(id,stage,wanted)
	var any_done: bool=false
	var choices: Array[Dictionary]=[]
	for id: String in stage.get("any",[]):
		any_done=any_done or bool(host.flags.get(id,false))
		for task: Dictionary in stage.tasks:
			if str(task.id)==id: choices.append(task)
	if not any_done and not choices.is_empty():
		var best: Dictionary=choices[0]
		for task: Dictionary in choices:
			# 同等条件优先脚线更低的安全观察位，再选最近位置。
			if task_score(task)<task_score(best): best=task
		add_requirement(str(best.id),stage,wanted)
	var selected: Dictionary={}
	for task: Dictionary in host.flow.active_tasks():
		if not wanted.has(str(task.id)): continue
		if selected.is_empty() or task_score(task)<task_score(selected): selected=task
	return selected

func add_requirement(id: String, stage: Dictionary, wanted: Dictionary) -> void:
	if host.flags.get(id,false) or wanted.has(id): return
	wanted[id]=true
	for task: Dictionary in stage.tasks:
		if str(task.id)!=id and not id in task.get("grant",[]): continue
		wanted[str(task.id)]=true
		for dependency: String in task.get("requires",[]): add_requirement(dependency,stage,wanted)

func task_score(task: Dictionary) -> float:
	var point: Vector2=host.point(task.at)
	return -point.y*10000+point.distance_to(host.player.position)

func move_to(point: Vector2, frame: int) -> void:
	var gap: Vector2=point-host.player.position
	key(KEY_A,gap.x < -12)
	key(KEY_D,gap.x > 12)
	key(KEY_I,false)
	key(KEY_J,false)
	key(KEY_SPACE,gap.y < -55 and frame%60<30)

func combat_input(frame: int) -> void:
	var enemy: EnemyLabEnemy=host.encounter.enemy
	target=enemy.position
	var buttons: Dictionary=ChapterPressureInputPolicy.decide(enemy,host.player,frame)
	for code: Key in [KEY_A,KEY_D,KEY_I,KEY_J,KEY_SPACE]: key(code,bool(buttons.get(code,false)))
	if frame%600==0:
		print("ROUTE_COMBAT hp=",host.player.health," enemy_hp=",enemy.health," state=",enemy.state," move=",enemy.move_key," position=",host.player.position," attacks=",enemy.attack_serial," links=",enemy.pressure.chains," blocks=",enemy.parry_count," received_hits=",enemy.reactions.received)
