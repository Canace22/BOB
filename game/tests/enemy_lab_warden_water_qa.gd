extends "res://tests/enemy_lab_warden_qa.gd"
## 所有水术在默认无设施Boss场内验证，单招明确初始站位夹具。
func setup_water(x: float=540.0) -> EnemyLabWarden:
	var e: EnemyLabWarden=await setup_guard()
	lab.player.position=Vector2(x,520)
	lab.player.facing=1.0
	return e

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=5
	lab.terrain=0
	lab.auto_attack=false
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	check("default boss has no membrane pump or relief valve",lab.pump_court==null and (lab.enemies[0] as EnemyLabWarden).court==null)
	check("six moves include all three intrinsic water skills",lab.hud.move_menu.item_count==7)
	var e: EnemyLabWarden=await setup_water(600)
	key(KEY_F,true)
	await tick(3)
	key(KEY_F,false)
	check("F in default encounter does not create a boss weakness",e.state=="idle" and e.water.overloads==0)
	await shot("warden-water-overview")
	e=await setup_water()
	e.begin_attack("warden_barrage")
	await tick(40)
	check("bullet warning uses actor-owned full pressure sac",e.visual.texture==EnemyLabVisual.WARDEN_WATER and e.visual.pose_id==1)
	check("vulnerable pressure sac glows yellow during preparation",float((e.visual.material as ShaderMaterial).get_shader_parameter("weak_glow"))>0.0)
	await shot("warden-water-barrage-tell")
	await tick(28)
	check("water bullets exist without any scene machine",e.water.total_shots>0 and lab.pump_court==null)
	await shot("warden-water-bullets")
	e=await setup_water()
	e.begin_attack("warden_barrage")
	await tick(30)
	key(KEY_I,true)
	for frame: int in 130:
		await tick(1)
		if e.water.blocks==3 or lab.player.health<5: break
	key(KEY_I,false)
	check("actual front I handles three separate water shots",e.water.blocks==3 and lab.player.health==5)
	check("blocking wave consumes real stance",(lab.player.skill_controller as EnemyLabSkills).guard_meter<35.0)
	await shot("warden-water-three-blocks")
	e=await setup_water()
	e.begin_attack("warden_barrage")
	await tick(30)
	key(KEY_A,true)
	await tick(85)
	key(KEY_A,false)
	check("actual retreat avoids locked bullet wave",lab.player.health==5 and e.water.total_shots==3)
	e=await setup_water(600)
	e.begin_attack("warden_vortex")
	await tick(45)
	check("tornado has its own gathering pose",e.visual.pose_id==5)
	await shot("warden-water-vortex-tell")
	await tick(31)
	key(KEY_SPACE,true)
	key(KEY_D,true)
	await tick(30)
	key(KEY_SPACE,false)
	await shot("warden-water-jump-vortex")
	for frame: int in 100:
		await tick(1)
		if lab.route_passed or get_nodes_in_group("enemy_lab_warden_water").is_empty(): break
	key(KEY_D,false)
	check("actual jump and lateral escape avoid pursuing tornado",lab.player.health==5 and e.water.total_shots==1 and e.water.hits==0)
	e=await setup_water(600)
	e.begin_attack("warden_vortex")
	await tick(70)
	key(KEY_I,true)
	for frame: int in 50:
		await tick(1)
		if e.water.blocks>0 or lab.player.health<5: break
	key(KEY_I,false)
	check("timed I breaks vortex and unloads its caster",e.water.blocks==1 and e.water.overloads==1 and lab.player.health==5)
	await shot("warden-water-vortex-counter")
	e=await setup_water(800)
	e.auto_attack=true
	var saw_wash: bool=false
	for cycle: int in 18:
		key(KEY_J,true)
		await tick(6)
		key(KEY_J,false)
		for frame: int in 14:
			if e.state=="wash" and not saw_wash:
				saw_wash=true
				await shot("warden-water-step-trail")
			await tick(1)
		if lab.player.health<5 or e.health<=0: break
	check("actual central J pressure triggers water escape",saw_wash and e.water.escapes>0)
	check("stationary J cannot safely kill through waterstep counter",lab.player.health<5 and e.health>0)
	e=await setup_water(675)
	e.begin_attack("warden_barrage")
	await tick(25)
	lab.player.position=Vector2(900,520)
	lab.player.facing=-1.0
	key(KEY_E,true)
	key(KEY_J,true)
	await tick(30)
	key(KEY_J,false)
	key(KEY_E,false)
	check("actual rear E+J overloads sac and cancels barrage",e.water.overloads==1 and e.water.total_shots==0)
	await shot("warden-water-sac-overload")
	e=await setup_water()
	e.begin_attack("warden_barrage")
	await tick(65)
	await tap(KEY_R)
	await tick(12)
	check("actual R clears water shots and caster sequence",not is_instance_valid(e) and get_nodes_in_group("enemy_lab_warden_water").is_empty())
	print("ENEMY_LAB_WARDEN_WATER failures=",failures)
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)
