extends TestSuite
## 验证技能间的真实控制、位移、命中和防御取消，不只检查配置存在。

func fixture() -> Node2D:
	var arena: Node2D = preload("res://tests/whitebox_combat/main.tscn").instantiate()
	add(arena)
	await physics_frames(8)
	return arena

func after_each() -> void:
	for action: String in ["tp_attack","tp_left","tp_right","wb_rise","wb_drive","wb_draw","wb_charge","wb_flurry"]:
		if InputMap.has_action(action): Input.action_release(action)
	await super.after_each()

func recovery(p: CombatWhiteboxPlayer) -> bool:
	for frame: int in 100:
		if p.skill_controller.active and p._offense_released(): return true
		await physics_frames(1)
	return false

func test_rise_triple_sweep_form_a_real_combo() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("wb_rise"),"upper starts")
	check(await recovery(p),"upper releases")
	check(arena.enemy.vertical_speed < 0.0,"launch impulse is applied at contact before shared hitstop ends")
	for i: int in 12:
		if arena.enemy.position.y < 540: break
		await physics_frames(1)
	check(arena.enemy.position.y < 540,"upper actually lifts target")
	check(p.request_action("wb_drive"),"triple chains from upper recovery")
	check(await recovery(p),"first manually triggered step releases")
	check(p.position.x > 550,"step advances player")
	check(p.request_action("wb_draw"),"wide finisher chains from triple")
	await physics_frames(25)
	check(arena.enemy.health <= 7,"rise, one step and sweep deal five damage")
	check(p.skill_controller.combo_hits >= 3,"combo meter counts contacts, not damage points")
	# 新反馈会同步冻结敌人；验证真实落地结果，不沿用旧的仅攻击者停顿壁钟。
	for i: int in 30:
		if arena.enemy.state in ["down","dead"]: break
		await physics_frames(1)
	check(arena.enemy.state in ["down","dead"],"finisher puts target down")

func test_backstep_cut_keeps_retreat_motion_and_has_no_free_followups() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(not p.request_action("wb_backcut"),"backcut requires backstep")
	check(p.try_backstep(),"approved backstep starts")
	Input.action_press("tp_attack")
	await physics_frames(6)
	Input.action_release("tp_attack")
	eq(arena.enemy.health,11,"backcut hits once while retreating")
	check(p.retreating,"attack did not terminate retreat")
	eq(p.facing,1.0,"facing preserved")
	await physics_frames(35)
	check(p.position.x < 460,"approved retreat distance preserved")
	eq(arena.enemy.health,11,"release does not fire a stale attack")

func test_flurry_has_five_hits_and_cannot_skip_pulses_with_guard() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	arena.enemy.health = 60
	check(p.request_action("wb_flurry"),"flurry starts")
	await physics_frames(12)
	check(not p.request_action("parry"),"guard cannot discard remaining flurry hits")
	check(await recovery(p),"flurry reaches final hit")
	eq(arena.enemy.health,55,"five distinct hits")
	check(p.request_action("parry"),"guard cancels flurry recovery")
	check(p.cooldowns.wb_flurry > 0.0,"cancel keeps flurry cooldown")

func test_charge_lifts_and_armor_resists_control() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("wb_charge"),"charge starts")
	check(await recovery(p),"charge releases")
	await physics_frames(2)
	check(p.position.x > 600,"charge closes distance")
	check(arena.enemy.vertical_speed < 0.0,"charge applies launch impulse on contact")
	for i: int in 12:
		if arena.enemy.position.y < 540: break
		await physics_frames(1)
	check(arena.enemy.position.y < 540,"charge moves target upward after shared hitstop")
	arena.reset_arena()
	arena.enemy.armored = true
	await physics_frames(3)
	arena.enemy.begin_attack()
	check(p.request_action("wb_rise"),"rise against armored windup")
	await physics_frames(12)
	eq(arena.enemy.position.y,540.0,"armor resists launch")
	eq(arena.enemy.state,"tell","armor keeps attack intent")

func test_group_sweep_hits_multiple_targets_but_not_out_of_range() -> void:
	var arena := await fixture()
	arena.toggle_group()
	arena.extra_targets[1].position.x = 1100
	check(arena.player.request_action("wb_draw"),"wide sweep starts")
	await physics_frames(25)
	eq(arena.enemy.health,9,"primary target hit")
	eq(arena.extra_targets[0].health,9,"second target hit")
	eq(arena.extra_targets[1].health,12,"distant target untouched")
	eq(arena.extra_targets[1].state,"idle","distant target not knocked down")

func test_keyboard_skill_cooldown_and_backstep_cancel_no_ghost_hits() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	var event := InputEventKey.new()
	event.keycode = KEY_Q
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frames(1)
	event = InputEventKey.new()
	event.keycode = KEY_I
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frames(2)
	event.pressed = false
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.keycode = KEY_Q
	event.pressed = false
	Input.parse_input_event(event)
	eq(p.skill_controller.visual_key,"wb_draw","skill shortcut reaches controller")
	check(p.try_backstep(),"backstep still forcibly cancels new skill startup")
	await physics_frames(35)
	eq(arena.enemy.health,12,"cancelled new skill never releases")
	check(not p.request_action("wb_draw"),"cancelled skill still on cooldown")

func test_launch_protection_limits_repeated_lifts_and_resets_on_ground() -> void:
	var arena := await fixture()
	for i: int in 3: arena.enemy.launch(510.0)
	var before: float = arena.enemy.vertical_speed
	arena.enemy.launch(510.0)
	eq(arena.enemy.air_lifts,3,"three lifts maximum")
	eq(arena.enemy.vertical_speed,before,"fourth lift rejected")
	await physics_frames(60)
	eq(arena.enemy.air_lifts,0,"landing resets juggle protection")

func test_drive_needs_three_presses_can_reverse_and_cannot_repeat_fourth() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("wb_drive"),"first tap")
	await physics_frames(20)
	eq(arena.enemy.health,11,"single press releases only one hit")
	var first_x: float = p.position.x
	Input.action_press("tp_left")
	check(p.request_action("wb_drive"),"second tap continues within window")
	await physics_frames(12)
	Input.action_release("tp_left")
	check(p.position.x < first_x,"second step can reverse direction")
	check(p.request_action("wb_drive"),"third tap")
	check(await recovery(p),"third step releases")
	check(not p.request_action("wb_drive"),"fourth press blocked by cooldown")
	Input.action_release("tp_left")

func test_sweep_pushes_both_sides_while_flurry_roots_player() -> void:
	var arena := await fixture()
	arena.toggle_group()
	arena.extra_targets[0].position.x = 430.0
	check(arena.player.request_action("wb_draw"),"sweep")
	await physics_frames(24)
	check(arena.enemy.position.x >= 800,"sweep pushes front target away")
	check(arena.extra_targets[0].position.x <= 280,"sweep pushes rear target away")
	arena.reset_arena()
	await physics_frames(4)
	var start_x: float = arena.player.position.x
	check(arena.player.request_action("wb_flurry"),"flurry")
	Input.action_press("tp_right")
	await physics_frames(20)
	Input.action_release("tp_right")
	eq(arena.player.position.x,start_x,"flurry holds position despite movement input")
	check(arena.enemy.position.x == 650.0,"flurry pins instead of blasting target away")

func test_drive_accepts_deliberate_pause_but_still_expires() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("wb_drive"),"first step")
	await physics_frames(50)
	check(p.request_action("wb_drive"),"0.83 second pause still continues second step")
	eq(p.skill_controller.drive_step,2,"pause continues chain rather than restarting")
	arena.reset_arena()
	await physics_frames(4)
	check(p.request_action("wb_drive"),"new chain")
	await physics_frames(75)
	check(not p.request_action("wb_drive"),"1.25 second pause expires while cooldown remains")
