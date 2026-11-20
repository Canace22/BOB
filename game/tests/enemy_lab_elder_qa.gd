extends "res://tests/enemy_lab_qa.gd"
## 单招明确站位夹具；末尾从默认起点按键交战，不注入生命或无敌。
func setup_elder(gap: float=130.0) -> EnemyLabElder:
	for code: Key in [KEY_J,KEY_I,KEY_A,KEY_D,KEY_SPACE,KEY_S,KEY_L]: key(code,false)
	lab.auto_attack=false
	lab.reset_round()
	await tick(14)
	lab.player.position=Vector2(855.0-gap,520)
	lab.player.facing=1.0
	return lab.enemies[0] as EnemyLabElder

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.auto_attack=false
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	for i: int in 7: await tap(KEY_F1)
	await tick(10)
	check("F1 selects eighth enemy on flat arena",lab.enemies[0] is EnemyLabElder and lab.terrain==0)
	var e: EnemyLabElder=await setup_elder(95)
	await shot("elder-overview")
	await tap(KEY_J)
	await tick(12)
	check("actual front J tests stable armor",e.health==24 and e.reactions.damage_remainder==0.5)
	e=await setup_elder(95)
	lab.player.position=e.position+Vector2(95,0)
	lab.player.facing=-1.0
	await tap(KEY_J)
	await tick(12)
	check("actual rear J bypasses stable front armor",e.health==23 and e.reactions.damage_remainder==0.0)
	await shot("elder-rear-opening")
	e=await setup_elder()
	key(KEY_I,true)
	await tick(25)
	e.begin_attack("elder_sweep")
	for frame: int in 100:
		await tick(1)
		if e.parry_count>0 or lab.player.health<5: break
	key(KEY_I,false)
	check("actual I blocks low gate sweep",lab.player.health==5 and e.parry_count==1)
	e=await setup_elder()
	e.begin_attack("elder_sweep")
	await tick(40)
	key(KEY_SPACE,true)
	await tick(25)
	key(KEY_SPACE,false)
	await tick(20)
	check("actual jump clears low sweep",lab.player.health==5)
	e=await setup_elder()
	e.begin_attack("elder_thrust")
	await tick(35)
	check("braced thrust uses red body warning",float((e.visual.material as ShaderMaterial).get_shader_parameter("danger"))>0.0)
	await shot("elder-thrust-warning")
	key(KEY_I,true)
	for frame: int in 80:
		await tick(1)
		if lab.player.health<5: break
	key(KEY_I,false)
	check("red long thrust cannot be held guarded",lab.player.health<5 and e.parry_count==0)
	e=await setup_elder()
	e.begin_attack("elder_thrust")
	await tick(36)
	key(KEY_A,true)
	await tick(75)
	key(KEY_A,false)
	check("ordinary walking retreat escapes committed thrust",lab.player.health==5)
	e=await setup_elder(90)
	key(KEY_I,true)
	await tick(25)
	e.begin_attack("elder_grip")
	for frame: int in 100:
		await tick(1)
		if e.pulse==2: break
	check("first ordinary guard preserves new second grip tell",e.parry_count==1 and e.state=="tell" and e.pulse==2 and e.visual.pose_id==14)
	await shot("elder-second-grip")
	for frame: int in 65:
		await tick(1)
		if e.parry_count==2 or lab.player.health<5: break
	key(KEY_I,false)
	check("held I must pay for two real contacts",lab.player.health==5 and e.parry_count==2 and (lab.player.skill_controller as EnemyLabSkills).guard_meter<45.0)
	e=await setup_elder(90)
	key(KEY_I,true)
	await tick(25)
	e.begin_attack("elder_grip")
	for frame: int in 100:
		await tick(1)
		if e.parry_count>0: break
	key(KEY_I,false)
	for frame: int in 70:
		await tick(1)
		if e.pulse==2 and e.timer>=0.33: break
	key(KEY_I,true)
	for frame: int in 55:
		await tick(1)
		if e.parry_count==2 or lab.player.health<5: break
	key(KEY_I,false)
	check("timed final I breaks stable stance with longer opening",lab.player.health==5 and e.parry_count==2 and e.opening_left>1.3 and not e.stable)
	await shot("elder-final-perfect")
	e=await setup_elder(110)
	e.begin_attack("elder_vault")
	for frame: int in 80:
		await tick(1)
		if e.state=="vault": break
	var from: Vector2=e.position
	await tick(14)
	check("staff vault physically crosses air with visible body",e.state=="vault" and e.position.y<from.y-45 and absf(e.position.x-from.x)>50 and e.visual.visible)
	await shot("elder-vault-air")
	for frame: int in 70:
		await tick(1)
		if e.state=="settle": break
	check("vault lands on opposite side and warns before damage",e.position.x<lab.player.position.x and e.state=="settle" and lab.player.health==5)
	await shot("elder-landing-grip")
	key(KEY_D,true)
	await tick(65)
	key(KEY_D,false)
	check("actual movement during landing tell avoids return strike",lab.player.health==5)
	e=await setup_elder(95)
	e.position.x+=100
	lab.player.position.x=e.position.x-95
	e.stable=false
	e.set_state("reground")
	await tap(KEY_J)
	await tick(12)
	check("actual J stops replant and forces unstable stance",e.cycle.replant_interrupts==1 and e.force_unstable and not e.stable)
	await shot("elder-replant-denied")
	e=await setup_elder(45)
	e.auto_attack=true
	for cycle: int in 25:
		key(KEY_J,true)
		await tick(6)
		key(KEY_J,false)
		await tick(14)
		if lab.player.health<5 or e.health<=0: break
	check("point blank repeated J cannot safely kill elder",lab.player.health<5 and e.health>0)
	e=await setup_elder()
	e.begin_attack("elder_vault")
	await tick(55)
	await tap(KEY_P)
	var frozen: Vector2=e.position
	await tick(8)
	check("P freezes physical vault position",paused and e.position==frozen)
	await tap(KEY_P)
	await tap(KEY_R)
	await tick(14)
	check("actual R deletes old vault owner",not is_instance_valid(e) and lab.enemies[0].health==24)
	await natural_fight()
	print("ENEMY_LAB_ELDER failures=",failures)
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)

func natural_fight() -> void:
	lab.auto_attack=true
	lab.reset_round()
	await tick(14)
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	for frame: int in 3600:
		if lab.player.health<=0 or not e.outcome.is_empty(): break
		var gap: float=e.position.x-lab.player.position.x
		var red: bool=e.move_key=="elder_thrust" and e.state in ["tell","active"]
		var direction: float=-signf(gap) if red else (signf(gap) if absf(gap)>85.0 else 0.0)
		key(KEY_A,direction<0)
		key(KEY_D,direction>0)
		key(KEY_I,(e.move_key in ["elder_sweep","elder_grip"] and e.state in ["tell","active"]) or e.state=="settle" or (e.move_key=="elder_vault" and e.state=="active"))
		key(KEY_J,e.state in ["recover","hurt","reground"] and absf(gap)<125.0 and frame%18<6)
		await tick(1)
	for code: Key in [KEY_A,KEY_D,KEY_I,KEY_J]: key(code,false)
	print("ELDER_ROUTE hp=",lab.player.health," elder=",e.health," serial=",e.attack_serial," vault=",e.cycle.vaults," denied=",e.cycle.replant_interrupts," end=",e.outcome)
	check("actual default approach and reads disable elder alive",lab.player.health>0 and e.outcome=="surrender" and e.data.alive and e.health==0)
	var hp: int=lab.player.health
	await tick(90)
	check("surrender has no late attack or second fight",lab.player.health==hp and e.state=="ended")
	await shot("elder-natural-fight")
