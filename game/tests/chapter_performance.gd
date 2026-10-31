extends SceneTree
var host: Node2D

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	host = (load("res://content/whalebelly/main.tscn") as PackedScene).instantiate()
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	var rows: Array[Dictionary] = []
	for index in range(7):
		if index>0 and not FileAccess.file_exists("res://content/whalebelly/environment/chapter/R1-0"+str(index+1)+".tscn"): continue
		host.load_room(index)
		for warmup in 120: await process_frame
		var process_times: Array[float] = []
		var frame_times: Array[float] = []
		var previous := Time.get_ticks_usec()
		for sample in 120:
			await process_frame
			var now := Time.get_ticks_usec()
			frame_times.append(float(now-previous)/1000.0)
			previous=now
			process_times.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
		process_times.sort()
		frame_times.sort()
		var row := {"room":host.room.id,"frame_median_ms":frame_times[60],"frame_p95_ms":frame_times[113],"process_p95_ms":process_times[113],"fps":Engine.get_frames_per_second(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"capture":false}
		rows.append(row)
		print("ISOLATED_BENCH ",JSON.stringify(row))
	FileAccess.open("res://build/qa/r1-chapter-scenes/performance.json",FileAccess.WRITE).store_string(JSON.stringify({"rooms":rows,"renderer":RenderingServer.get_video_adapter_name(),"scope":"warm native window; no recording or readback during samples; R1-01 existing baseline"},"\t"))
	await host.graceful_quit()
