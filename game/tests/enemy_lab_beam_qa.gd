extends "res://tests/enemy_lab_qa.gd"
## 定招站位夹具验证读招，最后从默认起点使用实际输入交战。
func setup_beam() -> EnemyLabBeamGuard:
	for code: Key in [KEY_I,KEY_J,KEY_D,KEY_A,KEY_SPACE,KEY_S,KEY_L,KEY_Z]: key(code,false)
	lab.auto_attack=false
	lab.reset_round()
	await tick(14)
	lab.player.position=Vector2(750,520)
	lab.player.facing=1.0
	return lab.enemies[0] as EnemyLabBeamGuard

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.auto_attack=false
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	for i: int in 6: await tap(KEY_F1)
	await tick(10)
	check("actual F1 selects seventh distinct enemy",lab.enemies[0] is EnemyLabBeamGuard and lab.terrain==0)
	var e: EnemyLabBeamGuard=await setup_beam()
	await shot("beam-overview")
	e.begin_attack("beam_brace")
	lab.player.position.x=500
	await tap(KEY_J)
	await tick(62)
	check("out of range J never triggers brace counter",e.counters==0 and lab.player.health==5)
	e=await setup_beam()
	e.begin_attack("beam_brace")
	key(KEY_J,true)
	for frame: int in 25:
		await tick(1)
		if e.counters>0: break
	key(KEY_J,false)
	check("actual front J causes one fresh counter tell",e.counters==1 and e.state=="tell" and e.timer<0.15 and e.reactions.received==1)
	check("brace damage is retained and red starts after contact",e.reactions.damage_remainder==0.5 and float((e.visual.material as ShaderMaterial).get_shader_parameter("danger"))>0.0)
	await shot("beam-hit-triggered-red")
	key(KEY_I,true)
	for frame: int in 100:
		await tick(1)
		if lab.player.health<5: break
	key(KEY_I,false)
	check("red counter defeats held I instead of becoming free guard reward",lab.player.health<5 and e.parry_count==0)
	e=await setup_beam()
	e.begin_attack("beam_brace")
	await tap(KEY_J)
	await tick(30)
	key(KEY_S,true)
	key(KEY_L,true)
	await tick(6)
	key(KEY_S,false)
	key(KEY_L,false)
	await tick(55)
	check("actual S+L cancels offense and escapes counter",lab.player.health==5 and e.counters==1 and e.state=="recover")
	await shot("beam-counter-evaded")
	e=await setup_beam()
	e.begin_attack("beam_brace")
	lab.player.position=e.position+Vector2(95,0)
	lab.player.facing=-1.0
	await tap(KEY_J)
	await tick(12)
	check("actual rear J breaks brace without retaliation",e.rear_breaks==1 and e.counters==0 and e.health==17 and e.control_window_open())
	await shot("beam-rear-break")
	e=await setup_beam()
	key(KEY_I,true)
	await tick(25)
	e.begin_attack("beam_press")
	for frame: int in 95:
		await tick(1)
		if e.parry_count>0 or lab.player.health<5: break
	key(KEY_I,false)
	check("ordinary I stops overhead and earns short opening",e.parry_count==1 and e.state=="recover" and e.opening_left<=0.65 and lab.player.health==5)
	e=await setup_beam()
	e.begin_attack("beam_press")
	await tick(40)
	key(KEY_I,true)
	for frame: int in 50:
		await tick(1)
		if e.parry_count>0 or lab.player.health<5: break
	key(KEY_I,false)
	check("timed I earns longer perfect opening",e.parry_count==1 and e.opening_left>1.0 and lab.player.health==5)
	await tap(KEY_J)
	await tick(18)
	check("actual J converts guard into counter damage",e.health<16)
	await shot("beam-perfect-counter")
	e=await setup_beam()
	e.begin_attack("beam_return")
	key(KEY_D,true)
	await tick(25)
	check("retreat moves root while blade and locked facing threaten pursuit",e.retreat_distance>45 and e.facing==-1.0 and not e.control_window_open())
	await shot("beam-retreat-bait")
	await tick(65)
	key(KEY_D,false)
	check("reckless actual D pursuit is hit by returning low blade",lab.player.health<5)
	e=await setup_beam()
	e.begin_attack("beam_return")
	key(KEY_D,true)
	await tick(25)
	key(KEY_SPACE,true)
	await tick(25)
	key(KEY_SPACE,false)
	key(KEY_D,false)
	await tick(35)
	check("actual jump over return cut preserves health",lab.player.health==5)
	await shot("beam-return-jumped")
	e=await setup_beam()
	lab.player.position=e.position-Vector2(38,0)
	e.auto_attack=true
	for cycle: int in 25:
		key(KEY_J,true)
		await tick(6)
		key(KEY_J,false)
		await tick(14)
		if lab.player.health<5 or e.health<=0: break
	check("point blank repeated J cannot kill boss without resistance",lab.player.health<5 and e.health>0)
	e=await setup_beam()
	e.begin_attack("beam_brace")
	e.take_hit(1)
	await tap(KEY_P)
	var time: float=e.timer
	await tick(10)
	check("P freezes counter clock",paused and e.timer==time)
	await tap(KEY_P)
	await tap(KEY_R)
	await tick(14)
	check("actual R clears counter and old owner",not is_instance_valid(e) and lab.enemies[0].health==18)
	await traversal()
	await natural_fight()
	print("ENEMY_LAB_BEAM failures=",failures)
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)

func natural_fight() -> void:
	lab.auto_attack=true
	lab.reset_round()
	await tick(14)
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	# 从默认起点靠近；只根据可见阶段决定格挡、跳低扫和收招短打。
	for frame: int in 2400:
		if lab.player.health<=0 or not e.outcome.is_empty(): break
		var gap: float=e.position.x-lab.player.position.x
		var opening: bool=e.state in ["recover","hurt"]
		var brace: bool=e.state=="brace"
		var low: bool=e.move_key=="beam_return" and e.state in ["tell","active"]
		key(KEY_A,gap< -80.0 and not brace)
		key(KEY_D,gap>80.0 and not brace)
		key(KEY_I,e.move_key=="beam_press" and e.state in ["tell","active"])
		key(KEY_SPACE,low and e.timer>0.25)
		key(KEY_J,opening and absf(gap)<125.0 and frame%18<6)
		await tick(1)
	for code: Key in [KEY_A,KEY_D,KEY_I,KEY_SPACE,KEY_J]: key(code,false)
	print("BEAM_ROUTE hp=",lab.player.health," enemy=",e.health," serial=",e.attack_serial," end=",e.outcome)
	check("actual approach and read-then-punish route defeats boss",lab.player.health>0 and e.outcome=="kill" and e.attack_serial>=3)
	await shot("beam-natural-fight")

func traversal() -> void:
	var e: EnemyLabBeamGuard=await setup_beam()
	key(KEY_D,true)
	await tick(28)
	key(KEY_D,false)
	check("ordinary walking cannot pass through guard body",lab.player.position.x<e.position.x-35)
	lab.player.facing=1.0
	await tap(KEY_L)
	await tick(23)
	check("actual stationary L dash can pass solid guard",lab.player.position.x>e.position.x+35)
	e=await setup_beam()
	key(KEY_D,true)
	key(KEY_SPACE,true)
	await tick(30)
	key(KEY_SPACE,false)
	await tick(20)
	key(KEY_D,false)
	check("actual jump and movement reach rear without hidden wall",lab.player.position.x>e.position.x+45 and lab.player.health==5)
