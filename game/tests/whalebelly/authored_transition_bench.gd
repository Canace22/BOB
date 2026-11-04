extends SceneTree
var host: WhalebellyMain
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var edge: String="E02"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--edge="):edge=arg.trim_prefix("--edge=")
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host
	host.load_room(2 if edge=="E03" else 1,[1917,600 if edge=="E03" else 713]);host.player.controls_enabled=false
	for frame: int in range(100):await process_frame
	var times: Array[float]=[]
	var last: int=Time.get_ticks_usec()
	for frame: int in range(240):
		await process_frame
		var now: int=Time.get_ticks_usec()
		times.append((now-last)/1000.0);last=now
	times.sort()
	var report: Dictionary={"edge":edge,"median_ms":times[120],"p95_ms":times[228],"gpu":RenderingServer.get_video_adapter_name(),"resolution":root.size,"capture":false,"scope":"Warm environment only, no combat or device guarantee"}
	var f:=FileAccess.open("res://build/qa/xumen-transitions/"+edge+"-performance.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"));f.close()
	print("TRANSITION_PERFORMANCE ",JSON.stringify(report))
	await host.graceful_quit()
