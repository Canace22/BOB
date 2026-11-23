extends TestSuite
## 真实观招/复制链验证新本体与只读phase消费，不以手工发释放信号代替执行。

func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=7
	lab.auto_attack=false
	lab.all_skill_practice=true
	add(lab)
	await physics_frames(14)
	return lab

func test_actual_copy_uses_shared_new_body_phase_without_moving_combat_time() -> void:
	var lab := await fixture()
	for item: Array in [["strike1","strike1",0.10],["wb_rise","upper",0.07],["heavy","heavy",0.25]]:
		lab.reset_round()
		await physics_frames(14)
		var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
		var source: String=str(item[0])
		var clip: String=str(item[1])
		var release: float=float(item[2])
		var observed: Array[float]=[]
		lab.player.animation_tag.connect(func(tag: String) -> void:
			if tag==source+":release": observed.append(lab.player.state_time))
		check(lab.player.request_action(source),"actual source starts "+source)
		for i: int in 80:
			await physics_frames(1)
			if e.mimic.repertoire.learned.has(source): break
		check(not observed.is_empty() and observed[0]>=release-0.00001,"learning follows actual source release "+source)
		check(e.mimic.repertoire.learned.has(source),"real source learned "+source)
		if not e.mimic.repertoire.learned.has(source): continue
		lab.player.position=e.position-Vector2(90,0)
		var hit_times: Array[float]=[]
		lab.player.damaged.connect(func() -> void:
			if e.state=="active" and e.move_key=="elder_mimic": hit_times.append(e.timer))
		check(e.begin_attack("elder_mimic"),"actual learned copy begins "+source)
		check(is_equal_approx(float(e.mimic.copied.release),release),"copy keeps release snapshot "+source)
		var schedule: Array[float]=e.mimic.times.duplicate()
		var snapshot: Dictionary=e.mimic.copied.duplicate(true)
		var saw_preparation: bool=false
		for i: int in 100:
			await physics_frames(1)
			if e.state=="active" and e.mimic.view.action_echo.visible:
				var echo: EnemyLabElderEchoView=e.mimic.view
				eq(echo.body_key,clip,"original source mapping preserved")
				var texture: AtlasTexture=echo.action_echo.texture as AtlasTexture
				check(texture!=null and texture.atlas.resource_path.contains(("player-basic-slash-v3/" if clip=="strike1" else "combat-animation-v2/player/")+clip+"-body.png"),"ghost consumes new shared texture "+clip)
				eq(echo.action_echo.offset,Vector2(-192,-340) if clip=="strike1" else Vector2(-128,-224),"authored pivot is not overwritten by old foot metadata")
				if e.timer<release:
					saw_preparation=true
					check(echo.body_frame<6 and not echo.effect.visible,"copy preparation has no cut body or attack FX")
				var time_before: float=e.timer
				var emitted_before: int=e.mimic.emitted
				var clock_before: float=lab.player.action_visual.phase_map.clock
				echo._physics_process(0.0)
				check(e.timer==time_before and e.mimic.emitted==emitted_before,"ghost reads without advancing copied combat")
				check(lab.player.action_visual.phase_map.clock==clock_before,"ghost does not advance player's presentation clock")
			if not hit_times.is_empty(): break
		check(saw_preparation,"new preparation frames actually selected "+clip)
		check(not hit_times.is_empty() and hit_times[0]>=release-0.00001,"real copied damage waits for original release "+source)
		eq(e.mimic.times,schedule,"copy pulse schedule unchanged")
		eq(e.mimic.copied,snapshot,"copy data remains unchanged")
