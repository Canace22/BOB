extends TestSuite
## 通过真实技能执行器释放后观招，不以手工发信号冒充释放。
func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=7
	lab.auto_attack=false
	add(lab)
	await physics_frames(14)
	return lab

func learn(lab: EnemyLab, key: String) -> EnemyLabElder:
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	check(lab.player.request_action(key),"player accepts actual source skill "+key)
	for frame: int in 65:
		await physics_frames(1)
		if not e.mimic.memory.is_empty(): break
	return e

func test_unreleased_canceled_and_utility_actions_are_not_learned() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	check(lab.player.request_action("wb_draw"),"start source heavy")
	await physics_frames(2)
	check(e.mimic.memory.is_empty(),"startup is not release")
	check(lab.player.try_backstep(),"cancel before source release")
	await physics_frames(30)
	check(not e.mimic.repertoire.learned.has("wb_draw") and e.mimic.repertoire.learned.has("backstep"),"canceled attack not copied, real backstep learned")
	check(lab.player.request_action("scan"),"actual utility scan accepted")
	await physics_frames(36)
	check(e.mimic.repertoire.learned.has("scan") and e.begin_attack("elder_mimic"),"actual utility scan is copied too")

func test_core_variants_use_actual_source_snapshots_without_mutation() -> void:
	var lab := await fixture()
	for key: String in ["wb_rise","wb_drive","wb_draw","wb_charge","wb_flurry","cyclone"]:
		lab.reset_round()
		await physics_frames(14)
		var e: EnemyLabElder=await learn(lab,key)
		check(not e.mimic.memory.is_empty(),"release observed "+key)
		if e.mimic.memory.is_empty(): continue
		eq(str(e.mimic.memory.key),key,"correct source key")
		check(e.begin_attack("elder_mimic"),"copy begins from real learned skill")
		check(e.state=="tell" and e.phase_duration()==0.70 and e.mimic.memory.is_empty(),"full tell consumes one observation")
		eq(str(e.mimic.source_key),key,"active snapshot fixed")
		check(not e.mimic.ready_to_cast(),"cooldown and new observation needed")
		if TideCombatSkills.DEFINITIONS.has(key): eq(e.mimic.copied.reach,TideCombatSkills.DEFINITIONS[key].reach,"source reach reused")
		if key=="wb_rise":
			lab.player.position=e.position-Vector2(95,0)
			for frame: int in 100:
				await physics_frames(1)
				if e.hit_count>0: break
			await physics_frames(3)
			check(lab.player.health==4 and lab.player.position.y<500,"copied uppercut launches only after real damage")

func test_three_observed_steps_replay_three_pulses_and_distinct_motion() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	for step: int in 3:
		check(lab.player.request_action("wb_drive"),"actual chained step")
		await physics_frames(13)
	check(not e.mimic.memory.is_empty() and e.mimic.memory.steps==3,"actual third release records three steps")
	e.begin_attack("elder_mimic")
	eq(e.mimic.times.size(),3,"three original cadence releases")
	eq(e.mimic.times[1],0.30,"second step release timing")
	var previous: float=e.position.x
	await physics_frames(67)
	check(e.mimic.emitted>=1 and e.position.x<previous-10,"copied step physically moves body")

func test_new_observation_cannot_replace_cast_in_progress() -> void:
	var lab := await fixture()
	var e := await learn(lab,"wb_draw")
	e.begin_attack("elder_mimic")
	check(lab.player.request_action("wb_rise"),"new source can release while enemy prepares")
	await physics_frames(12)
	check(e.mimic.source_key=="wb_draw" and str(e.mimic.memory.get("key",""))=="wb_rise","pending and casting are independent")
	eq(e.mimic.copied.damage,3,"copy never mutates source damage definition")

func test_rear_or_heavy_hit_interrupts_preparation_with_finite_opening() -> void:
	var lab := await fixture()
	var e := await learn(lab,"wb_draw")
	e.begin_attack("elder_mimic")
	lab.player.position=e.position+Vector2(90,0)
	e.take_hit(1)
	check(e.mimic.interrupted==1 and e.state=="recover" and e.opening_left==1.35,"real rear hit cancels copy")
	check(not e.mimic.view.effect.visible and not e.mimic.view.memory_pose.visible,"interruption clears echo feedback")
	await physics_frames(90)
	eq(e.mimic.casts,0,"canceled preparation never releases later")

func test_distance_and_actual_wall_occlusion_prevent_observation() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	lab.player.position.x=100
	lab.player.request_action("wb_rise")
	await physics_frames(16)
	check(e.mimic.memory.is_empty(),"outside observation range")
	lab.reset_round()
	await physics_frames(14)
	e=lab.enemies[0] as EnemyLabElder
	lab._make_body(Rect2(600,350,20,170))
	await physics_frames(2)
	lab.player.request_action("wb_draw")
	await physics_frames(25)
	check(e.mimic.memory.is_empty(),"actual solid wall blocks sight")

func test_projectile_is_owned_and_surrender_clears_pending_cast() -> void:
	var lab := await fixture()
	var e := await learn(lab,"A4_parry")
	await physics_frames(85)
	check(e.begin_attack("elder_mimic"),"learned projectile replay")
	for frame: int in 95:
		await physics_frames(1)
		if not e.mimic.orb_refs.is_empty(): break
	check(not e.mimic.orb_refs.is_empty(),"real hostile projectile spawned")
	e.take_hit(100)
	await physics_frames(3)
	check(e.outcome=="surrender" and e.mimic.orb_refs.is_empty(),"surrender clears owned projectile")
	lab.reset_round()
	await physics_frames(14)
	check(not is_instance_valid(e) and (lab.enemies[0] as EnemyLabElder).mimic.memory.is_empty(),"R clears observer and memory")

func test_upward_spell_and_real_dive_landing_keep_their_geometry() -> void:
	var lab := await fixture()
	var e := await learn(lab,"up_spell")
	e.begin_attack("elder_mimic")
	check(e.mimic.times.size()==1 and e.mimic.area().size==Vector2(140,165),"source upward shape and release")
	lab.reset_round()
	await physics_frames(14)
	e=lab.enemies[0] as EnemyLabElder
	lab.player.position.y-=120
	await physics_frames(2)
	check(lab.player.request_action("dive"),"actual air-only source action accepted")
	await physics_frames(5)
	check(e.mimic.memory.is_empty(),"fall startup is not a landing release")
	for frame: int in 65:
		await physics_frames(1)
		if not e.mimic.memory.is_empty(): break
	check(not e.mimic.memory.is_empty() and e.mimic.memory.data.motion=="dive","actual landing observed")
	e.begin_attack("elder_mimic")
	for frame: int in 80:
		await physics_frames(1)
		if e.state=="active" and e.position.y<e.home.y-25: break
	check(e.position.y<e.home.y-25 and e.mimic.emitted==0,"copied dive really rises before floor impact")
	for frame: int in 80:
		await physics_frames(1)
		if e.mimic.emitted>0: break
	check(e.is_on_floor() and e.mimic.emitted==1,"copied radial impact only at actual landing")
