extends "res://tests/whalebelly/xumen_layout_routes.gd"
## Declared room/camera fixtures for renderer and pause checks, not route evidence.

func run() -> void:
	label = "visual"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory()))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(RouteCampaign)
	host.set("route_id", label)
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(30)
	for i: int in 7:
		host.load_room(i, [], false)
		host.player_ui.close_all()
		host.reference_follow = true
		await tick(12)
		await shot(str(host.room.id)+"-entry")
		host.zoomed = false
		host.reference_follow = false
		await tick(30)
		check(str(host.room.id)+" actual scene", host.scenery.has_node("LayoutEnvironment"))
		await shot(str(host.room.id)+"-overview")
		var school: ChapterFishGroup = host.scenery.get_node("Middle/School0")
		var fringe: ChapterPinnedBitmap = host.scenery.get_node("Middle/Fringe0")
		var fish: Sprite2D = school.sprites[0]
		var initial: Vector2 = fish.position
		var frame: int = fish.frame
		await tick(45)
		check(str(host.room.id)+" swimming animation and path", fish.position != initial and fish.frame != frame)
		check(str(host.room.id)+" bounded fish count", school.sprites.size() == school.population and school.population<=20)
		paused = true
		var clock_before: float = host.clock
		var fringe_before: float = fringe.elapsed
		var fish_before: Vector2 = fish.position
		await tick(12)
		check(str(host.room.id)+" paused pose", host.clock == clock_before and fringe.elapsed == fringe_before and fish.position == fish_before)
		await shot(str(host.room.id)+"-paused")
		paused = false
		await tick(12)
		check(str(host.room.id)+" resumed pose", host.clock > clock_before and fringe.elapsed > fringe_before)
	var failures: int = checks.filter(func(c: Dictionary) -> bool: return not c["pass"]).size()
	FileAccess.open(output_directory().path_join("visual.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"Room-entry and overview-camera fixtures; actual renderer captures and shared-clock pause/resume. No playthrough or auditory claim."},"\t"))
	print("XUMEN_VISUAL_COMPLETE failed=",failures)
	host.graceful_quit.call_deferred(1 if failures else 0)
