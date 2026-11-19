extends "res://tests/whalebelly/chapter_loop_regression.gd"
## 原生第一章安全路段的真实键盘顺序验收；不修改角色位置或正式存档。

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host=load("res://tests/whalebelly/chapter_loop_play.tscn").instantiate()
	root.add_child(host)
	current_scene=host
	for i: int in 160:
		if host.player_ui.page_id=="dialogue": break
		await tick(1)
	await continue_story()
	check("reach warning by real movement",await walk(485))
	await tick(25)
	await continue_story()
	check("return to safe input test lane",await walk(300))
	var p: TideCombatPlayer=host.player
	for direction: Key in [KEY_A,KEY_D]:
		for reverse: bool in [false,true]:
			await tick(90)
			key(direction,true)
			await tick(3)
			key(KEY_L if reverse else KEY_S,true)
			await tick(2)
			if reverse: check("moving L waits instead of starting charge",not p.skill_controller.active and p.state!="A1_dash")
			key(KEY_S if reverse else KEY_L,true)
			await tick(2)
			check("native both movement directions/orders backstep",p.retreating)
			check("backstep keeps charge cooldown unspent",float(p.cooldowns.get("wb_charge",0.0))<=0.0)
			if reverse and direction==KEY_D: await shot("backstep-reverse-moving")
			for code: Key in [direction,KEY_S,KEY_L]: key(code,false)
	await tick(90)
	# 连斩在正常主线尚未解锁，用开局可用的横扫建立取消前置，不注入能力。
	check("attack setup",p.request_action("wb_draw"))
	p.hitstop=0.10
	key(KEY_L,true)
	await tick(2)
	key(KEY_S,true)
	await tick(2)
	check("reverse chord forcibly cancels native attack in hitstop",p.retreating and not p.skill_controller.active)
	key(KEY_L,false)
	key(KEY_S,false)
	print("BACKSTEP_CHORD_NATIVE failures=",failures)
	await host.graceful_quit(0 if failures==0 else 1)
