extends "res://tests/enemy_lab_eel_qa.gd"
## 按用户截图将玩家放在身体中段，持续原地J；不注入伤害或无敌。
func run() -> void:
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=4
	lab.auto_attack=true
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	e.position=Vector2(800,520)
	lab.player.position=Vector2(800,520)
	lab.player.facing=1.0
	for i: int in 24:
		key(KEY_J,true)
		await tick(6)
		key(KEY_J,false)
		await tick(14)
		print("CENTER round=",i," hp=",lab.player.health," enemy=",e.health," ",e.move_key,"/",e.state," player=",lab.player.position," body=",e.position)
		if lab.player.health<5 or e.health<=0: break
	check("stationary actual J in middle cannot kill eel without response",lab.player.health<5 and e.health>0)
	check("actual central hits trigger early visible burrow",e.center_repositions>0)
	await shot("eel-nest-center-response")
	print("ENEMY_LAB_CENTER failures=",failures)
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)
