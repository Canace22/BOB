extends TestSuite


func test_front_armor_rear_clasp_and_recovery() -> void:
	var guard := add((load("res://src/chapters/chapter_guard.tscn") as PackedScene).instantiate()) as BurdenGuard
	GameState.set_flag("chapter.challenge")
	guard.facing = -1
	var before := guard.health.current
	check(guard.hurtbox.receive(HitData.create(10, Vector2(-100, 0))), "front contact reports a block")
	eq(guard.health.current, before, "hard shell prevents frontal idle damage")
	check(not guard.hurtbox.allows_combo_link(), "blocked hit cannot count as a successful combo")
	guard.hurtbox.receive(HitData.create(10, Vector2(100, 0)))
	eq(guard.health.current, before - 10, "rear clasp takes damage")
	guard.change("recover")
	guard.hurtbox.receive(HitData.create(10, Vector2(-100, 0)))
	eq(guard.health.current, before - 20, "recovery opens a frontal counterattack window")


func test_damage_window_matches_drawn_contact_frames() -> void:
	var player := add((load("res://src/player/player.tscn") as PackedScene).instantiate()) as Player
	player.set_physics_process(false)
	var guard := add((load("res://src/chapters/chapter_guard.tscn") as PackedScene).instantiate()) as BurdenGuard
	guard.set_physics_process(false)
	for move: String in ["sweep", "slam"]:
		guard.start_tell(move)
		guard._physics_process(guard.tell_duration() - 0.01)
		check(not guard.hitbox.active, "anticipation is harmless")
		eq(guard.frames.current_frame, 3, "last anticipation pose remains before contact")
		guard._physics_process(0.02)
		check(guard.hitbox.active, "damage starts at active phase")
		eq(guard.frames.current_frame, 4, "contact uses the extended claw / fallen shell pose")
		guard._physics_process(guard.active_duration() + 0.01)
		check(not guard.hitbox.active, "damage ends before exposed recovery")
		eq(guard.frames.current_frame, 6, "recovery begins in the drawn recovery pose")


func test_chapter_scenery_and_all_drawn_actions_load() -> void:
	var frames := GuardFrames.new()
	for clip: String in ["idle", "walk", "sweep", "slam", "hit", "retire"]:
		check(frames.textures[clip].size() >= 4, "each action has successive drawn poses")
		for texture: Texture2D in frames.textures[clip]:
			check(texture != null and texture.get_size() == Vector2(512, 512), "registered bitmap is loaded")
	for id: String in ["N01-A", "N01-B", "N02-A", "N02-B"]:
		var room := add((load(WorldGraph.room_path(id)) as PackedScene).instantiate()) as Room
		var backdrop := room.get_node("Scenery/Far/Backdrop") as Sprite2D
		check(backdrop.texture.resource_path.begins_with("res://art/chapters/world/"), "room uses purpose-made chapter scenery")
		check(room.get_node("Scenery").scene_file_path.is_empty(), "room no longer instantiates an old R1 scenery scene")
