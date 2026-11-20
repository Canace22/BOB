extends TestSuite
## 实际玩家输入/伤害接口、敌人控制与整轮清理的回归。
func fixture(index: int=0) -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.auto_attack=false
	lab.profile_index=index
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
	for code: Key in [KEY_J,KEY_I,KEY_K,KEY_L,KEY_Q,KEY_E,KEY_S,KEY_D,KEY_A,KEY_SPACE]: key(code,false)
	await physics_frames(2)
	await super.after_each()

func test_actual_basic_attack_uses_shared_player_feedback_and_single_target() -> void:
	var lab := await fixture()
	var e: EnemyLabEnemy=lab.enemies[0]
	lab.player.position=e.position-Vector2(100,0)
	lab.player.facing=1.0
	key(KEY_J,true)
	await physics_frames(12)
	key(KEY_J,false)
	eq(e.health,e.maximum-1,"real J reaches enemy through shared hit path")
	eq(e.reactions.received,1,"one swing is deduplicated")
	check(lab.player.hit_feedback.event_count>0,"shared impact feedback fires")

func test_front_shell_accumulates_half_damage_and_rear_hit_is_full() -> void:
	var lab := await fixture(2)
	var e: EnemyLabEnemy=lab.enemies[0]
	e.set_physics_process(false)
	lab.player.set_physics_process(false)
	lab.player.position=e.position-Vector2(100,0)
	e.facing=-1.0
	e.take_hit(1)
	eq(e.health,e.maximum,"first half point is retained rather than rounded up")
	check(is_equal_approx(e.reactions.damage_remainder,0.5),"shell remainder visible")
	e.take_hit(1)
	eq(e.health,e.maximum-1,"two guarded hits make one full damage")
	lab.player.position=e.position+Vector2(100,0)
	e.take_hit(1)
	eq(e.health,e.maximum-2,"one rear hit earns a full point")

func test_guard_breaks_food_double_but_heavy_control_is_windowed() -> void:
	var lab := await fixture()
	var e: EnemyLabEnemy=lab.enemies[0]
	e.set_physics_process(false)
	lab.player.position=e.position-Vector2(80,0)
	lab.player.facing=1.0
	check(e.begin_attack("double"),"double starts")
	key(KEY_I,true)
	await physics_frames(11)
	key(KEY_I,false)
	check(bool(EnemyLabDebug.player(lab.player).guard_open),"I reaches the actual guard window after chord buffering")
	e.advance_action(0.55)
	eq(e.state,"recover","real front guard cancels remaining second strike")
	eq(e.parry_count,1,"one guard confirmed")
	eq(EnemyLabDebug.segments(e).size(),3,"cancelled second hit disappears from actual timeline")
	eq(lab.player.health,5,"guard prevents damage")
	lab.profile_index=1
	lab.reset_round()
	await physics_frames(8)
	e=lab.enemies[0]
	e.launch(600)
	check(e.velocity.y>=0.0,"heavy body cannot be launched from neutral")
	e.move_key="flip"
	e.spec=EnemyLabCatalog.action("flip")
	e.set_state("recover")
	e.pin(0.3)
	eq(e.state,"hurt","heavy is interruptible in exposed window")

func test_crossed_phase_dispatches_one_hit_and_lock_does_not_follow_late_turn() -> void:
	var lab := await fixture()
	var e: EnemyLabEnemy=lab.enemies[0]
	e.set_physics_process(false)
	lab.player.set_physics_process(false)
	lab.player.position=e.position-Vector2(80,0)
	check(e.begin_attack("sweep"),"sweep starts")
	var facing: float=e.facing
	e.advance_action(1.0)
	eq(lab.player.health,4,"crossed tell and active still hits")
	lab.player.invulnerable=0.0
	e.advance_action(0.5)
	eq(lab.player.health,4,"spent strike does not hit again")
	lab.player.position=e.position+Vector2(80,0)
	eq(e.facing,facing,"committed attack does not turn on late crossing")

func test_reset_clears_projectiles_old_targets_and_control() -> void:
	var lab := await fixture()
	var old: EnemyLabEnemy=lab.enemies[0]
	var old_id: int=old.get_instance_id()
	old.begin_attack("double")
	lab.player.skill_controller.attacks.projectile(1,1.0)
	check(not tree.get_nodes_in_group("tide_player_projectiles").is_empty(),"real projectile exists before reset")
	var serial: int=lab.round_serial
	lab.reset_round()
	await physics_frames(8)
	eq(lab.round_serial,serial+1,"one atomic rebuild")
	check(not is_instance_id_valid(old_id),"old enemy freed")
	eq(tree.get_nodes_in_group("tide_targets").size(),1,"only new target remains")
	eq(tree.get_nodes_in_group("tide_player_projectiles").size(),0,"old projectile removed")
	eq(lab.player.pending_action,"","queued action cleared")
	eq(lab.player.health,lab.player.max_health,"player restored")

func test_pause_step_advances_exactly_one_physics_tick() -> void:
	var lab := await fixture()
	var e: EnemyLabEnemy=lab.enemies[0]
	check(e.begin_attack("sweep"),"pause fixture starts attack")
	lab.toggle_pause()
	var before: float=e.timer
	var ticks: int=lab.simulation_ticks
	await physics_frames(4)
	check(is_equal_approx(e.timer,before),"paused actor does not tick")
	lab.step_requested=true
	await physics_frames(4)
	check(is_equal_approx(e.timer-before,1.0/60.0),"step grants exactly one simulation tick")
	eq(lab.simulation_ticks,ticks+1,"single step is counted once")
	check(tree.paused,"single step leaves scene paused")
	lab.toggle_pause()

func test_three_outcomes_stop_attacks_without_campaign_rewards() -> void:
	var lab := await fixture()
	for index: int in 3:
		lab.profile_index=index
		lab.kill_comparison=index==1
		lab.reset_round()
		await physics_frames(8)
		var e: EnemyLabEnemy=lab.enemies[0]
		e.take_hit(100)
		var expected: String=["retreat","kill","surrender"][index]
		eq(e.outcome,expected,"endings are independent of raw HP death")
		eq(bool(e.data.alive),expected!="kill","nonlethal actors stay alive")
		check(not e.is_in_group("tide_targets") and not e.begin_attack(),"ended target cannot attack or be farmed")
		var received: int=e.reactions.received
		e.take_hit(100)
		eq(e.reactions.received,received,"later hits cannot repeat finish")

func test_narrow_ceiling_blocks_crossing_but_wide_area_allows_jump() -> void:
	var lab := await fixture(1)
	lab.terrain=1
	lab.reset_round()
	await physics_frames(8)
	lab.player.position=Vector2(1100,EnemyLab.FLOOR)
	key(KEY_SPACE,true)
	await physics_frames(16)
	var narrow: float=lab.player.position.y
	key(KEY_SPACE,false)
	lab.reset_round()
	await physics_frames(8)
	lab.player.position=Vector2(500,EnemyLab.FLOOR)
	key(KEY_SPACE,true)
	await physics_frames(16)
	check(narrow>EnemyLab.FLOOR-110.0,"narrow ceiling denies crossing heavy body")
	check(lab.player.position.y<EnemyLab.FLOOR-110.0,"wide area gives a real side-switch opportunity")

func test_pause_preserves_backstep_for_single_frame_inspection() -> void:
	var lab := await fixture()
	check(lab.player.try_backstep(),"start actual backstep")
	lab.toggle_pause()
	var time: float=lab.player.retreat_time
	await physics_frames(4)
	check(lab.player.retreating and is_equal_approx(lab.player.retreat_time,time),"debug pause freezes rather than cancels retreat")
	lab.step_requested=true
	await physics_frames(4)
	check(lab.player.retreating and lab.player.retreat_time>time,"backstep can be inspected one frame at a time")
	lab.toggle_pause()

func test_staggered_mixed_spawn_keeps_valid_visual_frames() -> void:
	var lab := await fixture(1)
	lab.formation=1
	lab.auto_attack=true
	lab.reset_round()
	await physics_frames(12)
	eq(lab.enemies.size(),2,"mixed round has two targets")
	for e: EnemyLabEnemy in lab.enemies:
		check(e.visual.pose_id>=0 and e.visual.pose_id<16,"staggered walking stays on valid authored frames")

func test_heavy_interrupt_opens_only_at_end_of_flip() -> void:
	var lab := await fixture(1)
	var e: EnemyLabEnemy=lab.enemies[0]
	e.set_physics_process(false)
	check(e.begin_attack("flip"),"begin flip")
	check(lab.player.request_action("wb_draw"),"real heavy skill available")
	e.timer=0.10
	e.take_hit(3)
	eq(e.state,"tell","early heavy hit cannot skip protected startup")
	e.timer=0.70
	check(bool(e.snapshot().heavy_window),"debug adapter reports actual heavy window")
	e.take_hit(3)
	eq(e.state,"hurt","late heavy hit interrupts committed flip")

func test_menu_pause_restore_is_idempotent_and_preserves_manual_pause() -> void:
	var lab := await fixture()
	var popup: PopupMenu=lab.hud.enemy_menu.get_popup()
	popup.about_to_popup.emit()
	popup.about_to_popup.emit()
	check(tree.paused,"menu temporarily pauses simulation")
	lab.hud.enemy_menu.item_selected.emit(1)
	popup.popup_hide.emit()
	await physics_frames(4)
	eq(lab.enemies[0].profile.id,"mudback","actual selection callback rebuilds mudback")
	check(not tree.paused,"duplicate show does not retain temporary pause")
	var ticks: int=lab.simulation_ticks
	await physics_frames(3)
	check(lab.simulation_ticks>ticks,"rebuilt simulation advances")
	tree.paused=true
	popup.about_to_popup.emit()
	popup.about_to_popup.emit()
	popup.popup_hide.emit()
	check(tree.paused,"original manual pause survives menu close")
	tree.paused=false
