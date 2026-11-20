extends TestSuite
## 新主动防御的受击拦截与可拆反击，原三招合同另行保留。
func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=6
	lab.auto_attack=false
	add(lab)
	await physics_frames(14)
	lab.player.position=Vector2(750,520)
	lab.player.facing=1.0
	return lab

func guard_ready(e: EnemyLabBeamGuard) -> void:
	e.begin_attack("beam_guard")
	for frame: int in 30:
		await physics_frames(1)
		if e.state=="guarding": break

func test_blocked_contact_has_zero_damage_and_preserves_fraction() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	await guard_ready(e)
	e.reactions.damage_remainder=0.5
	e.take_hit(1)
	check(e.health==18 and e.reactions.damage_remainder==0.5,"blocked hit never enters HP or half damage accumulation")
	check(e.defense.blocks==1 and e.reactions.received==1,"one real hit and one block")
	check(e.state=="guard_contact" and e.timer==0.0,"block confirms before new riposte preparation")
	e.receive_feedback(0.1,1.0,12.0)
	check(e.feedback.stop_left==0.0,"block uses dedicated metal impact rather than flesh hitstop")

func test_fresh_riposte_has_locked_full_tell_and_is_blockable() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	await guard_ready(e)
	e.take_hit(1)
	for frame: int in 30:
		await physics_frames(1)
		if e.move_key=="beam_riposte": break
	check(e.state=="tell" and e.timer<0.03 and e.phase_duration()==0.55,"full separate counter tell follows contact")
	check(not bool(e.spec.get("unblockable",false)),"riposte can be guarded, distinct from red shove")
	var locked: float=e.facing
	lab.player.position.x=e.position.x+90
	await physics_frames(12)
	eq(e.facing,locked,"counter never snaps to rear attacker")
	e.take_hit(1)
	check(e.health==17 and e.defense.ripostes==1,"counter tell exposed and single queued riposte")

func test_heavy_and_rear_break_defense_and_cancel_counter() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	await guard_ready(e)
	e.take_hit(3)
	check(e.health==15 and e.defense.breaks==1 and e.control_window_open(),"heavy damages and opens defense")
	eq(e.defense.ripostes,0,"heavy break cancels queued revenge")
	e.set_state("idle")
	await guard_ready(e)
	lab.player.position.x=e.position.x+90
	e.take_hit(1)
	check(e.health==14 and e.defense.breaks==2,"rear bypasses block and opens")
	eq(e.defense.blocks,0,"neither hit counted as guard")

func test_multihit_breaks_contact_without_refreshing_timer() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	await guard_ready(e)
	e.take_hit(1)
	e.timer=0.10
	e.take_hit(1)
	check(e.health==17 and e.defense.blocks==1 and e.defense.breaks==1,"second contact exhausts finite brace")
	check(e.control_window_open() and e.defense.ripostes==0,"multiple hits cancel, never queue repeated counters")
	check(not e.defense.ring.visible and e.defense.impact_age>=0.24,"breaking guard clears old block impact")

func test_guard_whiff_and_windup_take_damage() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	e.begin_attack("beam_guard")
	e.take_hit(1)
	eq(e.health,17,"raising guard has no instant invulnerability")
	await physics_frames(65)
	check(e.state=="recover" and e.defense.ripostes==0 and lab.player.health==5,"waiting out guard gives opening and no automatic strike")

func test_earned_player_counter_breaks_guard_and_fatal_break_wins() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	await guard_ready(e)
	var guard: EnemyLabSkills=lab.player.skill_controller as EnemyLabSkills
	guard.counter_bonus=2
	guard.counter_left=1.0
	e.take_hit(1)
	check(e.health==15 and guard.counter_bonus==0 and e.defense.breaks==1,"earned counter reward is consumed once by original damage path")
	e.set_state("idle")
	await guard_ready(e)
	e.take_hit(100)
	check(e.outcome=="kill" and e.defense.ripostes==0,"fatal heavy ends before defensive counter")
