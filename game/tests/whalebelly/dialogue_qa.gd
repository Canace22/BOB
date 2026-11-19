extends SceneTree
## 当前主线隔离存档、键盘事件与GPU截图；不导入真实进度。
var host: WhalebellyMain
var failures: int = 0
const OUT := "res://build/qa/dialogue"
func _initialize() -> void: run.call_deferred()
func frames(n: int) -> void:
	for i: int in n: await process_frame
func check(label: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func key(code: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode=code
	e.keycode=code
	e.pressed=down
	Input.parse_input_event(e)
func tap(code: Key) -> void:
	key(code,true)
	await frames(2)
	key(code,false)
	await frames(2)
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(name+".png"))
func wait_modal() -> bool:
	for i: int in 120:
		if host.player_ui.page_id=="dialogue": return true
		await frames(1)
	return false
func await_resume() -> void:
	for i: int in 80:
		if not paused and host.player.controls_enabled: return
		await frames(1)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host=load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","dialogue")
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	host.ui_interactive_in_tests=true
	root.add_child(host)
	current_scene=host
	await frames(35)
	var story: WhaleCampaignDialogue=host.dialogue
	var ui: WhaleCampaignUI=host.player_ui
	if "--reload" in OS.get_cmdline_user_args():
		await reload_save()
		return
	check("QA defaults leave existing input routes uninterrupted",not story.enabled and not paused)
	story.enabled=true
	ui.open("pause")
	await frames(12)
	check("automatic trigger does not steal pause menu",story.active.is_empty() and ui.page_id=="pause")
	ui.close_all()
	await await_resume()
	check("arrival auto starts at a safe landing",await wait_modal())
	check("dialogue suspends combat and controls",paused and not host.player.controls_enabled)
	check("opening begins at first line without carried input",story.cursor==0)
	await frames(12)
	await shot("01-arrival")
	var before: float=host.player.position.x
	key(KEY_D,true)
	await frames(10)
	check("movement cannot advance behind modal",is_equal_approx(host.player.position.x,before))
	key(KEY_D,false)
	await tap(KEY_ENTER)
	check("first confirm reveals current line",story.cursor==0 and ui.dialogue_view.text_label.visible_characters==ui.dialogue_view.text_label.get_total_character_count())
	await shot("01b-arrival-full")
	await tap(KEY_ENTER)
	check("next confirm advances one line",story.cursor==1)
	await frames(12)
	key(KEY_SPACE,true)
	await frames(2)
	key(KEY_SPACE,false)
	await frames(2)
	check("space reveals without jumping",host.player.jump_buffer==0.0)
	await tap(KEY_ENTER)
	await await_resume()
	check("normal completion restores control",not paused and host.player.controls_enabled and story.active.is_empty())
	check("completion records stable ID and objective",story.seen.get("opening.arrival",false) and story.objective.id=="opening.inspect_lamp")
	await frames(20)
	check("staying in trigger does not replay completed arrival",story.active.is_empty())
	await shot("02-objective")
	check("F interaction prompt has priority over camp",ui.data.prompt()=="查看灯旁刻痕")
	var manual_start: Vector2=host.player.position
	key(KEY_D,true)
	await tap(KEY_F)
	key(KEY_D,false)
	check("manual dialogue stops movement in its opening physics tick",host.player.position.distance_to(manual_start)<1.0)
	check("physical F starts manual dialogue without camp menu",ui.page_id=="dialogue" and story.active.get("id","")=="opening.lamp")
	await frames(15)
	await shot("03-inscription")
	key(KEY_D,true)
	await tap(KEY_ESCAPE)
	await frames(20)
	check("skip commits record but waits for movement release",story.seen.get("opening.lamp",false) and ui.pending_resume and not host.player.controls_enabled)
	key(KEY_D,false)
	await await_resume()
	check("skip still advances to the next objective",story.objective.id=="opening.follow_road" and not paused)
	check("completed inscription returns F to original camp interaction",ui.data.prompt()=="在营地歇息")
	# 关卡作者可显式开启重复交流；默认样板读一次后不占用营地F键。
	host.scenery.get_node("OpeningNarrative/LampInscription").once=false
	await tap(KEY_F)
	check("repeatable inscription can be read again",story.active.get("id","")=="opening.lamp")
	key(KEY_Q,true)
	await tap(KEY_ESCAPE)
	await frames(20)
	check("resume waits for combat page modifier release",ui.pending_resume and not host.player.controls_enabled)
	key(KEY_Q,false)
	await await_resume()
	check("resume does not reopen held combo page",host.player.pad_input.effective_page()==0)
	# 真实按键走入字幕触发范围，不写玩家位置。
	key(KEY_D,true)
	for i: int in 150:
		if story.seen.get("opening.distant_song",false): break
		await frames(1)
	key(KEY_D,false)
	check("walking into trigger starts nonmodal subtitle",story.subtitle_left>0.0 and not paused and host.player.controls_enabled)
	check("subtitle updates goal without key input",story.objective.id=="opening.follow_song")
	await shot("04-moving-subtitle")
	host.save_progress(false)
	var saved: Dictionary=WhaleUISaveAccess.read(host.save_path(),host.rooms)
	check("V6 saves dialogue records and updated goal",saved.narrative==story.to_save())
	var before_restore: Dictionary=story.to_save()
	story.restore({})
	host.load_progress()
	check("load restores completed dialogue and goal together",story.to_save()==before_restore)
	check("old room goal is scoped to its room",story.objective_hint().contains("右侧骨路"))
	# 配置条件与战斗延后：专项触发器只放在当前活动房，内容为测试占位。
	var queued := WhaleDialogueTrigger.new()
	queued.dialogue_id="qa.deferred"
	queued.room_id=str(host.room.id)
	queued.lines=PackedStringArray(["危险解除后再说。"])
	queued.area=Rect2(-10000,-10000,20000,20000)
	host.scenery.add_child(queued)
	host.player._enter("hit",0.8)
	await frames(4)
	check("hurt defers automatic dialogue without consuming it",story.active.is_empty() and not story.seen.has("qa.deferred"))
	check("deferred dialogue starts after hurt ends",await wait_modal())
	check("deferred trigger keeps its identity",story.active.get("id","")=="qa.deferred")
	await tap(KEY_ESCAPE)
	await await_resume()
	queued.queue_free()
	await frames(4)
	# 重新实例化房间模拟检查点重试，已完成开场不再弹。
	host.load_room(0)
	await frames(40)
	check("checkpoint rebuild does not repeat completed opening",story.active.is_empty() and not paused)
	check("records survive actor replacement",story.seen.get("opening.arrival",false))
	var temporary := WhaleDialogueTrigger.new()
	temporary.dialogue_id="qa.cancelled"
	temporary.room_id="R1-01"
	temporary.activation=1
	temporary.lines=PackedStringArray(["中断内容"])
	host.scenery.add_child(temporary)
	check("manual fixture begins",story.play(temporary))
	host.load_room(1)
	await frames(30)
	await await_resume()
	check("actor replacement cancels unfinished dialogue without marking complete",story.active.is_empty() and not story.seen.has("qa.cancelled") and not paused)
	check("previous room objective does not override next room",story.objective_hint().is_empty())
	print("DIALOGUE_QA failures=",failures)
	await host.graceful_quit(0 if failures==0 else 1)

func reload_save() -> void:
	var story: WhaleCampaignDialogue=host.dialogue
	host.load_progress()
	host.load_room(host.room_index,host.checkpoint.get("pos",[]))
	story.enabled=true
	await frames(45)
	check("independent process restores automatic and manual completion",story.seen.get("opening.arrival",false) and story.seen.get("opening.lamp",false))
	check("independent reload does not repeat skipped/completed dialogue",story.active.is_empty() and not paused)
	check("independent reload restores next objective",story.objective.get("id","")=="opening.follow_song")
	check("new journey can start from saved story",host.start_ui_session(true))
	check("new journey clears previous records and objective",story.seen.is_empty() and story.objective.is_empty())
	check("new journey plays opening again",await wait_modal())
	await tap(KEY_ESCAPE)
	await await_resume()
	check("skipping arrival still establishes its goal",story.objective.get("id","")=="opening.inspect_lamp")
	print("DIALOGUE_RELOAD_QA failures=",failures)
	await host.graceful_quit(0 if failures==0 else 1)
