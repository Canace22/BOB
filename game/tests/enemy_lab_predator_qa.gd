extends "res://tests/enemy_lab_qa.gd"
## 按键移动/格挡/普攻走实际内核；明确站位夹具用于单招判定。
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.auto_attack=false
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	for i: int in 3:
		await tap(KEY_F1)
		await tick(8)
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	check("real F1 selects predator and matching stage",e!=null and lab.terrain==2 and lab.hud.enemy_menu.selected==3)
	check("dedicated sprite and perch loaded",e.visual.texture.resource_path.contains("enemy-lab-predator-squid-jelly-v1/membrane_hunter.png") and e.position.y==260.0)
	await shot("hunter-overview")
	lab.player.position=Vector2(e.position.x-230,520)
	lab.player.facing=1.0
	check("pounce starts",e.begin_attack("hunter_pounce"))
	await tick(35)
	var locked: Vector2=e.target_point
	key(KEY_A,true)
	await tick(24)
	key(KEY_A,false)
	await tick(23)
	check("late actual movement cannot redirect committed landing",e.target_point==locked)
	check("moving away avoids pounce",lab.player.health==5)
	check("actual floor opens full recovery",e.is_on_floor() and e.state=="recover" and e.timer<0.6)
	await shot("hunter-pounce-missed")
	await tap(KEY_D)
	key(KEY_J,true)
	await tick(15)
	key(KEY_J,false)
	check("real J punishes grounded pounce",e.health<e.maximum and e.reactions.received>0)
	await shot("hunter-counter")
	await tick(220)
	check("hurt recovery returns to visible perch",e.state=="idle" and absf(e.position.y-260.0)<0.1)
	await shot("hunter-returned")
	lab.reset_round()
	await tick(14)
	e=lab.enemies[0] as EnemyLabPredator
	lab.player.position=Vector2(500,520)
	lab.player.facing=1.0
	key(KEY_I,true)
	await tick(11)
	e.begin_attack("hunter_pounce")
	await tick(90)
	check("held front I blocks normal pounce",e.parry_count==1 and lab.player.health==5)
	key(KEY_I,false)
	lab.reset_round()
	await tick(14)
	e=lab.enemies[0] as EnemyLabPredator
	lab.player.position=Vector2(e.position.x,520)
	key(KEY_I,true)
	await tick(11)
	e.begin_attack("hunter_drop")
	await tick(45)
	check("heavy drop warns on body only",float((e.visual.material as ShaderMaterial).get_shader_parameter("danger"))>0.0)
	await shot("hunter-red-windup")
	await tick(55)
	check("heavy drop defeats held guard",lab.player.health==4)
	check("red warning ends with release",float((e.visual.material as ShaderMaterial).get_shader_parameter("danger"))==0.0)
	await shot("hunter-drop-landed")
	key(KEY_I,false)
	lab.reset_round()
	await tick(14)
	e=lab.enemies[0] as EnemyLabPredator
	e.begin_attack("hunter_glide")
	await tick(65)
	check("glide is overhead and leaves ground safe",e.position.y<300 and lab.player.health==5)
	await shot("hunter-glide")
	await tick(50)
	check("glide landing provides ground response",e.state=="recover" and e.is_on_floor())
	lab.auto_attack=true
	lab.reset_round()
	await tick(14)
	e=lab.enemies[0] as EnemyLabPredator
	key(KEY_A,true)
	await tick(65)
	key(KEY_A,false)
	await tick(240)
	check("actual movement reaches covered area",e.sheltered_player())
	check("cover avoids forced pounce damage",lab.player.health==5)
	var serial: int=e.attack_serial
	await tick(120)
	check("cover prevents endless reengagement",e.attack_serial==serial and e.state=="idle")
	await shot("hunter-covered")
	var old: EnemyLabEnemy=e
	await tap(KEY_R)
	await tick(12)
	check("R clears old flight and returns full fresh round",not is_instance_valid(old) and lab.player.health==5)
	print("ENEMY_LAB_PREDATOR failures=",failures)
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)
