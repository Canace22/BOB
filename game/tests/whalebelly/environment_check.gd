@warning_ignore_start("untyped_declaration")
extends SceneTree
var host: Node2D
var effect: Node2D

func _init() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280,720)
	host = load("res://src/campaign/main.gd").new()
	root.add_child(host)
	host.load_room(0)
	effect = host.scenery.get_node_or_null("EnvironmentMotion")
	if effect == null:
		effect = load("res://src/campaign/environment.gd").new()
		effect.host = host
		effect.name = "EnvironmentMotion"
		host.scenery.add_child(effect)
	var report: Dictionary = {"checks":[],"method":"Graphical Godot actual runtime environment instance"}
	for i: int in range(150): await process_frame
	report.initial = effect.runtime_report()
	var expected_fish: int = 0 if int(host.room_index) in [4,5] else 7
	report.checks.append({"name":"populations","pass":effect.bubbles.size()==18 and effect.dust.size()==28 and effect.fish.size()==expected_fish,"expected_fish":expected_fish})
	report.checks.append({"name":"audio_running","pass":effect.ambience.playing,"note":"Playback state; no subjective listening claim"})
	var first: float = effect.phase
	paused = true
	for i: int in range(15): await process_frame
	report.checks.append({"name":"pause_halts_time_and_audio","pass":effect.phase==first and effect.ambience.stream_paused})
	paused = false
	for i: int in range(15): await process_frame
	report.checks.append({"name":"resume_advances_time","pass":effect.phase>first and not effect.ambience.stream_paused})
	host.record_event("checkpoint",{})
	for i: int in range(3): await process_frame
	report.checks.append({"name":"event_pulse","pass":effect.pulses.size()>0})
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/qa/whalebelly/evidence/environment-running.png")
	var frames: int = 0
	var sum_ms: float = 0.0
	var max_ms: float = 0.0
	while frames<120:
		await process_frame
		var ms: float = float(Performance.get_monitor(Performance.TIME_PROCESS))*1000
		sum_ms += ms
		max_ms = maxf(max_ms,ms)
		frames += 1
	report.process_sample = {"frames":frames,"mean_ms":sum_ms/frames,"max_ms":max_ms,"note":"whole running scene process monitor; not GPU frametime benchmark"}
	host.capture_path = "freeze-only"
	for i: int in range(3): await process_frame
	report.checks.append({"name":"reference_capture_hides_effects","pass":not effect.visible and effect.ambience.stream_paused})
	host.capture_path = ""
	var path: String = "res://build/qa/whalebelly/evidence/environment-check.json"
	var output: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	effect.ambience.stream.save_to_wav("res://build/qa/whalebelly/evidence/environment-ambience.wav")
	print(JSON.stringify(report))
	host.queue_free()
	await process_frame
	await process_frame
	quit()
