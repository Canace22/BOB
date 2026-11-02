extends TestSuite


func test_chapter_save_isolation_and_restart() -> void:
	GameState.autosave = true
	GameState.set_flag("sentinel.campaign")
	GameState.save_progress()
	var original := FileAccess.get_file_as_string(TEST_SAVE)
	var scene := (load("res://src/chapters/chapter_run.tscn") as PackedScene).instantiate() as ChapterRun
	scene.progress_path = "user://test-chapters.json"
	SaveService.erase(scene.progress_path)
	add(scene)
	await physics_frames(5)
	eq(GameState.current_room, "N01-A", "chapter route starts independently")
	check(scene.player.tuning.prototype_controls, "chapter input uses short-hop and recovery cancellation")
	check(not GameState.has_flag("sentinel.campaign"), "campaign progress not imported")
	GameState.rest_at("N02-B")
	GameState.set_flag("chapter.guard")
	GameState.save_progress()
	var saved := SaveService.read(scene.progress_path)
	eq(saved.checkpoint_room, "N02-B", "chapter checkpoint validates and persists")
	check(saved.flags.has("chapter.guard"), "nonlethal victory persists")
	(scene.get_node("Pause") as ChapterPause).restart()
	await physics_frames(3)
	eq(GameState.current_room, "N01-A", "restart remains in chapter entry")
	check(not GameState.has_flag("chapter.guard"), "restart clears only chapter progress")
	eq(FileAccess.get_file_as_string(TEST_SAVE), original, "campaign sentinel is byte-identical")
	tree.paused = false
	scene.queue_free()
	await tree.process_frame
	eq(GameState.save_path, TEST_SAVE, "previous save context restored")
	check(GameState.has_flag("sentinel.campaign"), "previous flags restored")
	SaveService.erase("user://test-chapters.json")


func test_guard_survives_and_does_not_grant_campaign_ability() -> void:
	var guard := add((load("res://src/chapters/chapter_guard.tscn") as PackedScene).instantiate()) as ChapterEnemy
	check(absf(guard.visual.position.y + guard.visual.texture.get_height() * guard.visual.scale.y / 2.0) < 1.0, "guard sprite feet align with floor")
	GameState.arena_active = true
	guard.health.apply_hit(HitData.create(999, Vector2.ZERO))
	eq(guard.state, "dead", "combat state ends")
	check(guard.visible and guard.visual.modulate.a == 1.0, "surviving guard remains visible")
	check(GameState.has_flag("chapter.guard"), "chapter victory recorded")
	check(not GameState.arena_active, "passage is no longer sealed")
	check(not GameState.has_ability("ability.dash"), "story does not invent an ability reward")
	var revisited := add((load("res://src/chapters/chapter_guard.tscn") as PackedScene).instantiate()) as ChapterEnemy
	await physics_frames(2)
	check(is_instance_valid(revisited) and revisited.state == "dead", "revisiting retains non-hostile guard")


func test_encounter_gate_and_ending_require_their_events() -> void:
	var room := add((load(WorldGraph.room_path("N01-B")) as PackedScene).instantiate()) as Room
	var door := room.get_node("Gameplay/Door_E02") as ChapterDoor
	var resident := room.get_node("Gameplay/Resident") as ChapterMarker
	check(not resident.available(), "resident waits outside unresolved encounter")
	GameState.set_flag("chapter.scavenger.1")
	GameState.set_flag("chapter.scavenger.2")
	check(resident.available(), "both enemies cleared unlock resident response")
	check(not door.denied().is_empty(), "response is distinct from combat completion")
	GameState.set_flag("chapter.resident")
	eq(door.denied(), "", "response opens chapter transition")
	var end_room := add((load(WorldGraph.room_path("N02-B")) as PackedScene).instantiate()) as Room
	var rescue := end_room.get_node("Gameplay/Rescue") as ChapterMarker
	check(not rescue.available(), "cannot skip guard and trigger ending")
	GameState.set_flag("chapter.guard")
	check(rescue.available(), "victory permits rescue sequence")


func test_player_can_interact_with_resident_after_encounter() -> void:
	var scene := (load("res://src/chapters/chapter_run.tscn") as PackedScene).instantiate() as ChapterRun
	scene.progress_path = "user://test-chapters.json"
	SaveService.erase(scene.progress_path)
	add(scene)
	await physics_frames(4)
	var dialogue := scene.get_node("Dialogue") as ChapterDialogue
	while dialogue.visible:
		dialogue.advance()
	scene.change_room("N01-B", "camp")
	await physics_frames(4)
	GameState.set_flag("chapter.scavenger.1")
	GameState.set_flag("chapter.scavenger.2")
	scene.player.position = Vector2(2155, 1088)
	scene.player.interact()
	check(dialogue.visible, "player interaction opens the resident dialogue")
	while dialogue.visible:
		dialogue.advance()
	check(GameState.has_flag("chapter.resident"), "last page completes resident event")
	check(not (scene.room.get_node("Gameplay/Resident") as ChapterMarker).available(), "completed dialogue cannot reopen from the closing input")
	tree.paused = false
	scene.queue_free()
	await tree.process_frame
	SaveService.erase("user://test-chapters.json")
