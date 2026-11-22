extends TestSuite
## 固定的原待机解剖标尺，不把武器、举手或蹲姿的外包围盒当身高。

func test_elder_neutral_body_matches_idle_before_loading_weight() -> void:
	var view:=EnemyLabAnimationOverride.new()
	# 独立复核的中性站姿壳顶至脚底，排除更高的叉尖，不使用蓄力蹲姿外框。
	var spans: Dictionary={"elder_sweep":184.0,"elder_thrust":192.0,"elder_grip":200.0,"elder_vault":179.0,"elder_mimic":202.0}
	var idle_span: float=192.0/190.0
	for action: String in spans:
		var sample: Dictionary=view.sample("elder_guardian",action,"tell",1,0.0)
		var span: float=float(spans[action])/float(sample.clip.reference_height)
		check(absf(span/idle_span-1.0)<0.01,"elder full neutral body matches idle within one percent: "+action)

func test_authored_enemy_atlases_keep_idle_anatomical_scale() -> void:
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/enemy_scale_registration.json"))
	var view:=EnemyLabAnimationOverride.new()
	for record: Dictionary in fixture.records:
		view.warmup(str(record.profile))
		var expected: float=1.0/float(record.idle_reference_height)
		var count: int=0
		for clip: Dictionary in view.enemies[record.profile].clips:
			if clip.texture!=record.texture: continue
			count+=1
			var measured: float=float(record.source_units_per_idle)/float(clip.reference_height)
			check(absf(measured/expected-1.0)<=0.012,"neutral anatomy matches idle within 1.2 percent: "+str(record.texture))
		check(count>0,"registered source is actually consumed")
		eq(FileAccess.get_sha256(str(record.texture)),str(record.texture_sha256),"source pixels did not change after landmark review")

func test_beam_phases_use_one_scale_and_keep_physics_origin() -> void:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=6
	lab.auto_attack=false
	add(lab)
	await physics_frames(14)
	var enemy: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	enemy.set_physics_process(false)
	var origin: Vector2=enemy.global_position
	var collision: Rect2=enemy.hurt_rect()
	for action: String in ["beam_press","beam_return","beam_brace","beam_guard","beam_riposte"]:
		enemy.move_key=action
		enemy.spec=enemy.action_spec(action)
		var scale: Vector2=Vector2.ZERO
		for state: String in ["tell","active","recover"]:
			enemy.state=state
			for progress: float in [0.0,0.5,0.95]:
				enemy.timer=enemy.phase_duration()*progress
				enemy.visual.present(enemy)
				if scale==Vector2.ZERO: scale=enemy.visual.scale
				eq(enemy.visual.scale,scale,"whole action uses one scale despite pose changes")
				eq(enemy.global_position,origin,"presentation does not move physics root")
				eq(enemy.hurt_rect(),collision,"presentation does not change collision")

func test_beam_legacy_hurt_pose_is_not_resized_by_foreshortened_hood() -> void:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=6
	lab.auto_attack=false
	add(lab)
	await physics_frames(14)
	var enemy: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	enemy.set_physics_process(false)
	enemy.move_key="beam_press"
	enemy.spec=enemy.action_spec("beam_press")
	for state: String in ["hurt","ended"]:
		enemy.state=state
		enemy.visual.present(enemy)
		eq(enemy.visual.pose_id,15,"existing hurt pose is retained")
		check(is_equal_approx(absf(enemy.visual.scale.x),102.0/200.0),"tilted hood is not mistaken for uniform character shrinkage")
