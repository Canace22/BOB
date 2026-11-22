extends TestSuite
## 通过实际敌人状态推进取证，不能手工摆一个生产中不存在的move_key来证明接入。

func fixture(profile: int) -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=profile
	lab.auto_attack=false
	lab.invincible=true
	add(lab)
	await physics_frames(14)
	return lab

func test_predator_escape_and_return_keep_runtime_action_and_use_authored_swim() -> void:
	var lab:=await fixture(3)
	var enemy: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	check(enemy.begin_attack("hunter_pounce"),"真实扑击开始")
	# 受压事件刺激进入真实喷水脱身状态，不伪造hunter_escape招式ID。
	enemy._prepare_escape()
	var seen: Dictionary={}
	for frame: int in 240:
		await physics_frames(1)
		if enemy.state=="return":
			eq(enemy.move_key,"hunter_pounce","脱身不改变玩法招式ID")
			check(enemy.visual.texture.resource_path.ends_with("membrane_hunter--hunter_return.png"),"回挂使用新游动身体")
			seen[enemy.visual.region_rect]=true
		elif not seen.is_empty() and enemy.state=="idle": break
	check(seen.size()>=4,"回挂真正播放多张游动绘图")

func test_elder_replant_after_third_real_attack_uses_new_body() -> void:
	var lab:=await fixture(7)
	var enemy: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	var seen: Dictionary={}
	for attempt: int in 3:
		# 贯刺真实前移，第三次收招后才有返程距离；原地扫闸在家位会立即结束回稳。
		check(enemy.begin_attack("elder_thrust"),"真实贯刺前移后回稳")
		for frame: int in 240:
			await physics_frames(1)
			if enemy.state=="reground":
				check(enemy.visual.texture.resource_path.ends_with("elder_guardian--elder_reground.png"),"非撑跃招式也能进入新回稳身体")
				seen[enemy.visual.region_rect]=true
			if enemy.state=="idle": break
	check(seen.size()>=4,"实际第三招后的回稳播放连续绘图")

func test_replant_after_copy_does_not_override_copy_execution() -> void:
	var view:=EnemyLabAnimationOverride.new()
	check(not view.sample("elder_guardian","elder_mimic","reground",1,0.5).is_empty(),"复制结束后的独立回稳也能读取新绘图")
	eq(view.sample("elder_guardian","elder_mimic","active",1,0.5),{},"复制释放与幻影仍归原执行器")

func test_readable_crab_preparations_use_revised_atlases() -> void:
	var lab:=await fixture(1)
	for item: Array in [[1,"press","mudback--press.png"],[2,"shell_push","shell_guard--shell_push.png"]]:
		# 同一时间只保留一个InputMap所有者，换敌人用原场地重置入口。
		lab.profile_index=int(item[0])
		lab.reset_round()
		await physics_frames(14)
		var enemy: EnemyLabEnemy=lab.enemies[0]
		check(enemy.begin_attack(str(item[1])),"实际开始强化前摇招式")
		await physics_frames(2)
		check(enemy.visual.texture.resource_path.ends_with(str(item[2])),"真实前摇读取重绘图集")
