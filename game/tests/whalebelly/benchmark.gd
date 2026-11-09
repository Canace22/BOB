@warning_ignore_start("untyped_declaration")
extends SceneTree
var host: Node2D
func _init() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	host = load("res://src/campaign/main.gd").new()
	root.add_child(host)
	host.qa = true
	Engine.max_fps = 60
	var report: Dictionary = {"method":"Monotonic wall-clock frame intervals;120warmup+300sample per room","engine":Engine.get_version_info().string,"gpu":RenderingServer.get_video_adapter_name(),"audio_driver":AudioServer.get_driver_name(),"viewport":[1280,720],"frame_cap":60,"target":{"p95_ms_less_than":20,"frames_over50ms":0},"rooms":[],"limitations":["Current workstation and fixed scene sample; not a cross-hardware guarantee or isolated GPU timer.","Explicit Dummy audio used only for performance; hardware audio output not retested."]}
	for index: int in range(7):
		host.load_room(index)
		if host.scenery.get_node_or_null("EnvironmentMotion") == null:
			var effect: Node2D = load("res://src/campaign/environment.gd").new()
			effect.host = host
			effect.name = "EnvironmentMotion"
			host.scenery.add_child(effect)
		host.player.set_physics_process(false)
		for i: int in range(120): await process_frame
		var intervals: Array[float] = []
		var last: int = Time.get_ticks_usec()
		var over25: int = 0
		var over50: int = 0
		var total: float = 0.0
		for i: int in range(300):
			await process_frame
			var now: int = Time.get_ticks_usec()
			var ms: float = float(now-last)/1000.0
			last = now
			intervals.append(ms)
			total += ms
			if ms>25: over25 += 1
			if ms>50: over50 += 1
		intervals.sort()
		var row: Dictionary = {"room":host.room.id,"sample_frames":300,"mean_ms":total/300,"median_ms":intervals[150],"p95_ms":intervals[284],"p99_ms":intervals[296],"max_ms":intervals[-1],"frames_over25ms":over25,"frames_over50ms":over50,"effective_fps":300000.0/total,"texture_vram_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}
		row.pass = float(row.p95_ms)<20 and over50==0
		report.rooms.append(row)
		print("BENCH ",JSON.stringify(row))
		var file: FileAccess = FileAccess.open("res://build/qa/whalebelly/evidence/benchmark.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t"))
	report.all_rooms_passed = true
	for row: Dictionary in report.rooms:
		if not row.pass: report.all_rooms_passed = false
	var final_file: FileAccess = FileAccess.open("res://build/qa/whalebelly/evidence/benchmark.json",FileAccess.WRITE)
	final_file.store_string(JSON.stringify(report,"\t"))
	await host.graceful_quit()
