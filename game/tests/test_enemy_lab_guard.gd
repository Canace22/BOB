extends TestSuite
## 持续防御与反击收益必须经过实际按键、玩家伤害接口和敌人结算。
func fixture(index: int=0) -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=index
	lab.auto_attack=false
	add(lab)
	await physics_frames(12)
	lab.enemies[0].set_physics_process(false)
	lab.player.position=lab.enemies[0].position-Vector2(80,0)
	lab.player.facing=1.0
	return lab
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func after_each() -> void:
	key(KEY_I,false)
	key(KEY_J,false)
	await super.after_each()

func test_hold_guard_stays_active_but_does_not_extend_perfect_reward() -> void:
	var lab := await fixture(1)
	key(KEY_I,true)
	await physics_frames(80)
	var guard: EnemyLabSkills=lab.player.skill_controller as EnemyLabSkills
	check(guard.guard_open(),"holding I longer than one second still blocks")
	var e: EnemyLabEnemy=lab.enemies[0]
	check(e.begin_attack("press"),"heavy attack starts")
	e.set_state("active")
	e.strike()
	eq(lab.player.health,5,"early held guard prevents real heavy hit")
	check(not guard.perfect and guard.counter_bonus==1,"held guard earns ordinary reward only")
	eq(e.state,"recover","ordinary block exposes heavy enemy")
	key(KEY_I,false)
	await physics_frames(25)
	check(not guard.active,"releasing I exits held guard")

func test_perfect_guard_allows_immediate_attack_and_one_bonus_hit() -> void:
	var lab := await fixture()
	var e: EnemyLabEnemy=lab.enemies[0]
	key(KEY_I,true)
	await physics_frames(11)
	check(e.begin_attack("double"),"double begins")
	e.set_state("active")
	e.strike()
	var guard: EnemyLabSkills=lab.player.skill_controller as EnemyLabSkills
	check(guard.perfect and guard.counter_bonus==2,"timed guard earns enhanced counter")
	check(e.followup_cancelled,"double second hit cancelled")
	key(KEY_I,false)
	check(lab.player.request_action("strike_01"),"attack cancels successful guard immediately")
	await physics_frames(15)
	eq(e.health,1,"real basic hit adds counter bonus and exposed-food reward")
	eq(guard.counter_bonus,0,"bonus consumed once")

func test_guard_does_not_protect_back_and_counter_expires_while_idle() -> void:
	var lab := await fixture()
	key(KEY_I,true)
	await physics_frames(11)
	var guard: EnemyLabSkills=lab.player.skill_controller as EnemyLabSkills
	check(lab.player.take_damage(1,lab.player.position-Vector2(80,0)),"rear attack passes through front guard")
	guard.counter_bonus=2
	guard.counter_left=0.1
	guard.cancel()
	key(KEY_I,false)
	await physics_frames(24)
	eq(guard.consume_counter(),0,"idle time cannot preserve reward indefinitely")

func test_three_silhouettes_and_nine_action_regions_are_independent() -> void:
	var textures: Dictionary={}
	var lab := await fixture()
	for index: int in 3:
		lab.profile_index=index
		lab.reset_round()
		await physics_frames(12)
		lab.enemies[0].set_physics_process(false)
		var e: EnemyLabEnemy=lab.enemies[0]
		e.visual.present(e)
		textures[e.visual.texture.resource_path]=true
		var poses: Dictionary={}
		for move: String in e.profile.moves:
			e.move_key=move
			e.spec=EnemyLabCatalog.action(move)
			e.state="active"
			e.visual.present(e)
			poses[e.visual.pose_id]=true
			check(e.visual.region_rect.size.x>0,"authored frame has valid source region")
		eq(poses.size(),3,"each move selects a distinct action row")
	eq(textures.size(),3,"three profiles use different silhouette textures")

func test_perfect_guard_can_cancel_directly_into_sword_skill() -> void:
	var lab := await fixture(2)
	key(KEY_I,true)
	await physics_frames(11)
	var e: EnemyLabEnemy=lab.enemies[0]
	check(e.begin_attack("poke"),"guard enemy begins poke")
	e.set_state("active")
	e.strike()
	key(KEY_I,false)
	check(lab.player.request_action("wb_draw"),"success cancels into actual sword skill")
	eq(lab.player.skill_controller.visual_key,"wb_draw","new skill owns animation and timing")

func test_holding_guard_depletes_stance_and_cannot_recover_until_release() -> void:
	var lab := await fixture()
	key(KEY_I,true)
	await physics_frames(420)
	var guard: EnemyLabSkills=lab.player.skill_controller as EnemyLabSkills
	check(not guard.guard_open() and guard.guard_meter<=0.1,"holding alone eventually breaks guard")
	check(not lab.player.request_action("parry"),"empty stance cannot restart defense")
	check(lab.player.take_damage(1,lab.player.position+Vector2(80,0)),"front hit after depletion causes damage")
	key(KEY_I,false)
	await physics_frames(150)
	check(guard.guard_meter>25.0,"released guard recovers stance")
	check(lab.player.request_action("parry"),"recovered stance can defend again")

func test_repeated_heavy_blocks_break_stance_and_the_breaking_hit_hurts() -> void:
	var lab := await fixture(1)
	key(KEY_I,true)
	await physics_frames(80)
	var e: EnemyLabEnemy=lab.enemies[0]
	var guard: EnemyLabSkills=lab.player.skill_controller as EnemyLabSkills
	for i: int in 2:
		e.set_state("idle")
		check(e.begin_attack("press"),"heavy press begins")
		e.set_state("active")
		e.strike()
	eq(lab.player.health,4,"second heavy hit breaks stance and deals actual damage")
	check(guard.guard_lock>0.0 and guard.counter_bonus==0,"guard break locks defense and clears counter reward")

func test_perfect_guard_preserves_stance_but_flip_ignores_guard() -> void:
	var lab := await fixture(1)
	var guard: EnemyLabSkills=lab.player.skill_controller as EnemyLabSkills
	guard.guard_meter=50.0
	key(KEY_I,true)
	await physics_frames(11)
	var e: EnemyLabEnemy=lab.enemies[0]
	check(e.begin_attack("press"),"press begins")
	e.set_state("active")
	e.strike()
	check(guard.perfect and guard.guard_meter>50.0,"perfect timing refills instead of consuming stance")
	e.set_state("idle")
	check(e.begin_attack("flip"),"unblockable flip begins")
	e.set_state("active")
	e.strike()
	eq(lab.player.health,4,"red flip hits even a freshly perfect guard")
	check(not guard.incoming_unblockable,"incoming flags cleared after damage dispatch")

func test_attack_effects_are_pooled_and_reset_with_round() -> void:
	var lab := await fixture(1)
	var e: EnemyLabEnemy=lab.enemies[0]
	e.begin_attack("flip")
	e.set_state("active")
	eq(e.effects.bursts,1,"actual active transition emits a visual burst")
	eq(e.effects.particles.size(),24,"attack effects use a bounded pool")
	var shown: int=0
	for item: Dictionary in e.effects.particles:
		if (item.sprite as Sprite2D).visible: shown+=1
	check(shown>0,"authored textures are actually presented")
	var old: EnemyLabAttackEffects=e.effects
	lab.reset_round()
	await physics_frames(6)
	check(not is_instance_valid(old),"round reset releases effect owner and pool")

func test_unblockable_body_glow_only_exists_during_windup() -> void:
	var lab := await fixture(1)
	var e: EnemyLabEnemy=lab.enemies[0]
	check(e.begin_attack("flip"),"unblockable windup starts")
	var mat: ShaderMaterial=e.visual.material as ShaderMaterial
	check(float(mat.get_shader_parameter("danger"))>0.0,"body glows immediately in windup")
	e.set_state("active")
	eq(float(mat.get_shader_parameter("danger")),0.0,"release removes body warning immediately")
	e.set_state("idle")
	e.begin_attack("press")
	eq(float(mat.get_shader_parameter("danger")),0.0,"ordinary windup has no warning glow")
	e.set_state("idle")
	e.begin_attack("flip")
	e.set_state("hurt")
	eq(float(mat.get_shader_parameter("danger")),0.0,"interruption clears warning")
