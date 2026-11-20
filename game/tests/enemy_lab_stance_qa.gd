extends "res://tests/enemy_lab_qa.gd"
## 真实I持续防御受两次推进压破；特效由真实阶段事件驱动。
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	lab=load("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.auto_attack=false
	lab.ranges=false
	lab.profile_index=1
	root.add_child(lab)
	current_scene=lab
	await tick(14)
	var e: EnemyLabEnemy=lab.enemies[0]
	lab.player.position=e.position-Vector2(80,0)
	lab.player.facing=1.0
	key(KEY_I,true)
	await tick(80)
	var guard: EnemyLabSkills=lab.player.skill_controller as EnemyLabSkills
	check("holding I consumes visible stance",guard.guard_open() and guard.guard_meter<90.0)
	check("first heavy press begins",e.begin_attack("press"))
	for i: int in 100:
		if guard.guard_count>0: break
		await tick(1)
	check("first heavy hit blocks but consumes pressure",guard.guard_count==1 and lab.player.health==5 and guard.guard_meter<35.0)
	await shot("stance-low")
	e.set_state("idle")
	check("second heavy press begins",e.begin_attack("press"))
	for i: int in 100:
		if lab.player.health<5: break
		await tick(1)
	check("held I cannot prevent breaking hit damage",lab.player.health==4 and guard.guard_meter<=0.01 and guard.guard_lock>0.0)
	await shot("stance-broken")
	await tick(90)
	check("holding depleted guard does not refill it",guard.guard_meter<=0.01 and not guard.guard_open())
	key(KEY_I,false)
	await tick(150)
	check("release restores stance",guard.guard_meter>25.0)
	lab.reset_round()
	await tick(14)
	e=lab.enemies[0]
	lab.player.position=e.position-Vector2(80,0)
	lab.player.facing=1.0
	key(KEY_I,true)
	await tick(11)
	check("red flip begins",e.begin_attack("flip"))
	await tick(30)
	check("unblockable warning is visible during windup",float((e.visual.material as ShaderMaterial).get_shader_parameter("danger"))>0.0 and bool(e.spec.unblockable))
	await shot("stance-red-warning")
	await tick(28)
	await shot("stance-flip-impact")
	check("red flip damages through held defense",lab.player.health==4)
	key(KEY_I,false)
	lab.reset_round()
	await tick(14)
	e=lab.enemies[0]
	lab.player.position=e.position-Vector2(80,0)
	lab.player.facing=1.0
	check("red flip dodge scenario begins",e.begin_attack("flip"))
	await tick(30)
	key(KEY_S,true)
	key(KEY_L,true)
	await tick(7)
	key(KEY_S,false)
	key(KEY_L,false)
	check("real S+L cancels into backstep",lab.player.retreating)
	await tick(40)
	check("moving out avoids unblockable damage",lab.player.health==5 and lab.player.position.x<e.attack_rect().position.x-14.0)
	var cases: Array[Dictionary]=[{"index":0,"move":"sweep"},{"index":1,"move":"ambush"},{"index":2,"move":"shell_push"}]
	for item: Dictionary in cases:
		lab.profile_index=int(item.index)
		lab.reset_round()
		await tick(14)
		e=lab.enemies[0]
		check("FX attack starts "+str(item.move),e.begin_attack(str(item.move)))
		await tick(int(float(e.spec.tell)*60.0)+6)
		if str(item.move)=="sweep":
			var visible_particles: int=0
			for particle: Dictionary in e.effects.particles:
				if (particle.sprite as Sprite2D).visible: visible_particles+=1
			check("low sweep has no arc effect",visible_particles==0)
		else:
			check("actual phase emits pooled FX "+str(item.move),e.effects.bursts==1)
		await shot("stance-fx-"+str(item.move))
	print("ENEMY_LAB_STANCE failures=",failures)
	# 先释放仍在播音效的场景，再给音频线程归还播放引用的物理帧。
	lab.queue_free()
	lab=null
	await tick(6)
	quit(1 if failures else 0)
