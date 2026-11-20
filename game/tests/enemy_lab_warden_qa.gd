extends "res://tests/enemy_lab_qa.gd"
## 单招站位为明确夹具，最后从初始站位实际D/I/跳跃走撤离路线。
func setup_guard() -> EnemyLabWarden:
	lab.auto_attack=false
	lab.reset_round()
	await tick(14)
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.position=Vector2(800,520)
	lab.player.position=Vector2(675,520)
	lab.player.facing=1.0
	return e

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.auto_attack=false
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	for i: int in 5: await tap(KEY_F1)
	await tick(8)
	check("actual F1 selects independent boss sample",lab.enemies[0] is EnemyLabWarden and lab.terrain==0)
	lab.select_terrain(3)
	await tick(14)
	await shot("warden-overview")
	var e: EnemyLabWarden=await setup_guard()
	key(KEY_I,true)
	await tick(25)
	e.begin_attack("warden_double")
	for frame: int in 90:
		await tick(1)
		if e.pulse==2: break
	check("ordinary first I guard keeps visible second preparation",e.parry_count==1 and e.pulse==2 and e.state=="tell")
	check("second preparation has own pole-retraction pose",e.visual.pose_id==14)
	await shot("warden-second-tell")
	for frame: int in 65:
		await tick(1)
		if e.parry_count==2 or lab.player.health<5: break
	key(KEY_I,false)
	check("held normal guard must handle two real hits",e.parry_count==2 and lab.player.health==5)
	check("two normal blocks spend meaningful stance",(lab.player.skill_controller as EnemyLabSkills).guard_meter<50.0)
	await shot("warden-two-blocks")
	e=await setup_guard()
	e.begin_attack("warden_double")
	await tick(32)
	key(KEY_I,true)
	for frame: int in 45:
		await tick(1)
		if e.parry_count>0 or lab.player.health<5: break
	key(KEY_I,false)
	check("timed I perfect block cancels second stab",e.parry_count==1 and e.followup_cancelled and e.state=="recover")
	await shot("warden-perfect-break")
	e=await setup_guard()
	lab.player.position=Vector2(740,520)
	key(KEY_I,true)
	await tick(25)
	e.begin_attack("warden_push")
	await tick(32)
	check("crossbar warning uses action without red glow",e.visual.pose_id in [8,9] and float((e.visual.material as ShaderMaterial).get_shader_parameter("danger"))==0.0)
	await shot("warden-crossbar-warning")
	for frame: int in 70:
		await tick(1)
		if e.parry_count>0 or lab.player.health<5: break
	key(KEY_I,false)
	check("crossbar can be guarded but taxes stance",lab.player.health==5 and e.parry_count==1 and (lab.player.skill_controller as EnemyLabSkills).guard_meter<65.0)
	await shot("warden-crossbar-block")
	e=await setup_guard()
	e.begin_attack("warden_double")
	await tick(32)
	key(KEY_A,true)
	await tick(38)
	key(KEY_A,false)
	check("actual retreat avoids stab and cancels far followup",lab.player.health==5 and e.followup_cancelled)
	await shot("warden-missed")
	e=await setup_guard()
	lab.player.position=e.position
	e.auto_attack=true
	for cycle: int in 14:
		key(KEY_J,true)
		await tick(6)
		key(KEY_J,false)
		await tick(14)
		if lab.player.health<5 or e.health<=0: break
	check("close pressure retains visible waterstep response",e.water.escapes>0 and e.health>0)
	await shot("warden-inside-counter")
	lab.auto_attack=true
	lab.reset_round()
	await tick(14)
	e=lab.enemies[0] as EnemyLabWarden
	e.forced_move="warden_thrust"
	key(KEY_D,true)
	await tick(45)
	key(KEY_D,false)
	key(KEY_I,true)
	for frame: int in 110:
		await tick(1)
		if e.parry_count>0 or lab.player.health<5: break
	key(KEY_I,false)
	print("ROUTE first-contact hp=",lab.player.health," blocks=",e.parry_count," player=",lab.player.position," guard=",e.position," phase=",e.state)
	check("actual approach draws a real guarded attack",e.parry_count>0)
	key(KEY_D,true)
	key(KEY_SPACE,true)
	await tick(30)
	key(KEY_SPACE,false)
	for frame: int in 220:
		await tick(1)
		if lab.route_passed or lab.player.health<=0: break
	key(KEY_D,false)
	print("ROUTE exit hp=",lab.player.health," passed=",lab.route_passed," player=",lab.player.position," guard=",e.position," phase=",e.state)
	check("actual guard then movement and jump reaches safe line",lab.route_passed and lab.player.health>0 and lab.player.position.x>=EnemyLabWarden.EXIT_X)
	check("route wins without emptying warden health",e.health>0 and e.outcome=="surrender" and e.data.alive)
	var health: int=lab.player.health
	await tick(120)
	check("exit cancels pursuit and queued late damage",lab.player.health==health and e.state=="ended")
	await shot("warden-route-success")
	await tap(KEY_R)
	await tick(12)
	check("actual R clears route success and restores sentry",not lab.route_passed and lab.enemies[0].health==18)
	e=await setup_guard()
	e.take_hit(100)
	key(KEY_D,true)
	for frame: int in 110:
		await tick(1)
		if lab.route_passed: break
	key(KEY_D,false)
	check("actual exit after nonlethal disable still completes route",lab.route_passed and e.data.alive and e.health==0)
	print("ENEMY_LAB_WARDEN failures=",failures)
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)
