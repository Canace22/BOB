extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
	var host: Node2D = load("res://scripts/main.gd").new()
	root.add_child(host)
	host.qa = true
	var current: Node2D = host.scenery.get_node("EnvironmentMotion")
	var initial: float = current.ambience.volume_db
	await create_timer(0.45).timeout
	var steady: float = current.ambience.volume_db
	var outgoing: AudioStreamPlayer = current.ambience
	host.load_room(1)
	var reparented: bool = outgoing.get_parent()==host
	await create_timer(0.13).timeout
	var fading: float = outgoing.volume_db if is_instance_valid(outgoing) else -80
	await create_timer(0.22).timeout
	var released: bool = not is_instance_valid(outgoing)
	var report: Dictionary = {"audio_driver":AudioServer.get_driver_name(),"checks":[{"name":"quiet_initial_level","pass":initial<=-79,"db":initial},{"name":"fade_in_to_target","pass":absf(steady+29)<0.1,"db":steady},{"name":"tail_survives_old_room_unload","pass":reparented},{"name":"fade_out_progresses","pass":fading<steady-10,"db":fading},{"name":"tail_freed_after_fade","pass":released}],"note":"Actual runtime envelope and resource lifecycle. Explicit Dummy backend run does not test hardware output."}
	var file: FileAccess = FileAccess.open("res://evidence/environment-fade.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	await host.graceful_quit()
