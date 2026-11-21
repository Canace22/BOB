extends "res://tests/whalebelly/chapter_two_qa.gd"
## 显式检查点夹具；死亡由真实守卫攻击产生，重试与跳过走实际按键。

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	host = load("res://content/prototypes/chapter_two/main.tscn").instantiate() as ChapterTwoWhitebox
	host.restore_progress = false
	host.qa_save_suffix = "recovery-test"
	host.facts = {"arrival":true,"refusal":true}
	root.add_child(host)
	current_scene = host
	host.save_progress()
	await tick(30)
	check("refusal checkpoint begins without replaying dialogue",host.flow.stage=="warning" and not host.hud.dialogue.visible)
	key(KEY_D,true)
	for frame: int in 120:
		await tick(1)
		if host.flow.stage=="combat": break
	key(KEY_D,false)
	for frame: int in 2200:
		await tick(1)
		if host.player.health<=0: break
	check("standing without defense dies to real guard attacks",host.player.health<=0 and host.guard.hit_count>=5)
	await shot("08-failure")
	key(KEY_R,true)
	await tick(3)
	key(KEY_R,false)
	await tick(40)
	host = current_scene as ChapterTwoWhitebox
	check("R reload keeps isolated save and restores boss checkpoint",host!=null and host.qa_save_suffix=="recovery-test" and host.player.health==5 and host.flow.stage=="warning" and host.player.position.x<1050)
	# 同一次未完成交锋撤回安全线，敌人应归位而不是半途继续追杀。
	key(KEY_D,true)
	for frame: int in 130:
		await tick(1)
		if host.flow.stage=="combat": break
	key(KEY_D,false)
	key(KEY_A,true)
	for frame: int in 130:
		await tick(1)
		if host.flow.stage=="warning": break
	key(KEY_A,false)
	check("retreat to safety resets only unfinished encounter",host.flow.retreats==1 and host.guard.health==host.guard.maximum and not host.guard.awake)
	# 胜后中断为存档夹具，不计为真实战胜证据；主路径已单独实际按键击败。
	host.facts.guard_defeated = true
	host.save_progress()
	key(KEY_R,true)
	await tick(3)
	key(KEY_R,false)
	await tick(40)
	host = current_scene as ChapterTwoWhitebox
	check("reload after victory never restarts guard hostility",host.guard.outcome=="surrender" and not host.guard.can_receive_hit() and not host.facts.get("permit",false))
	check("victory checkpoint preserves warning about residents",host.flow.dialogue_id=="aftermath")
	await clear_dialogue()
	check("rescue replays from a safe complete state after interruption",host.flow.stage=="rescue" and not host.facts.get("rescue_done",false))
	await tap(KEY_F)
	await tick(5)
	check("F skip settles residents before permission dialogue",host.facts.get("rescue_done",false) and host.flow.dialogue_id=="permit")
	await clear_dialogue()
	check("skipped rescue still yields one consistent permission",host.facts.get("permit",false) and host.flow.stage=="permitted")
	await tap(KEY_ESCAPE)
	check("Esc pauses world after cutscene",paused and host.paused_by_user)
	var before: Vector2 = host.player.position
	key(KEY_D,true)
	await tick(10)
	await tap(KEY_ESCAPE)
	await tick(15)
	check("held movement cannot leak through pause resume",paused and host.player.position==before)
	key(KEY_D,false)
	await tick(20)
	check("release restores control",not paused and host.player.controls_enabled)
	await finish()
