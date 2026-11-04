extends SceneTree
## Compare the parent main.gd and new main.gd under the same GPU scene fixture.
var host: Node2D
var label := "current"
var stress := false

func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--label="): label = arg.trim_prefix("--label=")
		if arg == "--stress": stress = true
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280,720)
	Engine.max_fps = 60
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.qa_full_abilities = true
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	var rows: Array[Dictionary] = []
	for room_index: int in [1,2]:
		host.load_room(room_index)
		for warmup: int in 120: await process_frame
		var intervals: Array[float] = []
		var previous := Time.get_ticks_usec()
		var effects := 0
		for frame_number: int in 240:
			if stress and frame_number % 30 == 0:
				host.player.skill_controller.cancel()
				for key: String in host.player.cooldowns: host.player.cooldowns[key] = 0.0
				host.player.soul = 99
				if host.player.request_action("shadow_orb" if frame_number % 60 == 0 else "abyss_scream"): effects += 1
			await process_frame
			var now := Time.get_ticks_usec()
			intervals.append(float(now-previous)/1000)
			previous = now
		intervals.sort()
		rows.append({"room":host.room.id,"samples":240,"median_ms":intervals[120],"p95_ms":intervals[227],"max_ms":intervals[-1],"effects":effects,
			"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	var out := "res://build/qa/corpse-crab/performance"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	FileAccess.open(out.path_join(label+".json"),FileAccess.WRITE).store_string(JSON.stringify({"label":label,"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"stress":stress,"method":"1280x720 GPU, 60fps cap; same R1-02/03 spawn fixture, 120 warmup + 240 samples; no recording. Stress overrides resources/cooldowns for repeated orb/scream.","rows":rows},"\t"))
	await host.graceful_quit()
