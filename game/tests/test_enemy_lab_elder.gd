extends TestSuite
## 撑柄稳定、两段换握、真实腾跃和固定存活的接口合同。
func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=7
	lab.auto_attack=false
	add(lab)
	await physics_frames(14)
	lab.player.position=Vector2(745,520)
	lab.player.facing=1.0
	return lab

func test_eighth_enemy_and_all_authored_poses() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	check(e!=null,"stable elder ID selects own executor")
	eq(lab.hud.enemy_menu.item_count,8,"eight selectable enemies")
	eq(lab.hud.move_menu.item_count,6,"four own skills plus observation replay")
	check(e.visual.texture.resource_path.contains("enemy-lab-elder"),"independent tall broad silhouette")
	eq(e.visual.metadata.elder_guardian.regions.size(),24,"twenty four key poses")

func test_stability_front_armor_rear_and_displaced_damage() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	e.take_hit(1)
	check(e.health==24 and e.reactions.damage_remainder==0.5,"stable front armor retains half damage")
	lab.player.position.x=e.position.x+95
	e.take_hit(1)
	check(e.health==23 and e.reactions.damage_remainder==0.5,"rear receives full damage")
	e.position.x+=100
	e.begin_attack("elder_thrust")
	check(not e.stable and is_equal_approx(float(e.spec.recover),1.55),"off anchor adds recovery rather than health gimmick")
	e.take_hit(1)
	eq(e.health,22,"unstable attack has no front armor")

func test_intro_and_distance_selection_do_not_repeat_three_thrusts() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	eq(e.choose_move(),"elder_sweep","first demonstrates low gate sweep")
	e.begin_attack()
	e.set_state("idle")
	eq(e.choose_move(),"elder_thrust","second demonstrates long committed thrust")
	e.begin_attack()
	e.set_state("idle")
	e.begin_attack("elder_thrust")
	e.set_state("idle")
	lab.player.position.x=500
	check(e.choose_move()!="elder_thrust","distance cannot force a third identical natural thrust")

func test_first_block_keeps_second_and_final_perfect_opens() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	e.begin_attack("elder_grip")
	e.set_state("active")
	e.hit_sent=true
	e.guard_reaction(false)
	check(e.state=="active" and not e.followup_cancelled,"ordinary first block keeps second at source")
	e.advance_action(0.20)
	check(e.state=="tell" and e.pulse==2 and e.phase_duration()==0.55,"second grip has complete new tell")
	e.guard_reaction(true)
	check(e.state=="recover" and e.opening_left==1.55 and not e.stable,"final perfect creates stance opening")

func test_far_miss_cancels_followup_and_timeline() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	e.begin_attack("elder_grip")
	e.set_state("active")
	lab.player.position.x=200
	e.advance_action(0.20)
	check(e.state=="recover" and e.followup_cancelled,"no meaningless second press across arena")
	eq(e.segments().size(),3,"cancelled second absent from actual timeline")

func test_thrust_locks_and_warning_clears_after_end() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	e.begin_attack("elder_thrust")
	e.timer=0.80
	var direction: float=e.facing
	lab.player.position.x=e.position.x+100
	await physics_frames(2)
	eq(e.facing,direction,"committed thrust cannot follow rear")
	check(float((e.visual.material as ShaderMaterial).get_shader_parameter("danger"))>0.0,"only heavy thrust uses red warning")
	e.finish()
	eq(float((e.visual.material as ShaderMaterial).get_shader_parameter("danger")),0.0,"ending immediately clears red")

func test_vault_is_physical_vulnerable_and_lands_before_strike() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	e.begin_attack("elder_vault")
	e.timer=0.84
	await physics_frames(2)
	check(e.state=="vault" and e.velocity.y<0.0,"vault has physical jump velocity")
	var start: Vector2=e.position
	await physics_frames(12)
	check(e.position.y<start.y-35 and absf(e.position.x-start.x)>35,"body really travels through air")
	e.take_hit(1)
	eq(e.health,23,"airborne body is not hidden or invulnerable")
	for frame: int in 60:
		await physics_frames(1)
		if e.state=="settle": break
	check(e.state=="settle" and e.is_on_floor() and e.timer<0.03,"landing starts separate readable grip preparation")
	eq(lab.player.health,5,"flight itself has no invisible contact damage")

func test_replant_pressure_forces_unstable_next_action() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	e.position.x+=100
	e.stable=false
	e.set_state("reground")
	var x: float=e.position.x
	await physics_frames(10)
	check(e.position.x<x and e.position.x>x-40,"visible physical replant steps, not teleport")
	e.take_hit(1)
	check(e.state=="idle" and e.cycle.replant_interrupts==1 and e.force_unstable,"real pressure denies return")
	e.begin_attack("elder_sweep")
	check(not e.stable and e.spec.recover>1.1,"denied stance adds next punish opportunity")

func test_opening_budget_cannot_be_refreshed_into_permanent_control() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	e.begin_attack("elder_sweep")
	e.set_state("recover")
	for i: int in 12:
		e.pin(0.40)
		e.take_hit(1)
		if i==0: eq(e.phase_duration(),float(e.spec.recover),"controlled HUD reads finite opening duration")
		await physics_frames(10)
	check(e.health>0 and e.opening_left==0.0 and e.control_left==0.0 and not e.control_window_open(),"finite opening survives repeated hits without replenishment")

func test_ending_is_alive_even_debug_kill_and_reset_clears_vault() -> void:
	var lab := await fixture()
	var e: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	e.kill_comparison=true
	e.begin_attack("elder_vault")
	e.take_hit(100)
	check(e.outcome=="surrender" and e.data.alive and e.health==0 and not e.stable,"disable and survive, never killed by toggle")
	await physics_frames(120)
	eq(lab.player.health,5,"no queued landing strike after surrender")
	lab.reset_round()
	await physics_frames(14)
	check(not is_instance_valid(e) and lab.enemies[0].health==24,"R disposes motion owner and restores elder")
