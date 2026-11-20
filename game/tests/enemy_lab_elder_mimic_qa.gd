extends "res://tests/enemy_lab_elder_qa.gd"
## 通过实际组合键观招，固定招式夹具与自然选招路线分开。
func pad(keys: Array[Key], held: int=7) -> void:
	for code: Key in keys: key(code,true)
	await tick(held)
	for code: Key in keys: key(code,false)
	await tick(4)

func release_source(e: EnemyLabElder, keys: Array[Key]) -> void:
	await pad(keys)
	for frame: int in 100:
		await tick(1)
		if not e.mimic.memory.is_empty() and not lab.player.skill_controller.active and lab.player.state_duration<=0.0: break

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=7
	lab.auto_attack=false
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	var e: EnemyLabElder=await setup_elder(95)
	check("fifth boss move exposes observation replay",lab.hud.move_menu.item_count==6 and not e.begin_attack("elder_mimic"))
	await release_source(e,[KEY_W,KEY_J])
	check("actual W+J release records uppercut",str(e.mimic.memory.get("key",""))=="wb_rise")
	e.begin_attack("elder_mimic")
	await tick(15)
	check("copy has full tell and visible source pose cue",e.state=="tell" and e.mimic.view.memory_pose.visible and e.timer<float(e.spec.tell))
	await shot("elder-mimic-read-upper")
	for frame: int in 100:
		await tick(1)
		if lab.player.health<5: break
	check("copied upper actually damages through enemy protocol",lab.player.health==4 and e.mimic.casts==1 and e.mimic.emitted==1)
	await shot("elder-mimic-upper-release")
	e=await setup_elder(180)
	await release_source(e,[KEY_S,KEY_J])
	check("actual S+J stores wide heavy geometry",str(e.mimic.memory.get("key",""))=="wb_draw")
	e.begin_attack("elder_mimic")
	await tick(30)
	key(KEY_I,true)
	for frame: int in 80:
		await tick(1)
		if e.parry_count>0 or lab.player.health<5: break
	key(KEY_I,false)
	check("actual I can block copied heavy and end replay",lab.player.health==5 and e.parry_count==1 and e.control_window_open())
	await shot("elder-mimic-heavy-guarded")
	e=await setup_elder(180)
	await release_source(e,[KEY_S,KEY_J])
	e.begin_attack("elder_mimic")
	key(KEY_A,true)
	await tick(95)
	key(KEY_A,false)
	check("actual retreat avoids original radial reach",lab.player.health==5 and e.mimic.emitted==1)
	e=await setup_elder(130)
	await release_source(e,[KEY_E,KEY_J])
	e.begin_attack("elder_mimic")
	for frame: int in 125:
		await tick(1)
		if e.mimic.emitted>=3: break
	check("E+J replay keeps five source release marks",e.mimic.times.size()==5 and e.mimic.emitted>=3)
	await shot("elder-mimic-flurry")
	await tick(65)
	check("flurry emits five bounded pulses",e.mimic.emitted==5 and e.mimic.casts==1)
	e=await setup_elder(250)
	for step: int in 3:
		await pad([KEY_D,KEY_K],6)
		await tick(4)
	await tick(22)
	check("three actual K steps observed",int(e.mimic.memory.get("steps",0))==3)
	e.begin_attack("elder_mimic")
	var from: float=e.position.x
	await tick(105)
	check("copied triple slash has three physical dash cuts",e.mimic.emitted==3 and absf(e.position.x-from)>80)
	await shot("elder-mimic-triple")
	e=await setup_elder(130)
	await release_source(e,[KEY_W,KEY_J])
	e.begin_attack("elder_mimic")
	await pad([KEY_S,KEY_J])
	await tick(25)
	check("actual heavy interrupts copy windup",e.mimic.interrupted==1 and e.mimic.casts==0 and e.control_window_open())
	await shot("elder-mimic-interrupted")
	e=await setup_elder(330)
	await release_source(e,[KEY_E,KEY_L])
	await tick(85)
	check("actual E+L projectile release observed",str(e.mimic.memory.get("key",""))=="orb")
	e.begin_attack("elder_mimic")
	for frame: int in 100:
		await tick(1)
		if not e.mimic.orb_refs.is_empty(): break
	check("copied ranged skill produces owned projectile",not e.mimic.orb_refs.is_empty())
	await shot("elder-mimic-orb")
	await tap(KEY_R)
	await tick(14)
	check("R removes copy memory and hostile projectile",not is_instance_valid(e) and (lab.enemies[0] as EnemyLabElder).mimic.memory.is_empty() and get_nodes_in_group("tide_hostile_projectiles").is_empty())
	e=await setup_elder(130)
	key(KEY_S,true)
	key(KEY_J,true)
	await tick(6)
	key(KEY_S,false)
	key(KEY_J,false)
	await tap(KEY_Z)
	await tick(30)
	check("real canceled S+J is not recorded",not e.mimic.repertoire.learned.has("wb_draw") and e.mimic.repertoire.learned.has("backstep"))
	await natural_observation()
	print("ENEMY_LAB_ELDER_MIMIC failures=",failures)
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)

func natural_observation() -> void:
	lab.auto_attack=true
	lab.reset_round()
	await tick(14)
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	await pad([KEY_E,KEY_K])
	for frame: int in 1000:
		if lab.player.health<=0 or not e.outcome.is_empty() or e.mimic.casts>0: break
		var gap: float=e.position.x-lab.player.position.x
		var red: bool=e.move_key=="elder_thrust" and e.state in ["tell","active"]
		var direction: float=-signf(gap) if red else (signf(gap) if absf(gap)>85 else 0.0)
		key(KEY_A,direction<0)
		key(KEY_D,direction>0)
		key(KEY_I,e.move_key in ["elder_sweep","elder_grip","elder_mimic"] and e.state in ["tell","active"])
		await tick(1)
	for code: Key in [KEY_A,KEY_D,KEY_I]: key(code,false)
	print("MIMIC_ROUTE hp=",lab.player.health," serial=",e.attack_serial," key=",e.mimic.source_key," copies=",e.mimic.casts)
	check("default AI learns actual skill and later chooses replay",lab.player.health>0 and e.mimic.casts>0 and e.attack_serial>=3 and e.mimic.source_key=="cyclone")
	await shot("elder-mimic-natural-choice")
