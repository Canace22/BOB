extends SceneTree
## 隔离循环样板实际键盘路线；主路线不写玩家坐标、不注入能力或无敌。
var host: Node2D
var failures: int = 0
var upper: bool = false
const OUT := "res://build/qa/chapter-loop"
func _initialize() -> void: run.call_deferred()
func tick(n: int) -> void:
	for i: int in n: await process_frame
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func tap(code: Key) -> void:
	key(code,true)
	await tick(2)
	key(code,false)
	await tick(2)
func check(label: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))
func continue_story() -> void:
	if host.player_ui.page_id!="dialogue": return
	key(KEY_A,false)
	key(KEY_D,false)
	key(KEY_SPACE,false)
	await tick(12)
	await tap(KEY_ESCAPE)
	for i: int in 60:
		if not paused and host.player.controls_enabled: return
		await tick(1)
func walk(x: float, jump: bool = false, budget: int = 400) -> bool:
	for i: int in budget:
		if host.player_ui.page_id=="dialogue": await continue_story()
		var p: TidePlayer=host.player
		if p.health<=0: return false
		if absf(p.position.x-x)<12.0:
			key(KEY_A,false)
			key(KEY_D,false)
			key(KEY_SPACE,false)
			await tick(8)
			return true
		key(KEY_D,p.position.x<x)
		key(KEY_A,p.position.x>x)
		if jump and p.is_on_floor():
			if Input.is_action_pressed("tp_jump"): key(KEY_SPACE,false)
			elif i%8==0: key(KEY_SPACE,true)
		if not p.is_on_floor() and p.velocity.y>=0: key(KEY_SPACE,false)
		await tick(1)
	key(KEY_A,false)
	key(KEY_D,false)
	key(KEY_SPACE,false)
	var p: WhalebellyCampaignPlayer=host.player
	print("WALK_STOP target=",x," position=",p.position," state=",p.state," controls=",p.controls_enabled," floor=",p.is_on_floor()," velocity=",p.velocity," collision=",p.get_slide_collision(0).get_collider().get_path() if p.get_slide_collision_count()>0 else "none"," axis=",p.movement_axis()," room=",host.room.id)
	await shot("failed-walk")
	return false
func run() -> void:
	upper="--upper" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host=load("res://tests/whalebelly/chapter_loop_play.tscn").instantiate()
	root.add_child(host)
	current_scene=host
	for i: int in 160:
		if host.player_ui.page_id=="dialogue": break
		await tick(1)
	check("opening establishes reason to seek residents",host.dialogue.active.get("id","")=="loop.arrival")
	await shot("01-arrival")
	await continue_story()
	check("walk reaches resident warning",await walk(485))
	await tick(30)
	if host.player_ui.page_id=="dialogue": await continue_story()
	check("warning explains route and victory condition",host.dialogue.seen.get("loop.warning",false))
	check("two real enemy actors start apart",host.loop.enemies.size()==2 and absf(host.loop.enemies[0].position.x-host.loop.enemies[1].position.x)>200)
	check("checkpoint placed before encounter",int(host.checkpoint.pos[0])==500)
	check("first actor remains alive before engagement",host.loop.enemies[0].data.alive)
	if "--recovery" in OS.get_cmdline_user_args():
		await recovery()
		return
	if upper:
		check("jump reaches observation approach",await walk(670,true))
		for i: int in 80:
			if host.player.is_on_floor(): break
			await tick(1)
		check("upper platform physically supports observation",host.loop.observed and host.player.position.y<470)
		await shot("02-upper-observation")
		check("upper route progresses across real gap",await walk(1060,true))
		check("upper bypass reaches safe approach",await walk(1390,true))
	else:
		check("ground route activates first encounter",await walk(700))
		for i: int in 100:
			if host.loop.enemies[0].state=="tell": break
			await tick(1)
		await shot("02-first-tell")
		check("first enemy provides a visible windup",host.loop.enemies[0].state=="tell")
		var hp: int=host.player.health
		key(KEY_S,true)
		await tap(KEY_L)
		key(KEY_S,false)
		await tick(38)
		check("backstep is usable against the actual enemy",host.loop.backsteps>0 and host.player.health==hp)
		# 重进攻使用正常J键；不写敌人血量或压力来假造压退。
		for i: int in 700:
			var enemy: WhaleChapterForager=host.loop.enemies[0]
			if enemy.withdrawing: break
			if host.player.health<=0: break
			var gap: float=enemy.position.x-host.player.position.x
			key(KEY_D,gap>90 and host.player.state_duration<=0.0)
			if gap<=120 and i%26==0: await tap(KEY_J)
			await tick(1)
		key(KEY_D,false)
		check("real strikes pressure first enemy into retreat",host.loop.enemies[0].withdrawing)
		check("retreat does not become a kill",host.loop.enemies[0].data.alive and int(host.loop.enemies[0].data.hp)>0)
		check("second enemy joins after first pressure",host.loop.enemies[1].awake)
		await shot("03-first-withdraw")
		check("ground path approaches second enemy",await walk(960))
		for i: int in 700:
			var enemy: WhaleChapterForager=host.loop.enemies[1]
			if enemy.withdrawing or host.player.health<=0: break
			var gap: float=enemy.position.x-host.player.position.x
			key(KEY_D,gap>90 and host.player.state_duration<=0.0)
			if gap<=120 and i%26==0: await tap(KEY_J)
			await tick(1)
		key(KEY_D,false)
		check("second enemy can also be pressured without killing",host.loop.enemies[1].withdrawing and host.loop.enemies[1].data.alive)
		check("ground path reaches inner lamp",await walk(1390))
	for i: int in 180:
		if host.player_ui.page_id=="dialogue" or host.dialogue.seen.get("loop.aftermath",false): break
		await tick(1)
	check("standing safe platform completes passage without kills",host.loop.passed and host.loop.enemies.all(func(e: WhaleChapterForager) -> bool: return e.data.alive))
	check("victory ends pursuit before dialogue",host.loop.enemies.all(func(e: WhaleChapterForager) -> bool: return e.withdrawing and not e.is_in_group("tide_targets")))
	check("aftermath conversation follows player achievement",host.dialogue.active.get("id","")=="loop.aftermath" or host.dialogue.seen.get("loop.aftermath",false))
	await shot("04-aftermath")
	await continue_story()
	check("aftermath supplies next destination and question",host.dialogue.objective.get("id","")=="loop.go_foldwell")
	if upper: key(KEY_D,true)
	else:
		check("manual entrance can be reached",await walk(1440))
		await tap(KEY_F)
	for i: int in 400:
		if host.room_index==1: break
		await tick(1)
	key(KEY_D,false)
	check("arch route reaches actual foldwell room",host.room_index==1)
	for i: int in 250:
		if host.dialogue.active.get("id","")=="loop.foldwell_arrival": break
		await tick(1)
	check("destination arrival dialogue triggers",host.dialogue.active.get("id","")=="loop.foldwell_arrival")
	await continue_story()
	await tick(20)
	check("sample ends with replay and return choices",host.player_ui.page_id=="chapter_result")
	await shot("05-completed")
	host.player_ui.body.find_child("ReturnPassage",true,false).pressed.emit()
	for i: int in 100:
		if not paused and host.player.controls_enabled: break
		await tick(1)
	check("completed story returns to passage without forcing combat",host.room_index==0 and host.loop.passed and host.loop.enemies.all(func(e: WhaleChapterForager) -> bool: return e.withdrawing))
	print("CHAPTER_LOOP_QA upper=",upper," failures=",failures," health=",host.player.health)
	await host.graceful_quit(0 if failures==0 else 1)

func recovery() -> void:
	check("approach starts encounter",await walk(700))
	for i: int in 1500:
		if host.player_ui.page_id=="death": break
		# 受击后会被推离真实攻击范围，重新靠近而不防御，验证持续敌伤与死亡。
		key(KEY_D,host.loop.enemies[0].position.x-host.player.position.x>75.0 and host.player.controls_enabled)
		await tick(1)
	key(KEY_D,false)
	print("RECOVERY_TRACE health=",host.player.health," enemy=",host.loop.enemies[0].state," hits=",host.loop.enemies[0].contact_hits," pos=",host.player.position)
	check("repeated real enemy sweeps can defeat unguarded player",host.player.health==0 and host.player_ui.page_id=="death")
	var previous: int=host.player.get_instance_id()
	await host.player_ui.retry(true)
	for i: int in 120:
		if not paused and host.player.controls_enabled: break
		await tick(1)
	check("retry rebuilds at pre-encounter checkpoint",host.player.get_instance_id()!=previous and absf(host.player.position.x-500)<12)
	check("retry keeps completed conversations",host.dialogue.seen.get("loop.warning",false) and host.dialogue.active.is_empty())
	check("retry re-arms incomplete encounter",not host.loop.passed and host.loop.enemies.all(func(e: WhaleChapterForager) -> bool: return e.pressure==0 and e.data.alive))
	check("re-entering starts encounter again",await walk(700))
	check("retreating to entry is physically possible",await walk(515))
	await tick(20)
	check("entry retreat resets encounter without completing it",not host.loop.encounter and not host.loop.passed and host.loop.enemies.all(func(e: WhaleChapterForager) -> bool: return not e.awake))
	print("CHAPTER_LOOP_RECOVERY failures=",failures)
	await host.graceful_quit(0 if failures==0 else 1)
