extends SceneTree
## 真实R/F6/Esc/F输入验收；第三章与整章完成使用显式事实夹具，不代表真实通关。
var host: Variant
var failures: int=0
var checks: int=0
var suffix: String="recovery-%d" % Time.get_ticks_usec()
var paths: Array[String]=[]

func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for frame: int in count: await physics_frame
func key(code: Key, down: bool) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func tap(code: Key) -> void:
	key(code,true)
	await tick(2)
	key(code,false)
	await tick(5)
func release() -> void:
	for code: Key in [KEY_A,KEY_D,KEY_W,KEY_S,KEY_J,KEY_I,KEY_K,KEY_L,KEY_Q,KEY_E,KEY_Z,KEY_SPACE,KEY_F,KEY_ENTER,KEY_ESCAPE,KEY_R,KEY_F6]: key(code,false)
func check(label: String, passed: bool) -> void:
	checks+=1
	print("PASS " if passed else "FAIL ",label)
	if not passed: failures+=1

func walk(x: float, limit: int=1400) -> void:
	release()
	for frame: int in limit:
		if host.hud.dialogue.visible or absf(host.player.position.x-x)<12: break
		var right: bool=host.player.position.x<x
		key(KEY_D,right)
		key(KEY_A,not right)
		# 第三章已完成事实夹具仍使用真实台阶路线到出口。
		var px: float=host.player.position.x
		key(KEY_SPACE,host is ChapterThreeWhitebox and right and px>2240 and px<2510 and frame%60<30)
		await tick(1)
	release()
	await tick(20)

func run() -> void:
	root.size=Vector2i(1280,720)
	host=load("res://content/prototypes/chapter_three/main.tscn").instantiate()
	host.restore_progress=false
	host.qa_save_suffix=suffix
	# 只建立桥接起点，不运行或伪称完成第三章交锋、洪水与搬巢。
	host.facts={"arrival":true,"met":true,"clue":true,"enemy_cleared":true,"valve_opened":true,"settled":true,"salvage":true,"repaired":true,"completed":true}
	root.add_child(host)
	current_scene=host
	host.save_progress()
	var third_path: String=host.save_path()
	paths.append(third_path)
	var third_data: String=FileAccess.get_file_as_string(third_path)
	await tick(35)
	await walk(3420)
	await tap(KEY_F)
	await tick(40)
	host=current_scene
	check("第三章完成夹具经真实F进入第四章",host is ChapterRun)
	if not host is ChapterRun:
		await finish()
		return
	check("桥接继承suffix并切换白盒命名空间",host.chapter_id==4 and host.suffix==suffix and host.save_path()!=third_path)
	paths.append(host.save_path())
	await walk(host.point(host.flow.stage().at).x)
	check("靠近第一目标触发对白",host.flow.talking)
	await tap(KEY_ESCAPE)
	await tick(20)
	check("Esc完成对白并解锁下一阶段",host.flow.index==1 and not host.flow.talking and not paused)

	key(KEY_D,true)
	await tick(2)
	await tap(KEY_ESCAPE)
	check("Esc暂停时禁用角色控制",paused and host.paused_by_user and not host.player.controls_enabled)
	await tap(KEY_ESCAPE)
	var held_x: float=host.player.position.x
	await tick(25)
	check("保持移动键时不会提前恢复",paused and not host.player.controls_enabled and absf(host.player.position.x-held_x)<1)
	key(KEY_D,false)
	await tick(25)
	check("松开按键后恢复控制",not paused and host.player.controls_enabled and not host.paused_by_user)

	var survey: Dictionary=host.flow.stage()
	var required_id: String=str(survey.required[0])
	var required_task: Dictionary={}
	for task: Dictionary in survey.tasks:
		if str(task.id)==required_id: required_task=task
	await walk(host.point(required_task.at).x)
	await tap(KEY_F)
	check("真实F打开任务对白",host.flow.talking)
	await tap(KEY_ESCAPE)
	await tick(20)
	check("任务完成尚不替代任选观察",host.flags.get(required_id,false) and host.flow.index==1)
	await tap(KEY_R)
	await tick(40)
	host=current_scene
	check("真实R恢复已完成任务与未完成阶段",host is ChapterRun and host.flow.index==1 and host.flags.get(required_id,false))
	check("R从当前阶段检查点恢复且没有启动可选怪",host.player.position.distance_to(host.point(host.checkpoint()))<60 and not is_instance_valid(host.encounter.enemy))
	await tap(KEY_F6)
	await tick(40)
	host=current_scene
	check("F6只重开当前第四章",host is ChapterRun and host.chapter_id==4 and host.completed.is_empty() and host.flags.is_empty() and host.flow.index==0)
	check("R和F6没有改写第三章存档",FileAccess.get_file_as_string(third_path)==third_data)

	# 显式全章完成夹具仅验证终态落盘、R恢复和下一章F，不代表第四章通关。
	host.completed.clear()
	for stage: Dictionary in host.data.stages: host.completed.append(str(stage.id))
	host.flags={"qa_explicit_completion_fixture":true}
	host.write_save()
	var fourth_path: String=host.save_path()
	var fourth_data: String=FileAccess.get_file_as_string(fourth_path)
	await tap(KEY_R)
	await tick(40)
	host=current_scene
	check("完成夹具经R恢复到终态并保留最终检查点",host.flow.finished and host.player.position.distance_to(host.point(host.checkpoint()))<60)
	await tap(KEY_F)
	await tick(40)
	host=current_scene
	check("终态真实F只进入第五章一次",host is ChapterRun and host.chapter_id==5 and host.suffix==suffix)
	if host is ChapterRun:
		paths.append(host.save_path())
		check("下一章不导入上一章事实",not host.flags.get("qa_explicit_completion_fixture",false) and host.completed.is_empty())
		await tap(KEY_F6)
		await tick(40)
		host=current_scene
		check("第五章F6保留第四章完成记录",FileAccess.get_file_as_string(fourth_path)==fourth_data and FileAccess.get_file_as_string(third_path)==third_data)
	await finish()

func finish() -> void:
	release()
	paused=false
	DirAccess.make_dir_recursive_absolute("res://build/qa/chapters")
	var file:=FileAccess.open("res://build/qa/chapters/recovery-summary.json",FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Keyboard recovery and handoff only; chapter-three and chapter-four completion are explicit fixtures, not playthroughs."}))
	if is_instance_valid(host):
		root.remove_child(host)
		host.free()
	for path: String in paths:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	await tick(3)
	print("CHAPTERS_RECOVERY_QA checks=",checks," failures=",failures)
	quit(1 if failures else 0)
