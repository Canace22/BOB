extends SceneTree
var host: WhalebellyMain
func _initialize() -> void:call_deferred("run")
func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host
	var results: Array[Dictionary]=[]
	for sample: Dictionary in [{"id":"E01","room":0,"pos":[1900,632]},{"id":"hub","room":1,"pos":[600,663]},{"id":"E35","room":1,"pos":[1710,-270]}]:
		host.load_room(sample.room,sample.pos);host.player.controls_enabled=false
		for frame: int in range(90):await process_frame
		var frames: Array[float]=[]
		var previous: int=Time.get_ticks_usec()
		for frame: int in range(180):
			await process_frame
			var now: int=Time.get_ticks_usec()
			frames.append((now-previous)/1000.0);previous=now
		frames.sort()
		results.append({"scene":sample.id,"median_ms":frames[90],"p95_ms":frames[171],"fps":Engine.get_frames_per_second(),"chunks":host.connected_world.chunks.size()})
	var f:=FileAccess.open("res://build/qa/xumen-connected/performance.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"device":RenderingServer.get_video_adapter_name(),"renderer":"Compatibility","capture":false,"resolution":root.size,"samples":results,"scope":"warm environmental scene, player input disabled; not a combat or cross-device guarantee"},"\t"));f.close()
	print("CONNECTED_PERFORMANCE ",JSON.stringify(results))
	await host.graceful_quit()
