extends "res://tests/whalebelly/chapter_loop_regression.gd"
## 起点用实际输入；招式/站位夹具用于逐项复核表现与真实格挡、反击，不声称自然通关。

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host=load("res://tests/whalebelly/chapter_loop_play.tscn").instantiate()
	root.add_child(host)
	current_scene=host
	for i: int in 160:
		if host.player_ui.page_id=="dialogue": break
		await tick(1)
	await continue_story()
	check("reach warning",await walk(485))
	await tick(25)
	await continue_story()
	check("encounter reached by movement",await walk(700))
	var e: WhaleChapterForager=host.loop.enemies[0]
	var p: TideCombatPlayer=host.player
	for enemy: WhaleChapterForager in host.loop.enemies: enemy.set_physics_process(false)
	# 单招夹具：隔离第二只，使用同一正式主角与伤害路径，不授予能力或无敌。
	e.position=Vector2(850,host.ground_y(850,560))
	p.position=e.position-Vector2(75,0)
	p.velocity=Vector2.ZERO
	e.facing=-1.0
	p.facing=1.0
	e.awake=true
	e.withdrawing=false
	e.pressure=0
	e.attack_serial=1
	await tick(8)
	for kind: String in ["sweep","rush","double"]:
		e.attack_kind=kind
		e.followup=false
		e.change("tell")
		e.timer=0.4
		e._physics_process(0.0)
		check("authored visual active for "+kind,e.visual is WhaleForagerVisual and e.visual.texture!=null)
		check("tell progress visible for "+kind,e.phase_bar.visible and e.phase_bar.value>0.0)
		check("progress bars stay thin for "+kind,e.phase_bar.size.y<=6.0 and e.pressure_bar.size.y<=6.0)
		await shot("forager-tell-"+kind)
	e.attack_kind="double"
	e.followup=false
	e.change("active")
	var hp: int=p.health
	key(KEY_I,true)
	await tick(8)
	key(KEY_I,false)
	e.advance_action(0.07)
	check("actual I guard deflects",p.skill_controller.parried and p.health==hp)
	check("guard interrupts double into opening",e.state=="recover" and not e.followup)
	e._physics_process(0.0)
	await shot("forager-guard-opening")
	await tick(40)
	# 主角已结束格挡，保留敌人的破绽夹具以明确验证J的实际命中链路。
	e.change("recover")
	e.timer=0.10
	key(KEY_J,true)
	await tick(14)
	key(KEY_J,false)
	check("actual J counter earns extra pressure",e.counter_hits==1 and e.pressure==3)
	check("counter remains nonlethal",e.data.alive and not e.withdrawing)
	print("FORAGER_READABILITY_NATIVE failures=",failures)
	await host.graceful_quit(0 if failures==0 else 1)
