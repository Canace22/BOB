extends TestSuite
## 显式全技能练习夹具；实际执行/释放每个能力，原默认权限另测。
func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=7
	lab.auto_attack=false
	lab.all_skill_practice=true
	add(lab)
	await physics_frames(14)
	return lab

func perform(lab: EnemyLab, key: String) -> String:
	var p: EnemyLabPlayer=lab.player
	if key in ["dive","dark_dive","A3_anchor"]:
		p.position.y-=140
		await physics_frames(2)
	if key=="recover": p.health=4
	if key in ["wb_backcut","backstep"]:
		check(p.try_backstep(),"actual backstep starts")
	if key!="backstep": check(p.request_action(key),"actual execution accepts "+key)
	var expected: String={"A4_parry":"orb","strike_01":"strike1"}.get(key,key)
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	for frame: int in 180:
		await physics_frames(1)
		if e.mimic.repertoire.learned.has(expected): return expected
	check(false,"actual release observed for "+key)
	return expected

func test_all_controller_skills_and_legacy_combat_actions_have_real_replay() -> void:
	var lab := await fixture()
	var keys: Array[String]=[]
	for key: String in TideCombatSkills.DEFINITIONS: keys.append(key)
	for key: String in TideSkillCatalog.ACTIONS:
		if key!="tram": keys.append(key)
	keys.append_array(["strike_01","A3_anchor","A4_parry","heavy","A1_dash","A5_slit","recover","backstep"])
	for key: String in keys:
		lab.reset_round()
		await physics_frames(14)
		var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
		var expected: String=await perform(lab,key)
		if not e.mimic.repertoire.learned.has(expected): continue
		if key=="recover": e.health=18
		check(e.begin_attack("elder_mimic"),"replay starts "+key)
		check(e.mimic.source_key==expected and e.mimic.copied.size()>0,"matching behavior snapshot "+key)
		for frame: int in 200:
			await physics_frames(1)
			if e.mimic.emitted>0: break
		check(e.mimic.casts==1 and e.mimic.emitted>0,"actual replay release "+key)
		await physics_frames(2)
		check(e.mimic.view.action_echo.visible and e.mimic.view.action_echo.texture!=null,"source body animation present "+key)
		eq(float((e.visual.material as ShaderMaterial).get_shader_parameter("danger")),0.0,"copied ability stays blockable/readable "+key)

func test_persistent_repertoire_selects_range_and_reuses_learned_skills() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	await perform(lab,"wb_draw")
	await physics_frames(40)
	await perform(lab,"A4_parry")
	await physics_frames(40)
	e.mimic.memory.clear()
	lab.player.position.x=400
	eq(str(e.mimic.repertoire.choose().key),"orb","range chooses learned projectile")
	check(e.begin_attack("elder_mimic"),"known ranged ability replays without relearning")
	await physics_frames(120)
	e.set_state("idle")
	e.mimic.cooldown=0.0
	lab.player.position.x=e.position.x-80
	eq(str(e.mimic.repertoire.choose().key),"wb_draw","close pressure chooses different known attack")
	check(e.mimic.repertoire.learned.size()==2,"observed skills persist rather than consumed forever")

func test_copied_guard_blocks_but_heavy_breaks_and_heal_budget_is_finite() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	await perform(lab,"parry")
	e.begin_attack("elder_mimic")
	for frame: int in 70:
		await physics_frames(1)
		if e.state=="active" and e.timer>0.06: break
	lab.player.position=e.position-Vector2(90,0)
	e.take_hit(1)
	check(e.health==24 and e.mimic.repertoire.shields==1 and e.state=="recover","copied shield is real frontal defense")
	await physics_frames(40)
	e.set_state("idle")
	e.mimic.cooldown=0.0
	e.begin_attack("elder_mimic")
	for frame: int in 80:
		await physics_frames(1)
		if e.state=="active" and e.timer>0.06: break
	e.take_hit(3)
	check(e.health==21 and e.control_window_open() and e.opening_left==1.10,"heavy breaks copied guard without ignoring damage")
	lab.reset_round()
	await physics_frames(14)
	e=lab.enemies[0] as EnemyLabElder
	await perform(lab,"recover")
	e.health=12
	for count: int in 3:
		e.set_state("idle")
		e.mimic.cooldown=0.0
		check(e.begin_attack("elder_mimic"),"healing observation replay")
		await physics_frames(80)
		if count==1: break
	check(e.health==16 and e.mimic.repertoire.healing==4 and e.mimic.repertoire.heal_budget==0,"healing copied but cannot regenerate forever")
	e.mimic.cooldown=0.0
	check(not e.mimic.ready_to_cast(),"spent heal is omitted from valid repertoire")

func test_aggression_has_fast_engagement_short_reset_and_bounded_chain() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	e.auto_attack=true
	lab.player.position=e.position-Vector2(100,0)
	await physics_frames(15)
	check(e.attack_serial>0,"near target engaged within quarter second")
	e.begin_attack("elder_sweep")
	e.move_key="elder_sweep"
	e.spec=EnemyLabCatalog.action("elder_sweep")
	e.set_state("active")
	e.hit_sent=true
	e.advance_action(0.25)
	check(e.spec.recover==0.32 and e.pressure_chain==1,"contact creates one short continuation")
	e.set_state("active")
	e.hit_sent=true
	e.advance_action(0.25)
	check(e.pressure_chain==0,"no endless short recovery chain")
	e.guard_reaction(true)
	check(e.opening_left==1.55,"perfect guard still earns full punish")

func test_all_skill_practice_is_explicit_and_does_not_change_default_lock() -> void:
	var lab := await fixture()
	check(lab.player.skill_unlocked("chapter"),"explicit local practice unlocks upgraded source skills")
	lab.all_skill_practice=false
	lab.reset_round()
	await physics_frames(14)
	check(not lab.player.skill_unlocked("chapter"),"default player rules restored in new round")

func test_echo_animates_full_combo_on_real_origin_and_clears_on_end() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	await perform(lab,"wb_flurry")
	e.begin_attack("elder_mimic")
	var textures: Dictionary={}
	var clips: Dictionary={}
	for frame: int in 115:
		await physics_frames(1)
		var view: EnemyLabElderEchoView=e.mimic.view
		if not view.action_echo.visible: continue
		textures[view.action_echo.texture]=true
		clips[view.body_key]=true
		check(view.action_echo.global_position.is_equal_approx(e.global_position),"ghost shares actual attack and movement origin")
		var spec: Dictionary=lab.player.action_visual.manifest[view.body_key]
		if bool(spec.get("authored_pivot",false)):
			eq(view.action_echo.offset,-Vector2(float(spec.body.pivot[0]),float(spec.body.pivot[1])),"new ghost consumes its authored pivot")
		else:
			var bottoms: Array=lab.player.action_visual.foot_metadata.get(view.body_key,{}).get("bottom",[])
			if e.is_on_floor() and not bottoms.is_empty():
				check(view.body_frame<bottoms.size(),"legacy ghost frame has matching foot metadata")
				if view.body_frame<bottoms.size(): eq(view.action_echo.offset.y,-float(bottoms[view.body_frame]),"legacy ghost reuses original foot metadata")
	check(textures.size()>5 and clips.size()>=3,"flurry plays changing body frames and multiple source actions")
	e.finish()
	await physics_frames(2)
	check(not e.mimic.view.action_echo.visible and e.visual.modulate.a==1.0,"ending removes phantom and restores caster")
