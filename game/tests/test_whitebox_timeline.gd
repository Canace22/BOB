extends TestSuite
## 通过真实技能与物理帧核对显示窗口，防止UI展示的时序脱离行为。

func fixture() -> Node2D:
	var arena: Node2D = preload("res://tests/whitebox_combat/main.tscn").instantiate()
	add(arena)
	await physics_frames(8)
	return arena

func test_guard_track_matches_actual_window() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("parry"),"guard starts")
	var first: Dictionary = CombatWhiteboxTimelineData.sample(p,arena.enemy)
	check(not first.guard_open,"startup is not guard window")
	eq(first.phase,"STARTUP","guard startup is not mislabeled as active")
	await physics_frames(7)
	var open: Dictionary = CombatWhiteboxTimelineData.sample(p,arena.enemy)
	check(open.guard_open,"actual guard window displayed open")
	eq(open.guard_start,0.06,"window start from current skill data")
	eq(open.guard_end,0.21,"window end from current skill data")
	await physics_frames(10)
	var closed: Dictionary = CombatWhiteboxTimelineData.sample(p,arena.enemy)
	check(not closed.guard_open,"guard closes while recovery continues")
	eq(closed.phase,"RECOVERY","expired guard window labeled recovery")

func test_multi_hit_cancel_lane_is_not_open_after_first_hit() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("wb_flurry"),"flurry starts")
	await physics_frames(12)
	var early: Dictionary = CombatWhiteboxTimelineData.sample(p,arena.enemy)
	eq(early.hits.size(),5,"all five hit markers present")
	check(not early.recovery_open and not early.guard_ready,"cancel lane remains closed between hits")
	for i: int in 90:
		if p._offense_released(): break
		await physics_frames(1)
	var late: Dictionary = CombatWhiteboxTimelineData.sample(p,arena.enemy)
	check(late.recovery_open and late.guard_ready,"cancel lane opens after actual final hit")
	eq(late.recovery,0.66,"last pulse defines recovery boundary")

func test_chain_countdown_survives_action_end_and_sampling_is_read_only() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("wb_drive"),"drive starts")
	await physics_frames(25)
	var state_before: String = p.state
	var cd_before: float = p.cooldowns.wb_drive
	var left_before: float = p.skill_controller.drive_window
	var current: Dictionary = CombatWhiteboxTimelineData.sample(p,arena.enemy)
	check(current.chain_open,"chain countdown survives natural end")
	eq(current.chain_step,1,"first stage displayed")
	eq(current.chain_left,left_before,"countdown comes from controller")
	eq(p.state,state_before,"sampling does not change state")
	eq(p.cooldowns.wb_drive,cd_before,"sampling does not consume cooldown")
	eq(p.skill_controller.drive_window,left_before,"sampling does not advance chain timer")
	await physics_frames(60)
	check(not CombatWhiteboxTimelineData.sample(p,arena.enemy).chain_open,"expired countdown displays closed")

func test_hitstop_freezes_progress_and_dash_reports_live_immunity() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("wb_draw"),"sweep starts")
	p.hitstop = 0.1
	var before: Dictionary = CombatWhiteboxTimelineData.sample(p,arena.enemy)
	await physics_frames(3)
	var frozen: Dictionary = CombatWhiteboxTimelineData.sample(p,arena.enemy)
	eq(frozen.elapsed,before.elapsed,"timeline freezes with actor hitstop")
	check(frozen.hitstop > 0.0,"hitstop shown separately")
	arena.reset_arena()
	await physics_frames(3)
	check(p.request_action("A1_dash"),"dash starts")
	var dash: Dictionary = CombatWhiteboxTimelineData.sample(p,arena.enemy)
	check(dash.invulnerable > 0.0,"reports actual immunity")
	await physics_frames(20)
	check(CombatWhiteboxTimelineData.sample(p,arena.enemy).invulnerable <= 0.0,"immunity expires on actual timer")

func test_panel_retains_cancelled_skill_for_inspection() -> void:
	var arena := await fixture()
	check(arena.player.request_action("wb_draw"),"sweep starts")
	await physics_frames(2)
	check(arena.player.try_backstep(),"cancel sweep")
	eq(arena.timeline.last_reason,"CANCEL","panel captures interruption at event boundary")
	eq(arena.timeline.last_action.key,"wb_draw","captured original skill instead of replacement pose")
	await physics_frames(40)
	eq(arena.timeline.last_action.key,"wb_draw","cancelled skill stays available after retreat lands")
