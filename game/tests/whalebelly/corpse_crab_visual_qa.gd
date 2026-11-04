extends SceneTree
## Explicit presentation fixture in the real R1-02 scene; not a keyboard fight.
var host: WhalebellyMain
var out := "res://build/qa/corpse-crab/native"

func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	host.load_room(1)
	for i: int in 25: await physics_frame
	host.set_process(false)
	host.player.set_physics_process(false)
	host.player.hide()
	host.player_ui.hide()
	host.camera.set_process(false)
	host.camera.set_physics_process(false)
	host.camera.position_smoothing_enabled = false
	var crab: CampaignCorpseCrab = host.enemies[0].actor
	crab.set_physics_process(false)
	host.camera.position = crab.position+Vector2(0,-120)
	host.camera.zoom = Vector2(2,2)
	host.camera.reset_smoothing()
	var evidence: Array[Dictionary] = []
	for direction: float in [-1.0,1.0]:
		crab.facing = direction
		for action: String in ["idle","walk","tell","active","recover","hurt","dead"]:
			var duration := 1.2 if action in ["idle","walk"] else float(CampaignCorpseCrab.TIMES.get(action,.8))
			var frames := maxi(8,ceili(duration*30))
			crab.state = "idle" if action == "walk" else action
			crab.moving = action == "walk"
			var observed: Array[int] = []
			for frame_number: int in frames:
				crab.timer = float(frame_number)/frames*duration
				crab.idle_clock = crab.timer
				crab.walk_distance = float(frame_number)/frames*40
				crab.visual.present(crab)
				if not observed.has(crab.visual.frame_index): observed.append(crab.visual.frame_index)
				await process_frame
				if frame_number == frames/2:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(out.path_join(action+str(int(direction))+".png"))
			evidence.append({"action":action,"facing":direction,"frames":observed,"texture":crab.visual.texture.resource_path})
	FileAccess.open(out.path_join("coverage.json"),FileAccess.WRITE).store_string(JSON.stringify({"method":"GPU main-scene pose fixture; both directions; no natural input claim","actions":evidence},"\t"))
	await host.graceful_quit()
