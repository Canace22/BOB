extends TestSuite
## 守卫的两段格挡合同、有限反击和非致死撤离，不修改主线。
func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=5
	lab.auto_attack=false
	lab.terrain=3
	add(lab)
	await physics_frames(14)
	return lab
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func after_each() -> void:
	tree.paused=false
	for code: Key in [KEY_I,KEY_J,KEY_A,KEY_D,KEY_SPACE]: key(code,false)
	await super.after_each()

func test_catalog_loads_sixth_enemy_with_pressure_commands() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	check(e!=null,"stable warden ID selects executor")
	eq(lab.hud.enemy_menu.item_count,EnemyLabCatalog.PROFILES.size(),"catalog drives selectable enemies")
	eq(lab.hud.move_menu.item_count,7,"three self-contained water skills and pole auxiliaries")
	check(e.visual.texture.resource_path.contains("enemy-lab-warden-v1"),"own long-pole sheet")
	eq(e.visual.metadata.pump_warden.regions.size(),16,"sixteen authored poses")

func test_normal_first_guard_keeps_second_tell_and_perfect_cancels_it() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.position=Vector2(800,520)
	lab.player.position=Vector2(675,520)
	lab.player.facing=1.0
	key(KEY_I,true)
	await physics_frames(25)
	e.begin_attack("warden_double")
	await physics_frames(59)
	check(e.parry_count==1 and e.pulse==2 and e.state=="tell","ordinary first block does not erase second preparation")
	check(not e.followup_cancelled,"continuation is real rather than restored after a fake interruption")
	key(KEY_I,false)
	lab.reset_round()
	await physics_frames(14)
	e=lab.enemies[0] as EnemyLabWarden
	e.position=Vector2(800,520)
	lab.player.position=Vector2(675,520)
	lab.player.facing=1.0
	e.begin_attack("warden_double")
	await physics_frames(32)
	key(KEY_I,true)
	await physics_frames(18)
	check(e.parry_count==1 and e.state=="recover" and e.followup_cancelled,"timed perfect block cancels followup at source")

func test_large_first_miss_abandons_meaningless_second_stab() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	lab.player.position=Vector2(e.position.x-130,520)
	e.begin_attack("warden_double")
	await physics_frames(32)
	lab.player.position.x=100
	await physics_frames(20)
	check(e.state=="recover" and e.followup_cancelled and e.pulse==1,"far miss opens recovery without stabbing empty space twice")
	eq(lab.player.health,5,"late retreat avoids committed strike")

func test_committed_thrust_takes_damage_but_cannot_be_permanently_interrupted() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.begin_attack("warden_thrust")
	e.take_hit(1)
	e.launch(500)
	check(e.state=="tell" and e.control_left==0.0,"ordinary hit does not cancel committed attack")
	eq(e.health,17,"commitment has no damage immunity")
	e.set_state("recover")
	for i: int in 7:
		e.take_hit(1)
		await physics_frames(10)
	check(e.state=="idle" and e.health>0,"recovery budget cannot be refreshed forever")

func test_pole_push_is_no_red_and_consumes_more_guard_than_stab() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.begin_attack("warden_push")
	eq(float((e.visual.material as ShaderMaterial).get_shader_parameter("danger")),0.0,"no red attack added to this enemy")
	check(float(e.spec.guard_pressure)>28.0,"crossbar pressure taxes held guard")
	check(e.attack_rect().has_point(e.global_position-Vector2(0,30)),"body overlap is not a safe attack blind spot")

func test_exit_during_attack_ends_every_enemy_without_killing_warden() -> void:
	var lab := await fixture()
	lab.formation=1
	lab.reset_round()
	await physics_frames(14)
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.begin_attack("warden_double")
	e.feedback.receive(0.5,1,1)
	lab.player.position=Vector2(1150,520)
	await physics_frames(3)
	check(lab.route_passed and e.passed and e.outcome=="surrender","exit wins even during local stop")
	check(e.data.alive and e.health==18,"route success does not fake health defeat")
	for enemy: EnemyLabEnemy in lab.enemies: check(not enemy.outcome.is_empty(),"mixed encounter has no surviving queued attack")
	await physics_frames(90)
	eq(lab.player.health,5,"cleared route cannot deal a late second hit")

func test_defeat_remains_nonlethal_and_reset_clears_route_state() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.kill_comparison=true
	e.take_hit(100)
	check(e.outcome=="surrender" and e.data.alive,"debug kill toggle cannot rewrite sentry survival")
	lab.player.position=Vector2(1150,520)
	await physics_frames(3)
	check(lab.route_passed,"disabled sentry still allows later safe-line completion")
	lab.reset_round()
	await physics_frames(10)
	check(not lab.route_passed and not is_instance_valid(e),"R removes old route and old action owner")

func test_player_behind_guard_is_not_teleport_blocked() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.auto_attack=true
	lab.player.position=Vector2(1090,520)
	var previous: float=e.position.x
	await physics_frames(1)
	check(absf(e.position.x-previous)<10.0,"sentry approaches physically instead of teleporting to exit")
