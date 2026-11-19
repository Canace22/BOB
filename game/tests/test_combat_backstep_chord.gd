extends TestSuite
## 真实键事件覆盖移动中的反序后跳，防止低优先级位移提前抢走L。

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)

func fixture() -> Node2D:
	var arena: Node2D=preload("res://tests/whitebox_combat/main.tscn").instantiate()
	add(arena)
	await physics_frames(8)
	return arena

func after_each() -> void:
	for code: Key in [KEY_A,KEY_D,KEY_S,KEY_Q,KEY_E,KEY_L,KEY_Z,KEY_SPACE,KEY_SHIFT]: key(code,false)
	await physics_frames(1)
	await super.after_each()

func test_reverse_backstep_waits_while_moving_without_starting_charge() -> void:
	var arena := await fixture()
	key(KEY_D,true)
	await physics_frames(4)
	key(KEY_L,true)
	await physics_frames(2)
	check(not arena.player.skill_controller.active,"moving L must wait for possible backstep")
	check(arena.player.state in ["idle","run"],"movement continues without dash or charge before chord deadline")
	key(KEY_S,true)
	await physics_frames(2)
	check(arena.player.retreating,"D held, L then S must backstep")
	check(float(arena.player.cooldowns.get("wb_charge",0.0))<=0.0,"backstep must not pay charge cooldown")
	eq(arena.player.pending_action,"","no ghost charge queued")

func test_both_backstep_orders_work_in_both_movement_directions() -> void:
	var arena := await fixture()
	for direction: Key in [KEY_A,KEY_D]:
		for reverse: bool in [false,true]:
			arena.reset_arena()
			await physics_frames(4)
			key(direction,true)
			await physics_frames(3)
			key(KEY_L if reverse else KEY_S,true)
			await physics_frames(2)
			key(KEY_S if reverse else KEY_L,true)
			await physics_frames(2)
			check(arena.player.retreating,"both orders backstep while direction held: %s/%s" % [direction,reverse])
			for code: Key in [direction,KEY_S,KEY_L]: key(code,false)

func test_reverse_backstep_cancels_attack_and_hitstop() -> void:
	var arena := await fixture()
	key(KEY_D,true)
	check(arena.player.request_action("wb_flurry"),"start uncancellable attack phase")
	arena.player.hitstop=0.10
	key(KEY_L,true)
	await physics_frames(2)
	key(KEY_S,true)
	await physics_frames(2)
	check(arena.player.retreating,"reverse chord cancels during hitstop")
	check(not arena.player.skill_controller.active,"old attack events cancelled")
	check(arena.player.invulnerable<=0.0,"backstep gains no dash invulnerability")

func test_late_down_does_not_rewrite_launched_charge() -> void:
	var arena := await fixture()
	key(KEY_D,true)
	key(KEY_L,true)
	await physics_frames(9)
	eq(arena.player.skill_controller.visual_key,"wb_charge","deadline without S resolves moving charge")
	key(KEY_S,true)
	await physics_frames(2)
	check(not arena.player.retreating,"late S does not recast spent L")
