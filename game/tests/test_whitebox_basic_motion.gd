extends TestSuite
## 地面普攻站定，但不能误锁共用代理的位移技和防御取消。

func fixture() -> Node2D:
	var arena: Node2D = preload("res://tests/whitebox_combat/main.tscn").instantiate()
	add(arena)
	await physics_frames(8)
	return arena

func after_each() -> void:
	for action: String in ["tp_attack","tp_left","tp_right","tp_jump","tp_dash","tp_parry"]: Input.action_release(action)
	await super.after_each()

func test_running_basic_attack_stops_until_end_and_movement_resumes() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	Input.action_press("tp_right")
	await physics_frames(6)
	check(p.velocity.x > 0.0,"running before attack")
	var entry: Dictionary = {}
	# physics_frame等待会先于角色处理恢复，取真实动作进入点而非注入前一帧位置。
	p.animation_tag.connect(func(tag: String) -> void:
		if tag == "strike_01:start": entry["x"] = p.position.x)
	Input.action_press("tp_attack")
	await physics_frames(7)
	Input.action_release("tp_attack")
	check(entry.has("x"),"first swing emitted real start event")
	var start: float = float(entry.get("x",p.position.x))
	check(p.state == "strike_01" and p.state_duration > 0.0,"real first swing starts")
	check(absf(p.position.x-start) < 0.1,"first swing immediately stops running")
	Input.action_release("tp_right")
	Input.action_press("tp_left")
	await physics_frames(8)
	check(absf(p.position.x-start) < 0.1,"held reverse direction cannot slide during swing")
	eq(p.facing,1.0,"existing swing keeps original aim")
	await physics_frames(45)
	check(p.position.x < start-20.0,"held movement resumes after swing ends")

func test_second_basic_swing_is_rooted_but_aims_on_press() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	Input.action_press("tp_left")
	p.facing = -1.0
	check(p.request_action("strike2"),"second swing starts")
	var start: float = p.position.x
	await physics_frames(8)
	check(absf(p.position.x-start) < 0.1,"second swing also stays in place")
	eq(p.skill_controller.locked_facing,-1.0,"second swing keeps chosen direction")

func test_rooted_swing_can_still_cancel_into_defenses() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	Input.action_press("tp_right")
	check(p.request_action("strike_01"),"first swing starts")
	await wait_for_melee_recovery(p)
	var start: float = p.position.x
	check(p.request_action("A1_dash"),"recovery accepts dash")
	await physics_frames(3)
	check(p.position.x > start+10.0,"cancelled swing does not root dash")
	arena.reset_arena()
	await physics_frames(3)
	check(p.request_action("strike_01"),"next swing starts")
	await wait_for_melee_recovery(p)
	check(p.request_action("parry"),"recovery still accepts guard")
	arena.reset_arena()
	await physics_frames(3)
	check(p.request_action("strike_01"),"new swing starts")
	check(p.try_backstep(),"startup still forcibly cancels into backstep")
	start = p.position.x
	await physics_frames(4)
	check(p.position.x < start-10.0,"backstep remains mobile")

func wait_for_melee_recovery(p: CombatWhiteboxPlayer) -> void:
	# 100ms起手与真实hitstop都保留；等待命中尾窗结束，不把固定墙钟帧数当成后摇。
	var edge: float=p.action_trigger_time()+1.0/p.animation_fps
	var dt: float=1.0/Engine.physics_ticks_per_second
	var budget: int=int(ceil((p.state_duration+p.hitstop_duration)/dt))+3
	for i: int in budget:
		if p._offense_released(): break
		await physics_frames(1)
	check(p._offense_released() and p.state_duration>0.0,"actual melee recovery is open before natural end")
	check(p.state_time>=edge-0.00001 and p.state_time<=edge+dt+0.00001,"cancel tested at first legal recovery tick")

func test_mobile_skill_proxy_and_air_attack_keep_motion() -> void:
	var arena := await fixture()
	var p: CombatWhiteboxPlayer = arena.player
	check(p.request_action("wb_drive"),"moving skill sharing strike proxy starts")
	var start: float = p.position.x
	await physics_frames(4)
	check(p.position.x > start+10.0,"triple slash is not rooted by proxy state")
	arena.reset_arena()
	await physics_frames(3)
	check(p.request_action("wb_charge"),"launch starts")
	start = p.position.x
	await physics_frames(3)
	check(p.position.x > start+5.0,"launch also preserves movement")
	arena.reset_arena()
	await physics_frames(3)
	Input.action_press("tp_right")
	Input.action_press("tp_jump")
	await physics_frames(6)
	Input.action_release("tp_jump")
	start = p.position.x
	Input.action_press("tp_attack")
	await physics_frames(4)
	Input.action_release("tp_attack")
	check(p.position.x > start+5.0 and p.position.y < 540,"air attack preserves horizontal motion and gravity")
