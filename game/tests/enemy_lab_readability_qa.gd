extends "res://tests/enemy_lab_qa.gd"
## 真实I长按格挡/反击；动作截图明确使用阶段夹具，不冒充自然通关。
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.auto_attack=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	for index: int in 3:
		lab.profile_index=index
		lab.reset_round()
		await tick(12)
		var e: EnemyLabEnemy=lab.enemies[0]
		e.set_physics_process(false)
		for move: String in e.profile.moves:
			e.set_state("idle")
			check("begin authored "+move,e.begin_attack(move))
			e.timer=float(e.spec.tell)*0.80
			e.visual.present(e)
			await shot("readability-"+move+"-tell")
			e.set_state("active")
			e.timer=0.08
			e.visual.present(e)
			await shot("readability-"+move+"-active")
			check("authored region "+move,e.visual.pose_id>=4 and e.visual.region_rect.size.x>100)
	lab.profile_index=1
	lab.reset_round()
	await tick(12)
	var e: EnemyLabEnemy=lab.enemies[0]
	lab.player.position=e.position-Vector2(80,0)
	lab.player.facing=1.0
	key(KEY_I,true)
	await tick(80)
	var guard: EnemyLabSkills=lab.player.skill_controller as EnemyLabSkills
	check("early held I remains defensive",guard.guard_open())
	check("heavy press starts naturally timed",e.begin_attack("press"))
	for i: int in 100:
		if guard.guard_count>0: break
		await tick(1)
	check("held I blocks heavy enemy",guard.guard_count==1 and lab.player.health==5 and not guard.perfect)
	check("block staggers heavy and grants counter",e.state=="recover" and guard.counter_bonus==1)
	await shot("readability-held-block")
	key(KEY_I,false)
	key(KEY_J,true)
	await tick(20)
	key(KEY_J,false)
	check("real J immediately counters for bonus",e.health==e.maximum-2 and guard.counter_bonus==0)
	await shot("readability-counter")
	lab.profile_index=0
	lab.reset_round()
	await tick(12)
	e=lab.enemies[0]
	lab.player.position=e.position-Vector2(80,0)
	lab.player.facing=1.0
	check("timed double begins",e.begin_attack("double"))
	await tick(18)
	key(KEY_I,true)
	await tick(18)
	guard=lab.player.skill_controller as EnemyLabSkills
	check("real timed I grants perfect reward",guard.guard_count==1 and guard.perfect and guard.counter_bonus==2)
	await shot("readability-perfect-block")
	key(KEY_I,false)
	key(KEY_J,true)
	await tick(20)
	key(KEY_J,false)
	check("real perfect counter earns enhanced damage",e.health==1)
	print("ENEMY_LAB_READABILITY failures=",failures)
	quit(1 if failures else 0)
