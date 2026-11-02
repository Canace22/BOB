extends TestSuite


func arena_scene() -> CrabArena:
	return add((load("res://src/prototype/crab_arena.tscn") as PackedScene).instantiate()) as CrabArena


func test_training_never_writes_campaign_and_restores_state() -> void:
	GameState.grant_ability("ability.dash")
	GameState.set_flag("boss.r1_shell_crab")
	SaveService.write(GameState.to_save_data(), TEST_SAVE)
	var bytes := FileAccess.get_file_as_bytes(TEST_SAVE)
	var original := GameState.to_save_data()
	GameState.autosave = true
	var arena := arena_scene()
	eq(GameState.hp, 6, "training starts with six health")
	eq(arena.player.health.maximum, 6, "training health capacity stays local to this player")
	check(not GameState.autosave, "training disables all progress writes before children enter")
	check(not arena.dash_enabled and not GameState.has_ability("ability.dash"), "baseline ignores campaign dash")
	arena.toggle_dash()
	check(GameState.has_ability("ability.dash"), "optional dash affects training state only")
	arena.start()
	await physics_frames(35)
	arena.boss.health.apply_hit(HitData.create(999, Vector2.ZERO))
	eq(arena.stage, "won", "boss defeat yields training result")
	eq(arena.boss.state, "dead", "victory preserves defeated visual state")
	eq(FileAccess.get_file_as_bytes(TEST_SAVE), bytes, "campaign bytes unchanged after victory")
	arena.queue_free()
	await tree.process_frame
	eq(GameState.to_save_data(), original, "exit restores prior campaign state")
	eq(GameState.hp, 4, "exit restores campaign four-health state")
	check(GameState.autosave, "prior autosave setting restored")
	GameState.autosave = false


func test_pause_hitstop_and_retry_clear_every_runtime_state() -> void:
	var arena := arena_scene()
	arena.start()
	await physics_frames(35)
	arena.toggle_pause()
	var before := arena.boss.timer
	await physics_frames(8)
	eq(arena.boss.timer, before, "pause freezes boss timeline")
	arena.toggle_pause()
	arena._hit_feedback(Vector2.ZERO, true)
	eq(arena.world.process_mode, Node.PROCESS_MODE_DISABLED, "hitstop freezes both actors")
	arena.player.actions.buffer_input(&"heavy")
	arena.player.locomotion.buffer_jump(arena.player.tuning)
	arena.player.actions.cooldown = 0.8
	arena.boss.phase = 2
	arena.player.health.apply_hit(HitData.create(99, Vector2.ZERO))
	eq(arena.stage, "lost", "death produces immediate retry state")
	arena.start()
	eq(arena.boss.phase, 1, "retry clears phase")
	eq(arena.player.actions.queued_input, &"", "retry clears buffered action")
	eq(arena.player.locomotion.buffered_jump, 0.0, "retry clears jump buffer")
	eq(arena.player.actions.cooldown, 0.0, "retry clears dash cooldown")
	eq(arena.freeze_left, 0.0, "retry clears hitstop")
	check(not arena.player.hitbox.active and not arena.boss.hitbox.active, "retry clears damage")
	eq(GameState.hp, 6, "retry restores training health")
	eq(arena.player.hurtbox.guard, 1, "retry restores the opening guard")

func test_braced_shell_reduces_hits_and_adds_only_one_jumpable_reply() -> void:
	var boss := arena_scene().boss
	boss.begin()
	var light := HitData.create(10, Vector2.ZERO)
	var shot := HitData.create(24, Vector2.ZERO, true)
	shot.ranged = true
	boss.start_tell("sweep")
	boss.hurtbox.receive(shot)
	eq(boss.health.current, 288, "charged shot chips a braced shell without provoking a melee reply")
	eq(boss.hurtbox.glances, 0, "shots cannot queue a riposte")
	for count in 3:
		boss.hurtbox.receive(light)
	eq(boss.health.current, 282, "each braced light hit chips two")
	eq(light.damage, 10, "bracing does not alter damage for another target")
	eq(boss.sequence, ["sweep", "second"], "repeated pressure provokes one low follow-up")
	eq(boss.stagger, 0.0, "glancing blows build no stagger")
	boss.start_active()
	boss.finish_active()
	eq(boss.state, "tell", "the reactive follow-up gives a full warning")
	boss.start_active()
	boss.finish_active()
	boss.hurtbox.receive(light)
	eq(boss.health.current, 272, "recovery takes full damage")
	eq(boss.stagger, 14.0, "recovery hit earns pressure")


func test_only_timed_melee_heavy_stops_slam() -> void:
	var boss := arena_scene().boss
	boss.begin()
	var heavy := HitData.create(24, Vector2.ZERO, true)
	boss.start_tell("slam")
	boss.hurtbox.receive(heavy)
	eq(boss.state, "tell", "early heavy cannot interrupt the raised shell")
	boss.step_ai(0.76)
	heavy.ranged = true
	boss.hurtbox.receive(heavy)
	eq(boss.state, "tell", "charged projectile cannot trigger the melee counter")
	heavy.ranged = false
	boss.hurtbox.receive(heavy)
	eq(boss.state, "stagger", "timed melee hit interrupts before slam contact")
	check(not boss.hitbox.active and boss.sequence.is_empty(), "counter removes queued damage")
	boss.start_tell("slam")
	boss.step_ai(0.76)
	boss.hurtbox.receive(heavy)
	eq(boss.state, "tell", "stagger immunity prohibits repeated interrupts")


func test_only_a_missed_round_exposes_shell_in_recovery() -> void:
	var boss := arena_scene().boss
	boss.begin()
	var light := HitData.create(10, Vector2.ZERO)
	boss.start_tell("sweep")
	boss.start_active()
	boss.target.hurtbox.immune = false
	boss.target.hurtbox.guard = 1
	check(boss.hitbox.try_hit(boss.target.hurtbox), "round actually lands on the player's guard")
	boss.finish_active()
	boss.hurtbox.receive(light)
	eq(boss.health.current, 298, "a blocked swing keeps the shell braced through recovery")
	eq(boss.stagger, 0.0, "trading the shield cannot earn free stagger")
	boss.start_tell("sweep")
	boss.start_active()
	boss.finish_active()
	boss.hurtbox.receive(light)
	eq(boss.health.current, 288, "evading the next attack exposes full recovery damage")
