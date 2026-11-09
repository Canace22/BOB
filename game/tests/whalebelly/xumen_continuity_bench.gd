extends SceneTree
## Warm native run, no readback or movie writer during frame samples.
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var host:WhalebellyMain=(load("res://content/whalebelly/main.tscn") as PackedScene).instantiate()
	host.qa=true;host.integration_external_test=true
	root.add_child(host);current_scene=host
	var rows:Array[Dictionary]=[]
	for index in range(7):
		host.load_room(index)
		for frame in 90:await process_frame
		var times:Array[float]=[]
		var last:int=Time.get_ticks_usec()
		for sample in 90:
			await process_frame
			var now:int=Time.get_ticks_usec()
			times.append((now-last)/1000.0);last=now
		times.sort()
		rows.append({"room":host.room.id,"frame_median_ms":times[45],"frame_p95_ms":times[85],"fps":Engine.get_frames_per_second(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"readback":false,"recording":false})
		print("BENCH ",JSON.stringify(rows[-1]))
	FileAccess.open("res://build/qa/xumen-continuity/performance.json",FileAccess.WRITE).store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"rooms":rows},"\t"))
	await host.graceful_quit()
