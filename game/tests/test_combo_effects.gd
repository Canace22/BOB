extends TestSuite


func make_player() -> Player:
	var player := add((load("res://src/player/player.tscn") as PackedScene).instantiate()) as Player
	player.tuning = player.tuning.duplicate() as PlayerTuning
	player.tuning.prototype_controls = true
	player.set_physics_process(false)
	return player


func test_authored_one_shot_preserves_alpha_and_finishes() -> void:
	var fx := add(CombatEffect.new()) as CombatEffect
	for id: String in ["short1", "short2", "heavy", "hit", "sweep", "slam", "charge", "resonance"]:
		fx.play(id, Vector2(100, 80), 120, 0.4, 0.6)
		eq(fx.texture.get_size(), Vector2(1280, 320), "four authored poses load")
		check(fx.texture.get_image().detect_alpha() != Image.ALPHA_NONE, "transparent art remains transparent")
		fx.advance(0.21)
		eq(fx.frame, 2, "time selects the third pose")
		fx.advance(0.20)
		check(not fx.visible, "one shot ends without looping")
	fx.reset()
	eq(fx.effect_id, "", "retry forgets the previous clip")


func test_player_combo_distinguishes_trails_and_cancels() -> void:
	var player := make_player()
	var fx := player.get_node("CombatEffects") as PlayerEffects
	fx.set_physics_process(false)
	player.set_physics_process(true)
	for kind: String in ["short1", "short2", "heavy"]:
		player.actions.begin_attack(player, kind)
		fx._physics_process(0.01)
		check(not fx.trail.visible, "no trail during anticipation")
		player.actions.elapsed = player.actions.attack_active_start()
		player.actions.update_attack(player)
		fx._physics_process(0.01)
		eq(fx.trail.effect_id, kind, "each hit has a distinct authored path")
		check(fx.trail.visible, "trail begins at the damage window")
		player.actions.change("hurt")
		player.hitbox.deactivate()
		fx._physics_process(0.01)
		check(not fx.trail.visible, "interruption clears the weapon trail")
	player.reset_at(Vector2.ZERO)
	eq(fx.swings, 0, "retry clears counters and playback")


func test_contact_burst_requires_landed_hit_and_stays_at_target_surface() -> void:
	var player := make_player()
	var fx := player.get_node("CombatEffects") as PlayerEffects
	var boss := add((load("res://src/enemies/crab_prototype/crab_prototype.tscn") as PackedScene).instantiate()) as CrabPrototype
	boss.position = Vector2(230, 0)
	player.hitbox.activate(HitData.create(10, player.global_position))
	check(not fx.impact.visible, "whiff has no contact burst")
	check(player.hitbox.try_hit(boss.hurtbox), "real target accepts swing")
	eq(fx.hits, 1, "one landed swing emits one burst")
	eq(fx.impact.global_position, Vector2(80, -38), "contact is clamped to the hurt shape, not its ground origin")
	var at := fx.impact.global_position
	player.position.x -= 100
	boss.position.x += 100
	eq(fx.impact.global_position, at, "contact stays in world space")
	check(not player.hitbox.try_hit(boss.hurtbox), "same swing cannot repeat its burst")


func test_boss_moves_phase_victory_and_retry_are_distinct() -> void:
	var player := make_player()
	var boss := add((load("res://src/enemies/crab_prototype/crab_prototype.tscn") as PackedScene).instantiate()) as CrabPrototype
	boss.target = player
	var fx := boss.get_node("Effects") as CrabPrototypeEffects
	for kind: String in ["sweep", "slam", "charge"]:
		boss.start_tell(kind)
		fx._physics_process(0.01)
		check(not fx.dust.visible, "anticipation stays unobscured")
		boss.start_active()
		fx._physics_process(0.01)
		if kind == "charge":
			var first := fx.wake_index
			boss.position.x += 100
			fx._physics_process(0.01)
			check(fx.wake_index > first, "travel emits another detached puff")
			eq(fx.wakes.size(), 3, "pool bounds simultaneous dust")
		else:
			eq(fx.dust.effect_id, kind, "sweep and slam use different art")
			eq(fx.dust.z_index, 1, "ground effects are behind both bodies")
	boss.change("phase")
	fx._physics_process(0.01)
	check(fx.resonance.visible, "phase gets an authored resonance cue")
	check(fx.resonance.modulate.a < 0.5, "phase cue is restrained")
	boss.change("dead")
	fx._physics_process(0.01)
	eq(fx.resonance.global_position, player.global_position + Vector2(0, -100), "victory celebrates the player")
	fx._physics_process(1.7)
	check(not fx.resonance.visible, "victory plays only once")
	boss.reset_at(Vector2.ZERO)
	check(not fx.resonance.visible and not fx.dust.visible, "retry clears celebration and impacts")


func test_world_pause_and_hitstop_freeze_effect_clock() -> void:
	var player := make_player()
	var fx := player.get_node("CombatEffects") as PlayerEffects
	fx.impact.play("hit", Vector2.ZERO, 60, 1.0)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	var before := fx.impact.age
	await tree.physics_frame
	await tree.physics_frame
	eq(fx.impact.age, before, "disabled world used for hitstop cannot advance effects")
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	tree.paused = true
	await tree.process_frame
	eq(fx.impact.age, before, "pause cannot advance effects")
	tree.paused = false
