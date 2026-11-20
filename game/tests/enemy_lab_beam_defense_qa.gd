extends "res://tests/enemy_lab_beam_qa.gd"
## 明确站位夹具使用实际按键；自然交战沿用默认起点路线。
func setup_defense() -> EnemyLabBeamGuard:
	var e: EnemyLabBeamGuard=await setup_beam()
	e.begin_attack("beam_guard")
	for frame: int in 30:
		await tick(1)
		if e.state=="guarding": break
	return e

func hit_guard(e: EnemyLabBeamGuard) -> void:
	key(KEY_J,true)
	for frame: int in 25:
		await tick(1)
		if e.defense.blocks>0: break
	key(KEY_J,false)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=6
	lab.auto_attack=false
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	check("fourth menu move is active defense",lab.hud.move_menu.item_count==5 and lab.enemies[0].profile.moves[3]=="beam_guard")
	var e: EnemyLabBeamGuard=await setup_defense()
	await shot("beam-active-guard")
	await hit_guard(e)
	check("actual front J blocked without HP loss",e.health==18 and e.defense.blocks==1 and e.state=="guard_contact")
	await tick(1)
	check("guard contact uses visible metal ring and no flesh stop",e.defense.ring.visible and e.feedback.stop_left==0.0)
	await shot("beam-guard-impact")
	for frame: int in 50:
		await tick(1)
		if e.move_key=="beam_riposte": break
	check("guard confirms into full new counter tell without red",e.state=="tell" and e.timer<0.1 and e.phase_duration()==0.55 and float((e.visual.material as ShaderMaterial).get_shader_parameter("danger"))==0.0)
	await tick(8)
	await shot("beam-riposte-tell")
	for frame: int in 70:
		await tick(1)
		if lab.player.health<5: break
	check("unanswered defense counter actually hits",lab.player.health<5 and e.defense.ripostes==1)
	e=await setup_defense()
	await hit_guard(e)
	await tick(15)
	key(KEY_I,true)
	for frame: int in 90:
		await tick(1)
		if e.parry_count>0 or lab.player.health<5: break
	key(KEY_I,false)
	check("actual I guards the counter slash",lab.player.health==5 and e.parry_count==1 and e.control_window_open())
	await shot("beam-riposte-blocked")
	e=await setup_defense()
	await hit_guard(e)
	await tick(22)
	key(KEY_S,true)
	key(KEY_L,true)
	await tick(6)
	key(KEY_S,false)
	key(KEY_L,false)
	await tick(65)
	check("actual S+L avoids defensive counter",lab.player.health==5 and e.defense.ripostes==1)
	e=await setup_defense()
	key(KEY_S,true)
	key(KEY_J,true)
	await tick(7)
	key(KEY_S,false)
	key(KEY_J,false)
	for frame: int in 45:
		await tick(1)
		if e.defense.breaks>0: break
	check("actual S+J heavy breaks active guard",e.health<=15 and e.defense.breaks==1 and e.defense.blocks==0 and e.control_window_open())
	await shot("beam-heavy-guard-break")
	e=await setup_defense()
	lab.player.position=e.position+Vector2(95,0)
	lab.player.facing=-1.0
	await tap(KEY_J)
	await tick(14)
	check("actual rear J bypasses guard and cancels counter",e.health==17 and e.defense.breaks==1 and e.defense.ripostes==0)
	e=await setup_defense()
	key(KEY_E,true)
	key(KEY_J,true)
	await tick(7)
	key(KEY_E,false)
	key(KEY_J,false)
	await tick(50)
	check("actual E+J multihit exhausts guard before counter",e.defense.blocks==1 and e.defense.breaks==1 and e.defense.ripostes==0 and e.health<18)
	await shot("beam-multihit-break")
	e=await setup_defense()
	await tick(50)
	check("waiting out guard yields punish window with no hidden hit",e.state=="recover" and e.defense.ripostes==0 and lab.player.health==5)
	await tap(KEY_J)
	await tick(15)
	check("actual J punishes guard whiff",e.health<18)
	e=await setup_defense()
	await hit_guard(e)
	await tap(KEY_R)
	await tick(14)
	check("R deletes confirmed counter and feedback owner",not is_instance_valid(e) and (lab.enemies[0] as EnemyLabBeamGuard).defense.blocks==0)
	await natural_fight()
	print("ENEMY_LAB_BEAM_DEFENSE failures=",failures)
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)
