extends TestSuite
## 捕食者的真实物理落地、受控与回挂；站位夹具不代替自然AI验收。
func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=3
	lab.terrain=2
	lab.auto_attack=false
	add(lab)
	await physics_frames(12)
	return lab
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func after_each() -> void:
	tree.paused=false
	for code: Key in [KEY_I,KEY_J,KEY_A,KEY_D,KEY_S,KEY_L,KEY_SPACE]: key(code,false)
	await super.after_each()

func test_pounce_locks_target_and_lands_before_counter_window() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	check(e.position.y==260.0 and e.state=="idle","starts at visible perch")
	check(e.begin_attack("hunter_pounce"),"airborne idle can start pounce")
	await physics_frames(37)
	var point: Vector2=e.target_point
	lab.player.position.x=610
	await physics_frames(45)
	eq(e.target_point,point,"late movement cannot redirect pounce")
	check(e.is_on_floor() and e.state=="recover","actual landing opens counter window")
	check(e.timer<float(e.spec.recover),"landing leaves a usable recovery duration")

func test_recovery_returns_without_teleport_or_new_damage() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	e.begin_attack("hunter_pounce")
	lab.player.position.x=610
	var saw_return: bool=false
	for i: int in 250:
		var before: Vector2=e.position
		var returning: bool=e.state=="return"
		var prior_hits: int=e.hit_count
		await physics_frames(1)
		if returning:
			saw_return=true
			eq(e.hit_count,prior_hits,"return route never performs an attack")
			check(e.position.distance_to(before)<12.0,"return moves through physical space")
	check(saw_return and e.state=="idle" and absf(e.position.y-260.0)<0.1,"complete cycle regrips perch")

func test_cover_cancels_early_commit_and_blocks_new_attacks() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	e.begin_attack("hunter_pounce")
	lab.player.position=Vector2(160,520)
	await physics_frames(25)
	check(e.state!="active","early retreat abandons uncommitted dive")
	e.auto_attack=true
	await physics_frames(200)
	eq(e.attack_serial,1,"cover does not allow repeated invisible attacks")
	eq(lab.player.health,5,"cover retreat avoids damage")

func test_glide_recovery_is_not_spent_while_falling() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	e.begin_attack("hunter_glide")
	await physics_frames(78)
	check(e.state=="recover" and not e.is_on_floor(),"glide enters a real fall")
	check(is_zero_approx(e.timer),"recovery does not tick before floor contact")
	await physics_frames(28)
	check(e.state=="recover" and e.is_on_floor(),"counter window remains after contact")

func test_pounce_guard_and_ground_launch_use_shared_protocol() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	lab.player.position=Vector2(500,520)
	lab.player.facing=1.0
	key(KEY_I,true)
	await physics_frames(11)
	e.begin_attack("hunter_pounce")
	await physics_frames(90)
	key(KEY_I,false)
	check(e.parry_count==1 and lab.player.health==5,"front held guard blocks real pounce")
	check(e.state=="recover","guard leaves grounded retaliation opportunity")
	e.launch(510.0)
	check(e.state=="hurt" and e.velocity.y<0.0,"landing window allows light-body launch")

func test_drop_red_warning_and_unblockable_contact() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	lab.player.position=Vector2(e.position.x,520)
	key(KEY_I,true)
	await physics_frames(11)
	e.begin_attack("hunter_drop")
	await physics_frames(40)
	check(float((e.visual.material as ShaderMaterial).get_shader_parameter("danger"))>0.0,"drop body glows in windup")
	await physics_frames(60)
	eq(lab.player.health,4,"vertical contact bypasses guard")
	eq(float((e.visual.material as ShaderMaterial).get_shader_parameter("danger")),0.0,"contact clears warning")

func test_return_interrupt_does_not_resume_old_flight() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	e.spec=EnemyLabCatalog.action("hunter_pounce")
	e.position=Vector2(600,520)
	e.set_state("return")
	await physics_frames(4)
	e.launch(500)
	check(e.state=="hurt","return begins vulnerable to control")
	await physics_frames(12)
	check(e.state=="hurt" and e.velocity.y<0.0,"old return target does not override launch")

func test_dynamic_menu_and_reset_preserve_original_enemy_profiles() -> void:
	var lab := await fixture()
	eq(lab.hud.enemy_menu.item_count,EnemyLabCatalog.PROFILES.size(),"catalog profiles selectable")
	lab.select_terrain(1)
	await physics_frames(6)
	eq(lab.terrain,2,"air enemy cannot start inside low-ceiling collision")
	var old: EnemyLabEnemy=lab.enemies[0]
	old.begin_attack("hunter_pounce")
	lab.reset_round()
	await physics_frames(6)
	check(not is_instance_valid(old),"midair round owner freed")
	eq(lab.enemies[0].attack_serial,0,"reset leaves no queued old dive")
	lab.select_profile(0)
	await physics_frames(8)
	eq(lab.terrain,0,"returning to baseline restores flat stage")
	eq(lab.enemies[0].profile.id,"forager","original ground profile stays intact")

func test_approved_squid_identity_and_hanging_sequence_are_used() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	e.set_physics_process(false)
	e.timer=0.0
	e.visual.present(e)
	check(e.visual.texture.resource_path.contains("enemy-lab-predator-squid-jelly-v1"),"approved identity replaces old insect sheet")
	eq(e.visual.pose_id,0,"first hanging pose")
	var size: Vector2=e.visual.scale.abs()
	e.timer=0.30
	e.visual.present(e)
	eq(e.visual.pose_id,1,"resting creature advances through authored hanging poses")
	eq(e.visual.scale.abs(),size,"changing pose does not resize individual bounds")

