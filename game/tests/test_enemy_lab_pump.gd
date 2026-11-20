extends TestSuite
## 场景压力、角色物理运动、真实F交互及停战清理合同。
func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=5
	lab.terrain=4
	lab.auto_attack=false
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
	for code: Key in [KEY_F,KEY_I,KEY_D,KEY_A,KEY_J,KEY_SPACE]: key(code,false)
	await super.after_each()

func test_pump_has_own_assets_and_publishes_real_phase() -> void:
	var lab := await fixture()
	var court: EnemyLabPumpCourt=lab.pump_court
	check(court!=null and court.warden==lab.enemies[0],"one scene authority bound to sentry")
	eq(lab.hud.move_menu.item_count,7,"boss skills remain independent of level sample")
	court.manual=true
	court.timer=2.39
	await physics_frames(3)
	check(court.phase=="stroke" and court.view.jet.visible,"actual pressure enters visible pumping interval")
	await physics_frames(55)
	eq(court.phase,"release","pressure has finite recovery")

func test_real_f_vents_near_valve_and_opens_bounded_sentry_window() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.begin_attack("warden_barrage")
	lab.player.position=Vector2(600,520)
	lab.pump_court.request("sluice")
	key(KEY_F,true)
	await physics_frames(3)
	key(KEY_F,false)
	check(lab.pump_court.vents==1 and lab.pump_court.vent_left>2.8,"real nearby F unloads pressure")
	check(e.state=="recover" and e.opening_left>1.0,"connected sentry loses balance")
	check(not lab.pump_court.view.jet.visible,"no hidden damaging jet remains after relief")
	var before: float=lab.pump_court.vent_left
	key(KEY_F,true)
	await physics_frames(3)
	key(KEY_F,false)
	check(lab.pump_court.vent_left<before and lab.pump_court.vents==1,"repeated F cannot refresh same vent indefinitely")

func test_remote_f_cannot_operate_valve() -> void:
	var lab := await fixture()
	lab.player.position=Vector2(420,520)
	key(KEY_F,true)
	await physics_frames(3)
	key(KEY_F,false)
	eq(lab.pump_court.vents,0,"interaction requires physical approach")

func test_real_water_volume_damages_once_and_not_only_at_floor() -> void:
	var lab := await fixture()
	var court: EnemyLabPumpCourt=lab.pump_court
	lab.player.position=Vector2(980,380)
	court.phase="stroke"
	court.timer=0.11
	court.manual=true
	await physics_frames(40)
	eq(court.hits,1,"one stroke is one attack even if player stays near")
	eq(lab.player.health,4,"visible tall jet is not bypassed by a shallow hop")
	check(absf(lab.player.position.x-980)<500,"physical drift does not create unbounded launch")

func test_ground_pull_moves_toward_inlet_with_bounded_motor_speed() -> void:
	var lab := await fixture()
	lab.player.position=Vector2(780,520)
	lab.pump_court.request("siphon")
	await physics_frames(62)
	check(lab.player.position.x>800 and lab.player.position.x<865,"reverse pressure physically pulls toward fixed inlet")
	check(absf(lab.player.velocity.x)<400,"water drift does not accumulate as runaway acceleration")
	eq(lab.player.health,5,"reverse flow controls position without hidden contact damage")

func test_level_pressure_is_independent_of_boss_cast() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	lab.pump_court.request("sluice")
	await physics_frames(40)
	check(lab.pump_court.manual,"level controller starts without a boss command")
	eq(e.hit_count,0,"directing pressure has no invisible melee hit")
	check(lab.pump_court.view.pump.texture!=null,"level mechanism retains its own presentation")

func test_pause_freezes_pump_physics_and_visual_clock() -> void:
	var lab := await fixture()
	lab.pump_court.request("siphon")
	await physics_frames(48)
	tree.paused=true
	var time: float=lab.pump_court.clock
	var position: Vector2=lab.player.position
	await physics_frames(30)
	eq(lab.pump_court.clock,time,"pump shader clock does not advance while paused")
	eq(lab.player.position,position,"paused actor cannot drift")
	tree.paused=false

func test_stop_and_reset_clear_water_but_keep_facility_alive() -> void:
	var lab := await fixture()
	var court: EnemyLabPumpCourt=lab.pump_court
	court.request("sluice")
	court.phase="stroke"
	court.timer=0.1
	lab.enemies[0].finish()
	await physics_frames(3)
	check(court.stopped and not court.view.jet.visible,"sentry ending clears dangerous flow")
	var time: float=court.clock
	await physics_frames(30)
	check(court.clock>time,"unloaded membrane still operates harmlessly")
	lab.reset_round()
	await physics_frames(12)
	check(not is_instance_valid(court) and lab.player.pump_drift==0.0,"R clears pressure owner and residual motor drift")
