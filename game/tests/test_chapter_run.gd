extends TestSuite
## 直接调用目录、阶段和存档接口；完成事实夹具不代表章节已实机通关。

func test_all_nine_chapters_validate_and_chain() -> void:
	for id: int in range(4,13):
		var data: Dictionary=ChapterRunCatalog.read(id)
		eq(ChapterRunCatalog.validate(data),PackedStringArray(),"Chapter %d validates" % id)
		eq(int(data.get("id",0)),id,"Content id matches requested chapter")
		eq(int(data.get("next",-1)),id+1 if id<12 else 0,"Chapters form one terminating chain")
		var stages: Array=data.get("stages",[])
		check(not stages.is_empty(),"Every chapter has stages")
		if not stages.is_empty(): eq(str(stages.back().kind),"exit","Each chapter ends at explicit exit")

func test_catalog_rejects_missing_dependencies_and_duplicate_ids() -> void:
	var data: Dictionary=ChapterRunCatalog.read(4).duplicate(true)
	data.stages[1].tasks[0].requires=["qa_missing_task"]
	check(not ChapterRunCatalog.validate(data).is_empty(),"Unknown task dependency is rejected")
	data=ChapterRunCatalog.read(4).duplicate(true)
	data.stages[1].required=["qa_missing_required"]
	check(not ChapterRunCatalog.validate(data).is_empty(),"Unknown required task is rejected")
	data=ChapterRunCatalog.read(4).duplicate(true)
	data.stages[1].any=["qa_missing_alternative"]
	check(not ChapterRunCatalog.validate(data).is_empty(),"Unknown alternative is rejected")
	data=ChapterRunCatalog.read(4).duplicate(true)
	data.stages[1].id=data.stages[0].id
	check(not ChapterRunCatalog.validate(data).is_empty(),"Duplicate stage id is rejected")

	data=ChapterRunCatalog.read(4).duplicate(true)
	var tasks: Array=data.stages[1].tasks
	tasks[0].requires=[str(tasks[1].id)]
	tasks[1].requires=[str(tasks[0].id)]
	check(not ChapterRunCatalog.validate(data).is_empty(),"Cyclic task dependencies cannot become a soft lock")

func _host(id: int=4) -> ChapterRun:
	var host:=ChapterRun.new()
	host.chapter_id=id
	host.save_enabled=false
	host.restore_progress=false
	add(host)
	# 避免自动靠近/对白干扰纯阶段调用；玩家和组件仍由真实_ready建立。
	host.set_process(false)
	return host

func _finish_task(host: ChapterRun, id: String) -> void:
	for task: Dictionary in host.flow.stage().get("tasks",[]):
		if str(task.id)==id:
			host.flow.pending_task=task
			host.flow.finish_task()
			return
	check(false,"Fixture task exists: "+id)

func test_required_and_any_are_both_needed_and_dependencies_unlock() -> void:
	var host: ChapterRun=_host()
	# 使用内容现有的“供养牌 AND 两条观察路任选一条”，不另写一份判定器。
	host.flow.index=1
	host.flow.enter()
	var survey: Dictionary=host.flow.stage()
	var required: String=str(survey.required[0])
	var alternative: String=str(survey.any[0])
	_finish_task(host,required)
	eq(host.flow.index,1,"Required alone cannot satisfy required AND any")
	_finish_task(host,alternative)
	eq(host.flow.index,2,"Required plus one alternative advances")
	host.flags.clear()
	host.completed.clear()
	host.flow.index=1
	host.flow.enter()
	_finish_task(host,alternative)
	eq(host.flow.index,1,"Alternative alone cannot bypass required")
	_finish_task(host,required)
	eq(host.flow.index,2,"The two groups may be fulfilled in either order")
	host.flow.index=3
	host.flow.enter()
	var lift: Dictionary=host.flow.stage().tasks[0]
	var opening: Dictionary=host.flow.stage().tasks[1]
	check(not host.flow.unlocked(opening),"Water opening is locked before lifting homes")
	_finish_task(host,str(lift.id))
	check(host.flow.unlocked(opening),"Real task completion unlocks its dependent task")
	check(not host.flow.unlocked(lift),"Completed task cannot be repeated")

func test_optional_routes_and_chapter_specific_combat_endings() -> void:
	for id: int in [4,6]:
		var data: Dictionary=ChapterRunCatalog.read(id)
		var found: bool=false
		for stage: Dictionary in data.stages:
			check(str(stage.kind) not in ["battle","escape"],"Chapter %d has no required fight" % id)
			if stage.has("enemy"):
				found=true
				eq(str(stage.kind),"explore","Optional encounter belongs to exploration")
				check(bool(stage.enemy.get("optional",false)),"Enemy is explicitly optional")
				check(stage.get("any",[]).size()>=2,"Observation offers alternative positions")
				var safe: bool=false
				for task: Dictionary in stage.get("tasks",[]):
					if str(task.id) in stage.get("any",[]):
						if ChapterRunCatalog.point(task.at).distance_to(ChapterRunCatalog.point(stage.enemy.at))>300: safe=true
				check(safe,"An alternative is outside optional enemy trigger range")
		check(found,"Chapter %d retains an optional encounter" % id)
	for pair: Array in [[7,5,"surrender","escape"],[8,6,"kill","battle"],[12,7,"surrender","battle"]]:
		var found: bool=false
		for stage: Dictionary in ChapterRunCatalog.read(int(pair[0])).stages:
			if str(stage.kind)==str(pair[3]):
				found=true
				eq(int(stage.enemy.profile),int(pair[1]),"Chapter uses the full specified enemy profile")
				eq(str(stage.enemy.ending),str(pair[2]),"Chapter preserves its narrative ending")
				if int(pair[0])==7:
					check(stage.has("goal"),"Pump confrontation ends at an actual escape position")
					check(ChapterRunCatalog.point(stage.goal).distance_to(ChapterRunCatalog.point(stage.at))>250,"Escape is not satisfied at battle trigger")
		check(found,"Expected encounter exists in chapter %d" % int(pair[0]))
	for id: int in [10,11]:
		for stage: Dictionary in ChapterRunCatalog.read(id).stages:
			check(not stage.has("enemy"),"Chapters 10 and 11 leave room for records without enemies")

func test_save_namespace_and_completed_stage_checkpoint_restore() -> void:
	var host: ChapterRun=_host(8)
	host.suffix="chapter-run-unit-%d" % Time.get_ticks_usec()
	host.save_enabled=true
	var original_path: String=host.save_path()
	check(original_path.begins_with("user://chapters-whitebox/"),"Whitebox has its own namespace")
	var second:=ChapterTwoWhitebox.new()
	var third:=ChapterThreeWhitebox.new()
	second.qa_save_suffix=host.suffix
	third.qa_save_suffix=host.suffix
	check(original_path!=second.save_path() and original_path!=third.save_path(),"Earlier chapter saves cannot be overwritten")
	second.free()
	third.free()
	host.chapter_id=9
	check(host.save_path()!=original_path,"Each chapter has an independent save")
	host.chapter_id=8
	host.suffix+="-other"
	check(host.save_path()!=original_path,"QA suffixes isolate parallel sessions")
	host.suffix=host.suffix.trim_suffix("-other")
	# 显式完成前五阶段：验证死亡后的恢复点，不宣称执行过封梁交锋。
	for i: int in 5: host.completed.append(str(host.data.stages[i].id))
	host.flags={"qa_after_death":true}
	host.write_save()
	check(not host.save_failed,"Fixture save is written successfully")
	host.completed.clear()
	host.flags.clear()
	host.read_save()
	host.flow.restore()
	eq(host.flow.index,5,"Restore skips only persisted completed stages")
	eq(str(host.flow.stage().id),"ch08_receive_nests","Death aftermath resumes at nest work")
	eq(host.checkpoint(),host.data.stages[5].checkpoint,"Checkpoint belongs to first unfinished stage")
	check(host.flags.get("qa_after_death",false),"Local facts survive serialization")
	check(not is_instance_valid(host.encounter.enemy),"Restore does not restart defeated guard")
	host.encounter.restore_completed_bodies()
	check(is_instance_valid(host.encounter.retired_body),"Ended body remains present after loading aftermath")
	check(not host.encounter.retired_body.data.alive and host.encounter.retired_body.collision_layer==0,"Restored dead guard is nonhostile and has no body collision")
	host.completed.clear()
	for stage: Dictionary in host.data.stages: host.completed.append(str(stage.id))
	host.write_save()
	host.completed.clear()
	host.read_save()
	host.flow.index=0
	host.flow.restore()
	check(host.flow.finished and host.flow.stage().is_empty(),"Fully completed chapter restores to terminated flow")
	eq(host.checkpoint(),host.data.stages.back().checkpoint,"Finished chapter keeps its final checkpoint")
	DirAccess.remove_absolute(original_path)


func test_elder_steps_out_when_player_lands_on_its_head() -> void:
	var host: ChapterRun=_host(12)
	host.flow.index=2
	host.flow.enter()
	host.encounter.spawn(false)
	var enemy: EnemyLabEnemy=host.encounter.enemy
	check(enemy is ChapterRunElder and enemy is EnemyLabElder,"Chapter final boss retains complete elder implementation")
	enemy.auto_attack=false
	for frame: int in 30: await tree.physics_frame
	# 显式接触夹具只验证头顶边界，不作实战通关或伤害证据。
	host.player.position=enemy.position+Vector2(0,-float(enemy.profile.height)-0.1)
	for frame: int in 2: await tree.physics_frame
	enemy.timer=0.5
	enemy.auto_attack=true
	(enemy as ChapterRunElder)._idle_tick(1.0/60)
	eq(enemy.move_key,"elder_vault","Head contact uses existing readable pole-vault action")
	eq(enemy.state,"tell","Response keeps original tell instead of instant damage")

	for frame: int in 40: await tree.physics_frame
	check(host.player.position.y>enemy.position.y-100,"Head contact releases player back toward real floor")


func test_chapter_json_text_is_covered_by_embedded_font() -> void:
	var font:=load("res://art/fonts/WhalefallUI.ttf") as FontFile
	var characters: Dictionary[int,bool]={}
	for chapter: int in range(4,13):
		var value: String=FileAccess.get_file_as_string("res://content/prototypes/chapters/ch%02d.json" % chapter)
		for index: int in value.length():
			var code: int=value.unicode_at(index)
			if code>=0x3400 and code<=0x9fff: characters[code]=true
	for code: int in characters: check(font.has_char(code),"Chapter JSON font missing: "+String.chr(code))
