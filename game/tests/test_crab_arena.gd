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

func test_braced_shell_reports_chips_without_changing_the_advertised_sequence() -> void:
	var boss := arena_scene().boss
	boss.begin()
	var light := HitData.create(10, Vector2.ZERO)
	var shot := HitData.create(24, Vector2.ZERO, true)
	shot.ranged = true
	boss.start_tell("sweep")
	boss.hurtbox.receive(shot)
	eq(boss.health.current, 288, "charged shot chips a braced shell without provoking a melee reply")
	eq(boss.hurtbox.last_result, "shell", "projectile reports shell contact")
	for count in 3:
		boss.hurtbox.receive(light)
	eq(boss.health.current, 282, "each braced light hit chips two")
	eq(light.damage, 10, "bracing does not alter damage for another target")
	eq(boss.sequence, ["sweep"], "repeated chips cannot append an unadvertised attack")
	eq(boss.stagger, 0.0, "glancing blows build no stagger")
	boss.start_active()
	boss.finish_active()
	eq(boss.state, "recover", "the announced single sweep ends in recovery")
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


func test_recovery_is_exposed_after_guard_contact_and_after_a_miss() -> void:
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
	eq(boss.health.current, 290, "a blocked swing still offers full recovery damage")
	eq(boss.stagger, 14.0, "the recovery hit has consistent rewards")
	boss.start_tell("sweep")
	boss.start_active()
	boss.finish_active()
	boss.hurtbox.receive(light)
	eq(boss.health.current, 280, "evading the next attack exposes the same full damage")


func test_resolved_feedback_distinguishes_shell_hit_and_break_and_clears_on_retry() -> void:
	var arena := arena_scene()
	var boss := arena.boss
	var fx := boss.get_node("Effects") as CrabPrototypeEffects
	boss.begin()
	boss.start_tell("sweep")
	boss.hurtbox.receive(HitData.create(10, boss.position + Vector2(-190, 0)))
	eq(boss.hurtbox.last_damage, 2, "feedback reports reduced damage rather than weapon damage")
	eq(fx.received.effect_id, "short2", "shell uses a small deflection arc")
	var shot := HitData.create(12, boss.position + Vector2(-300, -32))
	shot.ranged = true
	boss.hurtbox.receive(shot)
	eq(fx.received.global_position.y, shot.origin.y, "ranged feedback stays at projectile height")
	arena.stage = "fighting"
	arena._hit_feedback(boss.hurtbox.global_position, false)
	eq(arena.freeze_left, 0.018, "shell has only a short tap of hitstop")
	boss.start_active()
	boss.finish_active()
	boss.hurtbox.receive(HitData.create(10, boss.position))
	eq(boss.hurtbox.last_result, "exposed", "recovery reports effective hit")
	eq(boss.hurtbox.last_damage, 10, "effective contact reports full damage")
	eq(fx.received.effect_id, "hit", "effective hit uses authored fragments")
	boss.stagger = 98
	boss.hurtbox.receive(HitData.create(10, boss.position))
	eq(boss.hurtbox.last_result, "break", "threshold-crossing hit has distinct feedback")
	eq(fx.received.effect_id, "heavy", "break uses a larger authored burst")
	arena._hit_feedback(boss.hurtbox.global_position, false)
	eq(arena.freeze_left, 0.09, "break has the strongest hitstop")
	arena.prepare()
	eq(boss.hurtbox.last_result, "", "retry clears the last impact")
	check(not fx.received.visible and not fx.hit_label.visible, "retry clears detached impact and label")


func test_help_auto_folds_and_remains_available_with_pause_or_toggle() -> void:
	var arena := arena_scene()
	var ui := arena.get_node("UI") as CrabArenaUI
	arena.stage = "fighting"
	arena.battle_time = 7
	ui._process(0)
	check(not ui.help_panel.visible, "controls leave the combat area after learning interval")
	ui.toggle_help()
	ui._process(0)
	check(ui.help_panel.visible, "manual expansion overrides automatic folding")
	ui.toggle_help()
	arena.toggle_pause()
	ui._process(0)
	check(ui.help_panel.visible, "pause always makes controls available")
	arena.toggle_pause()
	ui._process(0)
	check(not ui.help_panel.visible, "resume restores compact choice")


func test_deflected_attack_cannot_earn_fast_combo_even_if_shell_opens_later() -> void:
	var arena := arena_scene()
	var boss := arena.boss
	var box := arena.player.hitbox
	boss.start_tell("sweep")
	box.activate(HitData.create(10, Vector2.ZERO))
	check(box.try_hit(boss.hurtbox), "deflection still deals chip damage")
	check(not box.has_landed(), "deflection cannot grant an effective-hit combo")
	boss.start_active()
	boss.finish_active()
	check(not box.has_landed(), "later recovery cannot retroactively confirm the chip")
	box.activate(HitData.create(10, Vector2.ZERO))
	check(box.try_hit(boss.hurtbox) and box.has_landed(), "new recovery contact grants normal fast combo")
