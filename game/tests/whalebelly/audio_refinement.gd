@warning_ignore_start("untyped_declaration")
extends SceneTree
var host: Node2D
var checks: Array = []
func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void: checks.append({"name":label,"pass":passed})
func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate()
	root.add_child(host)
	host.qa=true
	await create_timer(0.4).timeout
	check("three_variants_all_11_events",host.sound_variants.size()==11)
	for id: String in host.sound_variants:
		check(id+"_three_variants",host.sound_variants[id].size()==3)
	for i: int in range(3):
		host.sfx("strike")
		await create_timer(0.15).timeout
	var variants: Array=[]
	for event: Dictionary in host.events:
		if event.event=="sound_voice" and event.data.id=="strike":variants.append(event.data.variant)
	check("rotation_without_immediate_repeat",variants.slice(-3)==[0,1,2])
	host.sfx("jump")
	for i: int in range(12):host.sfx("jump")
	check("same_frame_duplicates_limited",get_nodes_in_group("audio_sfx_jump").size()==1)
	await create_timer(1.0).timeout
	for id: String in host.sound_variants:host.sfx(id)
	check("global_voice_budget_8",get_nodes_in_group("audio_sfx").size()==8)
	await create_timer(1.2).timeout
	check("finished_voices_freed",get_nodes_in_group("audio_sfx").is_empty())
	var ambience: AudioStreamPlayer=host.scenery.get_node("EnvironmentMotion/WaterAmbience")
	check("water_noise_24_second_loop",absf(ambience.stream.get_length()-24.0)<.02 and ambience.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD)
	for room: int in range(7):
		host.load_room(room)
		host.sfx("jump")
		host.sfx("strike")
		await create_timer(0.3).timeout
	var passed: bool=true
	for item: Dictionary in checks:passed=passed and item.pass
	var result: Dictionary={"checks":checks,"pass":passed,"driver":AudioServer.get_driver_name(),"note":"Implementation checks; user listening separately required."}
	# user://whalebelly/ remains writable when this harness targets the exported PCK.
	FileAccess.open("user://whalebelly/audio-refinement-checks.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("AUDIO_REFINEMENT ",JSON.stringify(result))
	await host.graceful_quit()
