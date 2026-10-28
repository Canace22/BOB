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
	eq(GameState.hp, 4, "retry restores health")
