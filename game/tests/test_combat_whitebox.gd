extends TestSuite
## 白盒复用真实角色内核、碰撞地面与敌方判定；测试不导入或写入主线档。

const ARENA := preload("res://tests/whitebox_combat/main.tscn")

func fixture() -> Node2D:
	var arena: Node2D = ARENA.instantiate()
	add(arena)
	arena.enemy.auto_attack = false
	await physics_frames(8)
	return arena

func after_each() -> void:
	for action: String in ["wb_backstep","tp_attack","tp_left","tp_right","tp_parry","tp_jump","tp_dash"]:
		if InputMap.has_action(action): Input.action_release(action)
	await super.after_each()

func test_attack_cancel_clears_buffer_and_unreleased_hit() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("strike_01"),"real melee starts")
	p.pending_action = "strike2"
	p.pending_left = 0.12
	Input.action_press("wb_backstep")
	await physics_frames(2)
	Input.action_release("wb_backstep")
	check(p.retreating,"real input cancels melee in its startup")
	eq(p.pending_action,"","queued attack discarded")
	await physics_frames(35)
	eq(arena.enemy.health,12,"cancelled melee never releases a delayed hit")
	check(p.position.x < 460,"backward travel exceeds 90px")
	eq(p.facing,1.0,"retreat keeps facing enemy")
	check(p.is_on_floor() and not p.retreating,"lands and returns control")

func test_cancel_skill_keeps_cost_cooldown_and_stops_future_pulses() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	p.soul = 99
	check(p.request_action("up_spell"),"resource skill starts")
	eq(p.soul,66,"cost paid")
	check(p.try_backstep(),"skill startup can be cancelled")
	eq(p.soul,66,"cancel does not refund cost")
	check(p.cooldowns.orb > 0.0,"shared cooldown retained")
	await physics_frames(35)
	eq(arena.enemy.health,12,"cancelled skill does not release")
	arena.reset_arena()
	await physics_frames(3)
	check(p.request_action("cyclone"),"multi-hit skill starts")
	await physics_frames(10)
	var hp: int = arena.enemy.health
	check(hp < 12,"first pulse actually hit target")
	check(p.try_backstep(),"cancel during active multi-hit")
	await physics_frames(45)
	eq(arena.enemy.health,hp,"remaining pulses cancelled")

func test_backstep_rejects_air_hurt_and_repeat_without_immunity() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	p.facing = -1.0
	check(p.try_backstep(),"left facing retreat starts")
	check(not p.try_backstep(),"cannot cancel retreat into another retreat")
	await physics_frames(4)
	check(p.position.x > 550,"left facing retreats right")
	eq(p.facing,-1.0,"left facing retained")
	eq(p.invulnerable,0.0,"retreat adds no immunity")
	check(p.take_damage(1,Vector2(900,540)),"retreat can be hit")
	check(not p.retreating,"damage interrupts retreat")
	check(not p.try_backstep(),"hurt cannot be escaped")
	await physics_frames(50)
	p.controls_enabled = false
	check(not p.try_backstep(),"input lock respected")
	p.controls_enabled = true
	p.health = 0
	check(not p.try_backstep(),"dead player cannot retreat")

func test_actual_sweep_hits_baseline_but_backstep_evades() -> void:
	var arena := await fixture()
	arena.enemy.begin_attack()
	await physics_frames(55)
	eq(arena.player.health,4,"baseline enemy sweep hits standing player")
	arena.reset_arena()
	await physics_frames(4)
	arena.enemy.begin_attack()
	await physics_frames(28)
	check(arena.player.try_backstep(),"respond during visible windup")
	await physics_frames(35)
	eq(arena.player.health,5,"same sweep misses retreating player")
	check(arena.enemy.state=="recover","enemy exposes counter window")

func test_parry_staggers_real_attack_and_opens_counter() -> void:
	var arena := await fixture()
	arena.enemy.begin_attack()
	await physics_frames(40)
	check(arena.player.request_action("parry"),"parry starts near impact")
	await physics_frames(10)
	eq(arena.player.health,5,"parry prevents damage")
	eq(arena.enemy.parry_count,1,"enemy receives parry feedback")
	eq(arena.enemy.state,"stagger","parry produces counter window")
	await physics_frames(18)
	check(arena.player.request_action("strike_01"),"counter input accepted")
	await physics_frames(10)
	check(arena.enemy.health < 12,"counter actually reaches enemy")

func test_long_thrust_can_catch_backstep_and_jump_evades_low_sweep() -> void:
	var arena := await fixture()
	arena.enemy.mode = 1
	arena.enemy.begin_attack()
	await physics_frames(28)
	check(arena.player.try_backstep(),"retreat starts against long thrust")
	await physics_frames(35)
	eq(arena.player.health,4,"long attack catches retreat: not universal defense")
	arena.reset_arena()
	arena.enemy.mode = 0
	await physics_frames(4)
	arena.enemy.begin_attack()
	await physics_frames(22)
	Input.action_press("tp_jump")
	await physics_frames(30)
	Input.action_release("tp_jump")
	eq(arena.player.health,5,"jump clears low sweep")

func test_logical_keyboard_event_reaches_backstep() -> void:
	var arena := await fixture()
	var event := InputEventKey.new()
	event.keycode = KEY_Z
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frames(3)
	check(arena.player.retreating,"logical keyboard event triggers the same gameplay action")
	event.pressed = false
	Input.parse_input_event(event)

func test_dash_avoids_thrust_and_armored_windup_resists_melee() -> void:
	var arena := await fixture()
	arena.enemy.mode = 1
	arena.enemy.begin_attack()
	await physics_frames(38)
	check(arena.player.request_action("A1_dash"),"basic dash is available in the whitebox")
	await physics_frames(20)
	eq(arena.player.health,5,"dash invulnerability handles long thrust")
	arena.reset_arena()
	arena.enemy.armored = true
	await physics_frames(4)
	arena.enemy.begin_attack()
	check(arena.player.request_action("strike_01"),"player attacks armored windup")
	await physics_frames(10)
	check(arena.enemy.health < 12,"attack hit enemy")
	eq(arena.enemy.state,"tell","armor prevents attack from cancelling tell")
	await physics_frames(45)
	eq(arena.player.health,4,"continuing offense trades health against armor")

func test_guard_cancels_melee_recovery_before_old_gate_and_clears_queue() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("strike_01"),"start melee")
	check(not p.request_action("parry"),"guard cannot cancel startup")
	await physics_frames(12)
	check(p.state_time < p.state_duration*0.65,"test reaches recovery before old 65 percent gate")
	p.pending_action = "strike2"
	p.pending_left = 0.12
	Input.action_press("tp_parry")
	await physics_frames(2)
	Input.action_release("tp_parry")
	eq(p.skill_controller.visual_key,"parry","guard actually starts")
	eq(p.pending_action,"","cancel clears queued attack")
	await physics_frames(35)
	eq(arena.enemy.health,11,"no ghost second strike after guard")

func test_defenses_cancel_skill_recovery_but_keep_cost_and_cooldowns() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("up_spell"),"start paid skill")
	check(not p.request_action("A1_dash"),"dash cannot skip startup")
	await physics_frames(15)
	check(p.skill_controller.elapsed < p.skill_controller.duration*0.65,"earlier than old skill gate")
	Input.action_press("tp_dash")
	await physics_frames(2)
	Input.action_release("tp_dash")
	eq(p.state,"A1_dash","dash takes over")
	eq(p.soul,66,"paid resource remains spent")
	check(p.cooldowns.orb > 0.0,"paid skill cooldown retained")
	arena.reset_arena()
	await physics_frames(4)
	check(p.request_action("strike2"),"start second strike")
	await physics_frames(9)
	p.cooldowns.parry = 0.5
	check(not p.request_action("parry"),"guard cooldown rejects cancel")
	eq(p.skill_controller.visual_key,"strike2","rejected guard preserves original skill")
	p.cooldowns.parry = 0.0
	check(p.request_action("parry"),"guard cancels skill after release")

func test_defense_cannot_skip_remaining_multi_hits_or_escape_hurt() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("cyclone"),"start multi-hit")
	await physics_frames(10)
	check(not p.request_action("parry"),"guard cannot cancel remaining pulses")
	# 命中定格会暂停角色计时，等待最后一段实际释放而非仅按墙钟推算。
	await physics_frames(34)
	check(p.request_action("parry"),"last pulse opens recovery cancel")
	arena.reset_arena()
	await physics_frames(4)
	check(p.take_damage(1,Vector2(650,540)),"enter real hurt")
	check(not p.request_action("parry"),"guard cannot escape hurt")
	check(not p.request_action("A1_dash"),"dash cannot escape hurt")
