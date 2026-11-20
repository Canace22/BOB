extends "res://tests/enemy_lab_qa.gd"
## 使用真实J连打复现地面压制；明确落地站位夹具，不注入玩家伤害。
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=3
	lab.terrain=2
	lab.auto_attack=false
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	e.position=Vector2(600,520)
	e.spec=EnemyLabCatalog.action("hunter_pounce")
	e.move_key="hunter_pounce"
	e.set_state("recover")
	lab.player.position=Vector2(510,520)
	lab.player.facing=1.0
	var prepared: bool=false
	var jetted: bool=false
	var saw_return: bool=false
	for i: int in 12:
		key(KEY_J,true)
		await tick(6)
		key(KEY_J,false)
		for j: int in 14:
			if e.state=="escape_tell" and not prepared:
				prepared=true
				await tick(1)
				check("ordinary combo retains multiple hits",e.reactions.received>=2)
				check("escape shows compact authored pose",e.visual.pose_id==13)
				check("escape warning is not a red attack",float((e.visual.material as ShaderMaterial).get_shader_parameter("danger"))==0.0)
				await shot("hunter-escape-preparation")
			if e.state=="evade" and not jetted:
				jetted=true
				await tick(1)
				check("jet moves away through actual physics",absf(e.velocity.x)>300.0)
				await shot("hunter-escape-jet")
			if e.state=="return": saw_return=true
			await tick(1)
	check("repeated actual J cannot lock predator to death",prepared and jetted and e.health>0)
	check("escape transitions into visible return",saw_return or e.state=="idle")
	check("one visible water shot follows the prepared escape",e.water_shots==1)
	check("greedy attacker can be hit by the water shot",lab.player.health==4 and e.water_hits==1 and e.hit_count==0)
	await tick(120)
	check("new perch cycle resets pressure",e.state=="idle" and e.pressure_hits==0 and not e.escape_return)
	await shot("hunter-escape-regripped")
	lab.reset_round()
	await tick(14)
	e=lab.enemies[0] as EnemyLabPredator
	e.position=Vector2(600,520)
	e.spec=EnemyLabCatalog.action("hunter_pounce")
	e.move_key="hunter_pounce"
	e.set_state("recover")
	lab.player.position=Vector2(510,520)
	lab.player.facing=1.0
	for i: int in 3:
		key(KEY_J,true)
		await tick(6)
		key(KEY_J,false)
		await tick(14)
	key(KEY_I,true)
	await tick(55)
	key(KEY_I,false)
	check("real I after combo blocks escape water",lab.player.health==5 and e.water_blocks==1)
	await shot("hunter-escape-water-block")
	lab.reset_round()
	await tick(14)
	e=lab.enemies[0] as EnemyLabPredator
	e.position=Vector2(600,520)
	e.spec=EnemyLabCatalog.action("hunter_pounce")
	e.move_key="hunter_pounce"
	e.set_state("recover")
	lab.player.position=Vector2(510,520)
	lab.player.facing=1.0
	for i: int in 3:
		key(KEY_J,true)
		await tick(6)
		key(KEY_J,false)
		await tick(14)
	key(KEY_SPACE,true)
	await tick(30)
	key(KEY_SPACE,false)
	await tick(45)
	check("real jump avoids committed water shot",lab.player.health==5 and e.water_shots==1 and e.water_hits==0 and e.water_blocks==0)
	await shot("hunter-escape-water-dodged")
	print("ENEMY_LAB_ESCAPE failures=",failures)
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)
