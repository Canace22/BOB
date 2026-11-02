extends TestSuite


func make_boss() -> CrabPrototype:
	var boss := add((load("res://src/enemies/crab_prototype/crab_prototype.tscn") as PackedScene).instantiate()) as CrabPrototype
	boss.set_physics_process(false)
	boss.visual.set_physics_process(false)
	(boss.get_node("Effects") as CrabPrototypeEffects).set_physics_process(false)
	boss.reset_at(Vector2(600, 500))
	return boss


func test_contact_frames_follow_damage_and_mirror_about_root() -> void:
	var boss := make_boss()
	for kind: String in ["sweep", "slam", "charge"]:
		boss.start_tell(kind)
		boss.timer = CrabMoves.value(kind, "tell") - 0.001
		boss.visual.present(boss)
		var tell_frame := boss.visual.frame_index
		check(not boss.hitbox.active, "anticipation has no damage")
		boss.start_active()
		boss.visual.present(boss)
		check(boss.visual.frame_index > tell_frame, "contact begins with active damage")
		check(boss.hitbox.active, "contact has damage")
		boss.finish_active()
		boss.visual.present(boss)
		check(boss.visual.frame_index >= 8, "recovery uses return poses")
		check(not boss.hitbox.active, "return poses do not damage")
	boss.facing = -1
	boss.visual.present(boss)
	check(boss.visual.scale.x > 0, "left-facing source is not incorrectly mirrored")
	boss.facing = 1
	boss.visual.present(boss)
	check(boss.visual.scale.x < 0, "right-facing mirrors around shared root")
	eq(boss.visual.offset, Vector2(-512, -448), "runtime root preserves source registration")
	for texture: Texture2D in boss.visual.sheets.values():
		eq(texture.get_size(), Vector2(3584, 1536), "each runtime atlas retains exact cells")


func test_death_finishes_once_retry_clears_fade_and_detached_effects() -> void:
	var boss := make_boss()
	var fx := boss.get_node("Effects") as CrabPrototypeEffects
	boss.start_tell("slam")
	boss.start_active()
	fx._physics_process(0.02)
	check(fx.dust.visible, "impact starts authored dust")
	var impact_at := fx.dust.global_position
	boss.position.x += 100
	fx._physics_process(0.02)
	eq(fx.dust.global_position, impact_at, "dust does not slide with boss")
	boss.health.apply_hit(HitData.create(999, Vector2.ZERO))
	boss.visual._physics_process(2)
	eq(boss.visual.frame_index, 11, "death holds final frame")
	eq(boss.visual.modulate.a, 0.0, "death fades without baked scene color")
	boss.reset_at(Vector2(600, 500))
	eq(boss.visual.modulate.a, 1.0, "retry clears death opacity")
	eq(boss.visual.action_id, "01_idle", "retry restores idle")
	check(not fx.dust.visible, "retry clears old impact")


func test_walk_uses_travel_not_wall_clock_and_retry_resets_stride() -> void:
	var boss := make_boss()
	boss.change("observe")
	boss.velocity.x = 90
	boss.position.x += 24
	boss.visual._physics_process(0.1)
	eq(boss.visual.action_id, "10_walk", "displacement selects actual walking artwork")
	eq(boss.visual.frame_index, 2, "24 world pixels advance two stride phases")
	var distance := boss.visual.walk_distance
	boss.visual._physics_process(0.7)
	eq(boss.visual.walk_distance, distance, "held velocity at wall cannot advance gait")
	eq(boss.visual.action_id, "01_idle", "stationary body settles instead of stepping in place")
	boss.position.x += 12
	boss.visual._physics_process(0.01)
	eq(boss.visual.frame_index, 3, "phase follows travelled distance independent of frame delta")
	boss.reset_at(Vector2(700, 500))
	boss.visual._physics_process(0.1)
	eq(boss.visual.walk_distance, 0.0, "retry teleport is not a walking stride")
	boss.start_tell("charge")
	boss.visual.present(boss)
	eq(boss.visual.action_id, "11_charge", "charge uses authored side-view bracing sequence")
