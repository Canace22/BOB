extends TestSuite


func after_each() -> void:
	Input.action_release("heal")
	Input.action_release("ranged")
	await super.after_each()


func make_skills() -> TrainingSkills:
	var world := add(Node2D.new()) as Node2D
	var player := (load("res://src/player/player.tscn") as PackedScene).instantiate() as Player
	world.add_child(player)
	player.set_physics_process(false)
	player.tuning = player.tuning.duplicate() as PlayerTuning
	player.tuning.prototype_controls = true
	var skills := TrainingSkills.new()
	player.add_child(skills)
	skills.set_physics_process(false)
	skills.reset()
	return skills


func make_target() -> Hurtbox:
	var health := add(Health.new()) as Health
	health.maximum = 200
	health.restore()
	var target := add(Hurtbox.new()) as Hurtbox
	target.health = health
	return target


func test_ranged_moves_and_hits_without_melee_or_energy_cost() -> void:
	var skills := make_skills()
	var player := skills.player
	check(skills.try_cast(), "training accepts ranged input from idle")
	check(not skills.try_cast(), "cooldown rejects a duplicate cast")
	eq(skills.shots_fired, 0, "projectile waits for the visible gesture")
	player.actions.step(player, 0.13)
	eq(skills.shots_fired, 1, "active frame creates one projectile")
	eq(GameState.energy, GameState.MAX_ENERGY, "ranged attack is independent of melee energy")
	check(not player.hitbox.active, "ranged gesture has no hidden melee damage")
	var projectile := skills.projectiles[0]
	projectile.set_physics_process(false)
	var start := projectile.position.x
	projectile._physics_process(0.4)
	check(projectile.position.x > start + 200, "shot travels beyond the short melee reach")
	var target := make_target()
	check(projectile.try_hit(target), "traveling shot can damage the target")
	eq(target.health.current, 188, "shot deals twelve damage")
	eq(skills.ranged_hits, 1, "landed ranged attack is observable")
	eq(skills.shield_charge, 0, "ranged hit does not charge the melee passive")
	check(not projectile.active, "shot deactivates after one target")
	check(not projectile.try_hit(target), "shot cannot hit the same target twice")


func test_opening_guard_consumes_swing_and_protects_followups() -> void:
	var skills := make_skills()
	var player := skills.player
	var box := add(Hitbox.new()) as Hitbox
	box.activate(HitData.create(1, player.position + Vector2(100, 0)))
	check(box.try_hit(player.hurtbox), "opening shield accepts the first strike")
	eq(player.hurtbox.guard, 0, "first strike consumes one shield")
	eq(skills.blocks, 1, "block feedback is emitted once")
	eq(GameState.hp, 4, "shield prevents runtime health loss")
	eq(player.health.current, 4, "shield prevents local health loss")
	check(not box.try_hit(player.hurtbox), "same swing cannot hit after breaking the shield")
	box.activate(HitData.create(1, player.position))
	player._physics_process(1.1)
	check(not box.try_hit(player.hurtbox), "shield protection rejects a followup for more than one second")
	player._physics_process(0.11)
	check(box.try_hit(player.hurtbox), "later unguarded strike deals normal damage")
	eq(GameState.hp, 3, "later strike costs exactly one health")


func test_melee_rebuilds_guard_and_ranged_does_not() -> void:
	var skills := make_skills()
	var player := skills.player
	var target := make_target()
	player.hurtbox.guard = 0
	var ranged := HitData.create(12, Vector2.ZERO)
	ranged.ranged = true
	skills._melee_hit(target, ranged)
	eq(skills.shield_charge, 0, "ranged classification cannot charge the passive")
	for i in 3:
		player.hitbox.activate(HitData.create(10, Vector2.ZERO))
		check(player.hitbox.try_hit(target), "distinct landed melee swing contributes")
	eq(skills.shield_charge, 3, "three light hits accumulate three charges")
	eq(player.hurtbox.guard, 0, "partial charge is not a shield")
	player.hitbox.activate(HitData.create(10, Vector2.ZERO))
	player.hitbox.try_hit(target)
	eq(player.hurtbox.guard, 1, "four landed light hits restore a shield")
	eq(skills.shield_charge, 0, "restoring shield consumes accumulated charge")
	player.hitbox.activate(HitData.create(24, Vector2.ZERO, true))
	player.hitbox.try_hit(target)
	eq(skills.shield_charge, 0, "active shield cannot stockpile a second shield")
	player.hurtbox.guard = 0
	for i in 2:
		player.hitbox.activate(HitData.create(24, Vector2.ZERO, true))
		player.hitbox.try_hit(target)
	eq(player.hurtbox.guard, 1, "two landed heavy hits restore a shield")


func test_range_reset_and_mainline_opt_in() -> void:
	var skills := make_skills()
	var player := skills.player
	check(skills.try_cast(), "training can start a shot")
	player.actions.step(player, 0.13)
	var projectile := skills.projectiles[0]
	projectile.set_physics_process(false)
	projectile._physics_process((ResonanceProjectile.RANGE + 1) / ResonanceProjectile.SPEED)
	check(not projectile.active and projectile.is_queued_for_deletion(), "shot expires at its finite range")
	player.actions.change("idle")
	skills.cooldown = 0
	check(skills.try_cast(), "next ready cast is accepted")
	player.actions.step(player, 0.13)
	var retry_projectile := skills.projectiles.back() as ResonanceProjectile
	skills.shield_charge = 3
	player.hurtbox.guard = 0
	skills.reset()
	eq(skills.projectiles.size(), 0, "retry forgets active projectiles")
	check(not retry_projectile.active and retry_projectile.is_queued_for_deletion(), "retry disables damage before deleting old shots")
	eq(skills.cooldown, 0.0, "retry clears ranged cooldown")
	eq(skills.shield_charge, 0, "retry clears partial guard progress")
	eq(player.hurtbox.guard, 1, "retry restores opening guard")
	eq(skills.shots_fired, 0, "retry clears combat counters")
	player.actions.change("idle")
	player.tuning.prototype_controls = false
	check(not skills.try_cast(), "mainline controls cannot invoke training ranged skill")


func test_freed_projectiles_do_not_break_next_cast_or_cleanup() -> void:
	var skills := make_skills()
	var player := skills.player
	check(skills.try_cast(), "first cast starts normally")
	player.actions.step(player, 0.13)
	var first := skills.projectiles[0]
	first.queue_free()
	await tree.process_frame
	check(not is_instance_valid(first), "fixture frees the projectile before the next cast")
	eq(skills.projectiles.size(), 1, "fixture retains the stale reference until cleanup")
	var before := skills.snapshot()
	eq(before.projectiles.size(), 0, "snapshot safely skips a freed projectile before filtering")
	player.actions.change("idle")
	skills.cooldown = 0
	check(skills.try_cast(), "second cast is accepted after the first projectile is freed")
	player.actions.step(player, 0.13)
	eq(skills.shots_fired, 2, "second cast actually emits another projectile")
	eq(skills.projectiles.size(), 1, "second cast removes the stale projectile reference")
	check(is_instance_valid(skills.projectiles[0]), "remaining projectile is a live object")
	var active := skills.snapshot()
	eq(active.projectiles.size(), 1, "snapshot reports the new active projectile")
	var second := skills.projectiles[0]
	second.queue_free()
	await tree.process_frame
	check(not is_instance_valid(second), "cleanup fixture contains a truly freed reference")
	skills.clear_projectiles()
	eq(skills.projectiles.size(), 0, "clear safely removes freed references before a later cast")
	eq(skills.snapshot().projectiles.size(), 0, "snapshot is safe after cleanup")


func test_training_heal_can_restore_the_sixth_health() -> void:
	var arena := add((load("res://src/prototype/crab_arena.tscn") as PackedScene).instantiate()) as CrabArena
	arena.start()
	await physics_frames(35)
	arena.boss.stop()
	arena.player.set_physics_process(false)
	check(arena.player.is_on_floor(), "healing fixture is grounded")
	GameState.hp = 5
	arena.player.health.restore(5)
	# Leave the physics-frame signal callback before injecting a fresh input edge.
	await tree.process_frame
	Input.action_press("heal")
	check(Input.is_action_just_pressed("heal"), "healing fixture supplies a fresh input press")
	check(arena.player.actions.is_free(), "healing fixture has no competing action")
	arena.player.actions.step(arena.player, 0.01)
	Input.action_release("heal")
	eq(arena.player.actions.mode, "heal", "five of six health can begin healing")
	arena.player.actions.step(arena.player, arena.player.tuning.heal_duration)
	eq(GameState.hp, 6, "training can heal back to six")
	eq(arena.player.health.current, 6, "healing keeps both health stores synchronized")
	eq(GameState.energy, 2, "training heal retains its normal cost")

func test_confirmed_light_links_heavy_before_whiff_recovery() -> void:
	var player := make_skills().player
	var target := add(Hurtbox.new()) as Hurtbox
	target.health = add(Health.new()) as Health
	player.actions.begin_attack(player, "short1")
	player.actions.step(player, 0.13)
	player.actions.buffer_input(&"heavy")
	player.actions.step(player, 0.08)
	eq(player.actions.attack_kind, "short1", "a whiff cannot skip recovery")
	eq(GameState.energy, 4, "whiff does not spend finisher energy")
	player.actions.begin_attack(player, "short1")
	player.actions.step(player, 0.13)
	check(player.hitbox.try_hit(target), "light hits a real hurtbox")
	player.actions.buffer_input(&"heavy")
	player.actions.step(player, 0.08)
	player.actions.step(player, 0.01)
	eq(player.actions.attack_kind, "heavy", "confirmed light cancels recovery into heavy")
	eq(GameState.energy, 2, "linked heavy spends energy once")
