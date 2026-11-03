extends TestSuite


func test_connected_battle_retry_victory_and_resume_preserve_chapter_save() -> void:
	GameState.set_flag("campaign.sentinel")
	GameState.save_progress()
	var original := GameState.to_save_data()
	var flow := ChapterFlow.new()
	flow.progress_path = "user://test-connected-chapters.json"
	var data := ChapterRun.fresh_data()
	data.checkpoint_room = "N02-B"
	data.flags = ["chapter.arrival", "chapter.challenge", "chapter.echo.1", "chapter.latch"]
	SaveService.write(data, flow.progress_path)
	add(flow)
	await physics_frames(5)
	var journey := flow.current as ChapterRun
	eq(journey.player.health.maximum, 6, "chapter uses the same six health capacity")
	journey.player.position.x = 500
	await physics_frames(40)
	check(flow.current is ChapterMotherBattle, "walking beyond the challenge enters the original mother scene")
	var battle := flow.current as ChapterMotherBattle
	if battle == null:
		return
	eq(battle.stage, "fighting", "chapter entry starts the original combat")
	eq(battle.boss.health.maximum, 300, "original mother stats retained")
	check(battle.skills != null, "original ranged and shield system retained")
	battle.player.health.apply_hit(HitData.create(99, Vector2.ZERO))
	eq(battle.stage, "lost", "loss stays in the fight for retry")
	check(SaveService.read(flow.progress_path).flags.has("chapter.echo.1"), "death preserves chapter collection")
	battle.start()
	await physics_frames(35)
	eq(battle.boss.phase, 1, "retry resets original phases")
	battle.boss.health.apply_hit(HitData.create(999, Vector2.ZERO))
	check(SaveService.read(flow.progress_path).flags.has("chapter.mother_victory"), "win persisted before leaving result screen")
	check(battle.boss.visual.modulate.a > 0.9, "chapter victory keeps the mother alive and visible")
	battle.continue_journey()
	await physics_frames(6)
	journey = flow.current as ChapterRun
	check(journey != null and journey.room.room_id == "N02-B", "return continues the same chapter")
	check(journey.player.position.x > 1800, "return places player beside rescue")
	check(GameState.has_flag("chapter.latch") and GameState.has_flag("chapter.echo.1"), "collected progress survives round trip")
	check((journey.room.get_node("Gameplay/Rescue") as ChapterMarker).available(), "victory unlocks rescue")
	flow.queue_free()
	await tree.process_frame
	eq(GameState.to_save_data(), original, "outer campaign context restored")
	eq(GameState.max_hp, 4, "six health does not leak to main campaign")
	SaveService.erase("user://test-connected-chapters.json")


func test_old_chapter_completion_keeps_collections_but_requires_mother() -> void:
	var path := "user://test-chapter-migration.json"
	var data := ChapterRun.fresh_data()
	data.checkpoint_room = "N02-B"
	data.flags = ["chapter.guard", "chapter.complete", "chapter.echo.2", "chapter.latch"]
	SaveService.write(data, path)
	var run := preload("res://src/chapters/chapter_run.tscn").instantiate() as ChapterRun
	run.progress_path = path
	add(run)
	await physics_frames(5)
	check(not GameState.has_flag("chapter.guard") and not GameState.has_flag("chapter.complete"), "old guard cannot count as mother victory")
	check(GameState.has_flag("chapter.echo.2") and GameState.has_flag("chapter.latch"), "optional progress is retained")
	run.queue_free()
	await tree.process_frame
	SaveService.erase(path)
