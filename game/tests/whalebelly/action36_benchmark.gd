extends SceneTree
## Native warm baseline/after comparison; no screenshots or recording during samples.
var host: Node2D
var output: String = "res://build/qa/action36"
var label: String = "baseline"
var stress: bool = false

func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--label="): label = arg.trim_prefix("--label=")
		if arg == "--stress": stress = true
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280, 720)
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	host = (load("res://content/whalebelly/main.tscn") as PackedScene).instantiate()
	host.qa = true
	host.qa_full_abilities = true
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	var rows: Array[Dictionary] = []
	for room_id: int in [0, 3]:
		host.load_room(room_id)
		for warmup: int in 120: await process_frame
		var intervals: Array[float] = []
		var effects_started: int = 0
		var start: int = Time.get_ticks_usec()
		for sample: int in 240:
			if stress and sample % 30 == 0:
				host.player.skill_controller.cancel()
				for cooldown_key: String in host.player.cooldowns: host.player.cooldowns[cooldown_key] = 0.0
				host.player.soul = 99
				if host.player.request_action("shadow_orb" if sample % 60 == 0 else "abyss_scream"): effects_started += 1
			await process_frame
			var now: int = Time.get_ticks_usec()
			intervals.append(float(now - start) / 1000.0)
			start = now
		intervals.sort()
		var row: Dictionary = {"room":host.room.id, "samples":intervals.size(), "median_ms":intervals[120], "p95_ms":intervals[227], "max_ms":intervals[-1], "texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED), "draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC), "static_memory_peak_bytes":Performance.get_monitor(Performance.MEMORY_STATIC_MAX)}
		row["effects_started"] = effects_started
		row["camera_following"] = host.camera.was_following
		row["camera_zoom"] = host.camera.zoom.x
		rows.append(row)
		print("ACTION36_BENCH ", JSON.stringify(row))
	var report: Dictionary = {"label":label, "engine":Engine.get_version_info().string, "gpu":RenderingServer.get_video_adapter_name(), "scope":"1280x720 native GPU; 120 warmup + 240 measured frames per room; no screenshot/movie during measurement; QA save only", "stress":stress, "stress_method":"Repeated orb and scream every 30 rendered frames; resource and cooldown overridden only for load testing" if stress else "none", "rooms":rows}
	FileAccess.open(output.path_join(label + "-performance.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	await host.graceful_quit()
