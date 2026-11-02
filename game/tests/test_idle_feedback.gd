extends TestSuite


func arena_scene() -> CrabArena:
	return add((load("res://src/prototype/crab_arena.tscn") as PackedScene).instantiate()) as CrabArena


func test_ready_both_directions_hold_full_opacity_and_boss_pose() -> void:
	var arena := arena_scene()
	var player := arena.player
	var visual := player.get_node("Visual") as PlayerVisual
	for facing: float in [-1.0, 1.0]:
		player.facing = facing
		var player_opacities: Dictionary = {}
		var boss_opacities: Dictionary = {}
		var boss_frames: Dictionary = {}
		for tick in 300:
			await physics_frames(1)
			player_opacities[visual.modulate.a] = true
			boss_opacities[arena.boss.visual.modulate.a] = true
			boss_frames[arena.boss.visual.frame_index] = true
		eq(player_opacities, {1.0: true}, "five-second ready view never flashes protected player")
		eq(boss_opacities, {1.0: true}, "ready boss stays fully visible")
		eq(boss_frames, {0: true}, "ready boss holds accepted static idle rather than cycling mismatched redraws")
		eq(visual.animation_snapshot().opacity, 1.0, "read-only snapshot reports actual visual opacity")
		eq(player.invulnerable, 0.0, "training ready does not start the protection timer before combat")


func test_spawn_retry_and_pause_do_not_turn_protection_into_flashing() -> void:
	var arena := arena_scene()
	var visual := arena.player.get_node("Visual") as PlayerVisual
	arena.start()
	eq(arena.player.invulnerable, 0.0, "entering retains the new prepare rule")
	var opacities: Dictionary = {}
	for tick in 60:
		await physics_frames(1)
		opacities[visual.modulate.a] = true
	eq(opacities, {1.0: true}, "entering and spawn protection stay opaque")
	eq(arena.stage, "fighting", "sample is after controls have been enabled")
	check(arena.player.invulnerable > 0 and arena.player.invulnerable <= arena.player.tuning.invulnerability + 0.2, "training grants protection when combat starts, without flashing")
	arena.toggle_pause()
	var before := visual.animation_snapshot()
	await physics_frames(30)
	eq(visual.animation_snapshot(), before, "paused player does not flash or change pose")
	arena.toggle_pause()
	arena.prepare()
	await physics_frames(60)
	eq(visual.modulate.a, 1.0, "retry menu does not retain a flashing state")
	eq(arena.player.invulnerable, 0.0, "retry menu also clears its protection timer until combat starts")
	eq(arena.boss.visual.frame_index, 0, "retry restores stable boss idle")


func test_real_hurt_is_brief_and_death_or_disabled_control_is_opaque() -> void:
	var player := add((load("res://src/player/player.tscn") as PackedScene).instantiate()) as Player
	player.position = Vector2(300, 100)
	var visual := player.get_node("Visual") as PlayerVisual
	player.health.apply_hit(HitData.create(1, Vector2.ZERO))
	var saw_flash := false
	for tick in 16:
		await physics_frames(1)
		saw_flash = saw_flash or visual.modulate.a < 1
	check(saw_flash, "actual health damage retains visible hurt feedback")
	eq(visual.modulate.a, 1.0, "hurt feedback ends with the brief hurt action")
	check(player.invulnerable > 0 and player.hurtbox.immune, "remaining immunity does not continue flashing")
	player.set_physics_process(false)
	var remaining := player.invulnerable
	player.actions.change("idle")
	var stopped_opacities: Dictionary = {}
	for tick in 60:
		await physics_frames(1)
		stopped_opacities[visual.modulate.a] = true
	eq(player.invulnerable, remaining, "disabled parent intentionally retains the protection timer fixture")
	eq(stopped_opacities, {1.0: true}, "a frozen protection timer cannot make another scene's inactive player flash")
	player.actions.change("hurt")
	player.actions.elapsed = 0.04
	await physics_frames(5)
	eq(visual.modulate.a, 1.0, "disabled character cannot keep a stale hurt flash")
	player.set_physics_process(true)
	player.health.apply_hit(HitData.create(99, Vector2.ZERO))
	await physics_frames(12)
	check(player.dead, "lethal damage really reaches death state")
	eq(visual.modulate.a, 1.0, "dead character stays visible instead of flashing forever")
