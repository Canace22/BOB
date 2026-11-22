extends SceneTree
## 分场景正式关卡夹具：仅初始阶段/检查点与历史能力配置，交战全部使用物理键事件。
const DRIVER=preload("res://tests/story/combat_input_driver.gd")
var host: WhalebellyMain
var records: Array[Dictionary]=[]
var checks: Array[Dictionary]=[]
var output: String="res://build/qa/formal-story-combat-input"
var chapters: Array[int]=[1,2,3,5,7,8,9,12]
var attempts: int=2
var maximum_frames: int=7200

func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for tick: int in count: await physics_frame

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"pass":passed})
	print("PASS " if passed else "FAIL ",label)

func parse_options() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output=arg.trim_prefix("--out=")
		if arg.begins_with("--chapter="):
			chapters.clear()
			for item: String in arg.trim_prefix("--chapter=").split(","): chapters.append(int(item))
		if arg.begins_with("--attempts="): attempts=clampi(int(arg.trim_prefix("--attempts=")),1,3)
		if arg.begins_with("--max-frames="): maximum_frames=maxi(300,int(arg.trim_prefix("--max-frames=")))

func run() -> void:
	parse_options()
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var raw: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var catalog:=CampaignStoryCatalog.new()
	catalog.load_data(CampaignWorld.load_rooms(raw))
	check("formal story catalog has valid room bindings",catalog.errors.is_empty())
	for stage: Dictionary in catalog.stages:
		if int(stage.chapter) not in chapters or str(stage.kind) not in ["battle","escape"]: continue
		var success: bool=false
		for attempt: int in attempts:
			var record: Dictionary=await play_stage(catalog,stage,attempt)
			records.append(record)
			success=bool(record.success)
			if success: break
		check("physical keyboard completes "+str(stage.id),success)
	var failed: int=checks.filter(func(item: Dictionary) -> bool:return not item.pass).size()
	var report: Dictionary={"method":"Per-stage fixture of actual WhalebellyMain/WhalebellyCampaignPlayer and current formal room. Only initial story completed-prefix, source historical flags/reward abilities and checkpoint are configured. Combat uses Input.parse_input_event only; no enemy damage/finish/health or invincibility writes. Not a full continuous twelve-chapter walk-through.","display_server":DisplayServer.get_name(),"chapters":chapters,"checks":checks,"attempts":records,"failed":failed}
	write_json("report.json",report)
	print("STORY_COMBAT_INPUT_QA checks=",checks.size()," failures=",failed," attempts=",records.size()," output=",output)
	await frames(12)
	quit(1 if failed>0 else 0)

func make_host(catalog: CampaignStoryCatalog, stage: Dictionary) -> void:
	paused=false
	host=preload("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	host.ui_interactive_in_tests=true
	host.muted=true
	root.add_child(host)
	current_scene=host
	await frames(14)
	host.story.allow_in_tests=true
	host.dialogue.enabled=true
	var prefix: Array[String]=[]
	var facts: Dictionary={}
	for previous: Dictionary in catalog.stages:
		if str(previous.id)==str(stage.id): break
		prefix.append(str(previous.id))
		for flag: String in previous.get("grant",[]): facts[flag]=true
		for task: Dictionary in previous.get("tasks",[]):
			facts[str(task.id)]=true
			for flag: String in task.get("grant",[]): facts[flag]=true
		for ability: String in previous.get("reward_abilities",[]): host.abilities[ability]=true
		if str(previous.kind)=="battle": facts[str(previous.id)+"_outcome"]=str(previous.enemy.get("ending","retreat"))
	if bool(host.abilities.get("float",false)): host.collected["R1-03"]=true
	host.completed=int(stage.chapter)>1
	host.story.restore({"version":1,"completed":prefix,"facts":facts})
	var index: int=0
	for item: int in host.rooms.size():
		if str(host.rooms[item].id)==str(stage.room_id): index=item;break
	host.load_room(index,stage.get("checkpoint",stage.at))
	await frames(20)

func play_stage(catalog: CampaignStoryCatalog, stage: Dictionary, attempt: int) -> Dictionary:
	await make_host(catalog,stage)
	var driver:=DRIVER.new()
	var started: bool=false
	var enemy: EnemyLabEnemy
	var samples: Array[Dictionary]=[]
	var shots: Dictionary={}
	var start_events: int=host.event_sequence
	var last_snapshot: Dictionary={}
	var start_hp: int=host.player.health
	var start_position: Vector2=host.player.position
	var source_abilities: Dictionary=host.abilities.duplicate(true)
	var peak_x: float=host.player.position.x
	var minimum_x: float=peak_x
	for frame: int in maximum_frames:
		if host.player.health<=0: break
		if str(stage.id) in host.story.completed: break
		if not is_instance_valid(enemy):
			enemy=host.story.encounter.enemy
			if not is_instance_valid(enemy):
				if frame>180: break
				await frames(1)
				continue
			started=true
			await shot(str(stage.id)+"-a"+str(attempt)+"-start")
		driver.drive(host.player,enemy,stage,frame,attempt)
		peak_x=maxf(peak_x,host.player.position.x)
		minimum_x=minf(minimum_x,host.player.position.x)
		if frame%15==0:
			last_snapshot={"frame":frame,"player":pair(host.player.position),"health":host.player.health,"state":host.player.state,"enemy":pair(enemy.position),"enemy_health":enemy.health,"phase":enemy.state,"move":enemy.move_key,"timer":enemy.timer,"serial":enemy.attack_serial,"outcome":enemy.outcome,"guard_count":(host.player.skill_controller as TideCombatGuardSkills).guard_count,"guard_meter":(host.player.skill_controller as TideCombatGuardSkills).guard_meter}
			samples.append(last_snapshot)
		if enemy.state=="tell" and not shots.has("tell"):
			shots.tell=true
			await shot(str(stage.id)+"-a"+str(attempt)+"-tell")
		if (host.player.skill_controller as TideCombatGuardSkills).guard_count>0 and not shots.has("guard"):
			shots.guard=true
			await shot(str(stage.id)+"-a"+str(attempt)+"-guard")
		await frames(1)
	driver.release(maximum_frames)
	var succeeded: bool=str(stage.id) in host.story.completed and host.player.health>0
	var end_hp: int=host.player.health
	var ending: String=str(host.story.facts.get(str(stage.id)+"_outcome","surrender" if succeeded and str(stage.kind)=="escape" else ""))
	var actual_enemy_hp: int=enemy.health if is_instance_valid(enemy) else int(last_snapshot.get("enemy_health",-1))
	var serials: int=enemy.attack_serial if is_instance_valid(enemy) else int(last_snapshot.get("serial",0))
	await shot(str(stage.id)+"-a"+str(attempt)+"-result")
	var stage_events: Array=[]
	for event: Dictionary in host.events:
		if int(event.seq)>start_events: stage_events.append(event)
	var record: Dictionary={"stage":stage.id,"chapter":stage.chapter,"room":stage.room_id,"attempt":attempt,"success":succeeded,"started_via_controller":started,"expected_ending":stage.enemy.get("ending","surrender"),"ending":ending,"initial_player_health":start_hp,"final_player_health":end_hp,"enemy_health":actual_enemy_hp,"enemy_serials":serials,"checkpoint":stage.get("checkpoint",stage.at),"initial_position":pair(start_position),"final_position":pair(host.player.position),"x_span":[minimum_x,peak_x],"historical_abilities":source_abilities,"inputs":driver.inputs,"samples":samples,"events":stage_events}
	write_json(str(stage.id)+"-attempt-"+str(attempt)+".json",record)
	print("STORY_COMBAT_INPUT ",JSON.stringify({"stage":stage.id,"attempt":attempt,"success":succeeded,"started":started,"health":end_hp,"enemy_health":actual_enemy_hp,"serials":serials,"ending":ending,"position":pair(host.player.position)}))
	await dispose_host()
	return record

func dispose_host() -> void:
	paused=false
	if not is_instance_valid(host): return
	host.quitting=true
	host.story.leave_room()
	host.streaming.shutdown()
	host.queue_free()
	host=null
	current_scene=null
	await frames(12)

func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func pair(value: Vector2) -> Array: return [value.x,value.y]
func write_json(name: String, value: Dictionary) -> void:
	var file:=FileAccess.open(output.path_join(name),FileAccess.WRITE)
	file.store_string(JSON.stringify(value,"\t"))
