extends TestSuite


func after_each() -> void:
	for action: StringName in [&"attack", &"heavy", &"heal", &"jump", &"dash", &"move_left", &"move_right"]:
		Input.action_release(action)
	await super.after_each()


func make_player(prototype: bool = true) -> Player:
	var player := add((load("res://src/player/player.tscn") as PackedScene).instantiate()) as Player
	player.set_physics_process(false)
	player.tuning = player.tuning.duplicate() as PlayerTuning
	player.tuning.prototype_controls = prototype
	return player


func test_cancel_window_and_mainline_opt_in() -> void:
	var player := make_player(false)
	player.actions.begin_attack(player, "short1")
	player.actions.elapsed = 0.12
	check(player.actions.can_jump(player), "mainline keeps existing attack jump")
	player.tuning.prototype_controls = true
	check(not player.actions.can_jump(player), "prototype cannot cancel active attack")
	player.actions.elapsed = 0.199
	check(not player.actions.can_jump(player), "cancel unavailable during active frames")
	player.actions.elapsed = 0.201
	check(player.actions.can_jump(player), "light strike permits jump as soon as active frames end")
	player.actions.begin_attack(player, "heavy")
	player.actions.elapsed = 0.53
	check(not player.actions.can_jump(player), "heavy has longer commitment")
	player.actions.elapsed = 0.55
	check(player.actions.can_jump(player), "heavy permits cancel after 120ms recovery")
	player.tuning.action_buffer = 0.25
	player.actions.begin_attack(player, "short1")
	player.actions.elapsed = 0.18
	check(not player.actions.can_jump(player), "larger buffer never cancels active frames")


func test_combo_buffers_through_active_frames_once() -> void:
	var player := make_player()
	player.actions.begin_attack(player, "short1")
	player.actions.elapsed = 0.10
	player.actions.buffer_input(&"attack")
	player.actions.step(player, 0.01)
	check(not player.actions.combo, "early press waits for the active window")
	player.actions.step(player, 0.02)
	player.actions.step(player, 0.01)
	check(player.actions.combo, "buffered press queues second strike during the first impact")
	player.actions.step(player, 0.27)
	eq(player.actions.attack_kind, "short2", "queued strike consumed at first recovery end")
	check(not player.actions.combo, "second strike clears combo queue")
	player.actions.step(player, 0.51)
	eq(player.actions.mode, "idle", "one press cannot produce a third strike")


func test_dash_cancel_respects_active_frames_and_clears_hitbox() -> void:
	var player := make_player()
	GameState.grant_ability("ability.dash")
	player.actions.begin_attack(player, "short1")
	player.actions.elapsed = 0.13
	player.actions.buffer_input(&"dash")
	player.actions.step(player, 0.01)
	eq(player.actions.mode, "attack", "dash cannot cancel active strike")
	player.actions.elapsed = 0.201
	player.actions.step(player, 0.01)
	eq(player.actions.mode, "dash", "buffered dash cancels as soon as active frames end")
	check(not player.hitbox.active, "cancel cannot leave attack damage active")
	check(player.actions.cooldown > 0 and player.actions.air_dash, "cancel still consumes dash")


func test_short_jump_and_buffered_landing_release() -> void:
	var player := make_player()
	Input.action_press("jump")
	player.locomotion.grounded_time = 0.10
	player.locomotion.step(player, 0.01)
	check(player.velocity.y < -400, "held jump keeps full initial rise")
	Input.action_release("jump")
	player.locomotion.step(player, 0.01)
	check(player.velocity.y > -210 and player.velocity.y < 0, "release cuts rise")
	await tree.process_frame
	player.locomotion.grounded_time = 0.10
	player.locomotion.buffer_jump(player.tuning)
	player.velocity = Vector2.ZERO
	player.locomotion.step(player, 0.01)
	check(player.velocity.y > -210 and player.velocity.y < 0, "released buffered tap becomes short jump")
	eq(player.locomotion.buffered_jump, 0.0, "jump buffer consumed once")


func test_hitstop_queue_priority_and_reset() -> void:
	var player := make_player()
	player.actions.buffer_input(&"heavy")
	player.actions.buffer_input(&"attack")
	Input.action_press("heal")
	player.actions.step(player, 0.01)
	eq(player.actions.attack_kind, "heavy", "first hitstop input takes priority")
	eq(GameState.energy, 2, "one queued action spends once")
	eq(player.actions.queued_input, &"", "hitstop queue consumed")
	Input.action_release("heal")
	player.actions.cooldown = 0.8
	player.actions.air_dash = true
	player.actions.combo = true
	player.actions.buffer_input(&"attack")
	player.locomotion.buffer_jump(player.tuning)
	player.locomotion.grounded_time = 0.1
	player.hitbox.activate(HitData.create(10, Vector2.ZERO))
	player.reset_at(Vector2(300, 500))
	eq(player.actions.mode, "idle", "retry starts idle")
	eq(player.actions.cooldown, 0.0, "retry clears dash cooldown")
	check(not player.actions.air_dash and not player.actions.combo, "retry clears dash and combo")
	eq(player.actions.queued_input, &"", "retry clears input queue")
	eq(player.actions.pending_input, &"", "retry clears recovery input buffer")
	eq(player.locomotion.buffered_jump, 0.0, "retry clears jump buffer")
	eq(player.locomotion.grounded_time, 0.0, "retry clears coyote time")
	check(not player.hitbox.active, "retry clears attack hitbox")


func test_jump_cancel_ends_damage_and_discards_combo() -> void:
	var player := make_player()
	player.actions.begin_attack(player, "short1")
	player.actions.elapsed = 0.27
	player.actions.combo = true
	player.hitbox.activate(HitData.create(10, Vector2.ZERO))
	player.locomotion.grounded_time = 0.10
	Input.action_press("jump")
	player.locomotion.step(player, 0.01)
	eq(player.actions.mode, "idle", "late jump terminates recovery")
	check(not player.hitbox.active and not player.actions.combo, "jump cannot retain damage or queued second strike")
	check(player.velocity.y < -400, "accepted jump actually starts rising")


func ground_player(player: Player) -> void:
	var ground := add(StaticBody2D.new()) as StaticBody2D
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1000, 20)
	shape.shape = rectangle
	shape.position.y = 10
	ground.add_child(shape)
	player.position = Vector2(100, -1)
	await physics_frames(2)
	player.velocity.y = 200
	player.move_and_slide()


func test_same_frame_heavy_and_heal_spends_only_once() -> void:
	var player := make_player()
	await ground_player(player)
	check(player.is_on_floor(), "fixture is grounded so healing is eligible")
	GameState.damage(1)
	await tree.process_frame
	Input.action_press("heavy")
	Input.action_press("heal")
	player.actions.step(player, 0.01)
	eq(player.actions.mode, "attack", "heavy wins simultaneous resource actions")
	eq(GameState.energy, 2, "simultaneous heal does not spend a second time")


func test_damage_protection_prevents_followup_hits_and_restores_control() -> void:
	var player := make_player()
	player.hurtbox.immune = false
	var box := add(Hitbox.new()) as Hitbox
	box.activate(HitData.create(1, player.position + Vector2(50, 0)))
	check(box.try_hit(player.hurtbox), "first strike removes one health")
	eq(GameState.hp, 3, "contact strike cannot remove the whole health bar")
	eq(player.health.current, 3, "runtime and local health stay in sync")
	check(player.velocity.x < -200, "hit pushes the player away from the boss")
	box.activate(HitData.create(1, player.position))
	check(not box.try_hit(player.hurtbox), "separate attack cannot damage during protection")
	player._physics_process(1.1)
	check(player.hurtbox.immune, "protection lasts beyond one second")
	eq(player.actions.mode, "idle", "control returns before damage protection ends")
	check(not box.try_hit(player.hurtbox), "followup is still rejected at 1.1 seconds")
	player._physics_process(0.11)
	check(box.try_hit(player.hurtbox), "next strike can hit after protection ends")
	eq(GameState.hp, 2, "followup costs only one additional health")


func test_recovery_movement_and_mainline_damage_stay_separate() -> void:
	var player := make_player()
	player.actions.begin_attack(player, "short1")
	player.actions.elapsed = 0.21
	Input.action_press("move_right")
	player.locomotion.step(player, 0.01)
	check(is_equal_approx(player.velocity.x, player.tuning.move_speed), "training recovery restores full movement")
	player.tuning.prototype_controls = false
	player.locomotion.step(player, 0.01)
	check(is_equal_approx(player.velocity.x, player.tuning.move_speed * 0.55), "mainline keeps prior recovery movement")
	player.hurtbox.immune = false
	player.hurtbox.receive(HitData.create(1, player.position + Vector2(50, 0)))
	eq(player.invulnerable, player.tuning.invulnerability, "mainline damage protection stays unchanged")
	eq(player.velocity.x, -140.0, "mainline knockback stays unchanged")


func test_expired_attack_input_does_not_fire_after_hurt() -> void:
	var player := make_player()
	player.actions.change("hurt")
	player.actions.buffer_input(&"attack")
	player.actions.step(player, 0.01)
	player.actions.step(player, 0.17)
	player.actions.step(player, 0.01)
	eq(player.actions.mode, "idle", "expired input does not start an unintended attack")
	eq(player.actions.pending_input, &"", "expired recovery buffer clears")


func test_ranged_fires_once_without_melee_hitbox() -> void:
	var player := make_player()
	var shots: Array[bool] = []
	player.actions.ranged_fired.connect(func() -> void: shots.append(true))
	player.actions.begin_attack(player, "ranged")
	player.actions.step(player, 0.13)
	eq(shots.size(), 1, "ranged shot fires at the first active frame")
	check(not player.hitbox.active, "ranged gesture does not also deal melee damage")
	player.actions.step(player, 0.03)
	eq(shots.size(), 1, "remaining active frames cannot emit a second shot")
	player.actions.step(player, 0.25)
	eq(player.actions.mode, "idle", "ranged gesture returns to idle")
	eq(GameState.energy, GameState.MAX_ENERGY, "ranged gesture does not spend melee energy")


func test_ranged_keeps_full_movement_and_launch_facing() -> void:
	var player := make_player()
	await ground_player(player)
	check(player.is_on_floor(), "ranged movement fixture starts grounded")
	player.facing = 1.0
	player.actions.begin_attack(player, "ranged")
	player.actions.elapsed = 0.13
	Input.action_press("move_left")
	player.locomotion.step(player, 0.01)
	check(is_equal_approx(player.velocity.x, -player.tuning.move_speed), "ranged active frames allow full-speed retreat")
	eq(player.facing, 1.0, "ranged keeps its launch direction while retreating")
	player.actions.elapsed = 0.25
	player.locomotion.step(player, 0.01)
	check(is_equal_approx(player.velocity.x, -player.tuning.move_speed), "ranged recovery stays mobile")
