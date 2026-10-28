extends SceneTree
var host: Node2D
var captured: PackedVector2Array = PackedVector2Array()
var capture: AudioEffectCapture
func _init() -> void: call_deferred("run")
func take_buffer() -> void:
	var count: int = capture.get_frames_available()
	if count>0: captured.append_array(capture.get_buffer(count))
func capture_for(seconds: float) -> void:
	var finish: int = Time.get_ticks_msec()+int(seconds*1000.0)
	while Time.get_ticks_msec()<finish:
		await process_frame
		take_buffer()
func metrics(buffer: PackedVector2Array) -> Dictionary:
	var peak: float = 0.0
	var energy: float = 0.0
	var clipped: int = 0
	var nonzero: int = 0
	var crossings: int = 0
	var previous: float = 0.0
	for frame: Vector2 in buffer:
		peak = maxf(peak,maxf(absf(frame.x),absf(frame.y)))
		energy += frame.x*frame.x+frame.y*frame.y
		if absf(frame.x)>=0.999 or absf(frame.y)>=0.999: clipped += 1
		if absf(frame.x)>0.000001 or absf(frame.y)>0.000001: nonzero += 1
		if (previous<0 and frame.x>=0) or (previous>=0 and frame.x<0): crossings += 1
		previous = frame.x
	return {"frames":buffer.size(),"peak":peak,"rms":sqrt(energy/maxi(1,buffer.size()*2)),"clipped_frames":clipped,"nonzero_frames":nonzero,"zero_crossings":crossings}
func run() -> void:
	var evidence_dir: String = "res://evidence"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--audio-evidence="): evidence_dir = arg.trim_prefix("--audio-evidence=")
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	root.size = Vector2i(1280,720)
	host = load("res://scripts/main.gd").new()
	root.add_child(host)
	host.qa = true
	host.load_room(0)
	if host.scenery.get_node_or_null("EnvironmentMotion") == null:
		var effect: Node2D = load("res://scripts/environment.gd").new()
		effect.host = host
		effect.name = "EnvironmentMotion"
		host.scenery.add_child(effect)
	AudioServer.set_bus_mute(0,false)
	capture = AudioEffectCapture.new()
	capture.buffer_length = 0.5
	var slot: int = AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0,capture)
	await capture_for(1.5)
	var ambient: Dictionary = metrics(captured)
	captured.clear()
	for id: String in ["jump","dash","strike","hit","hurt","slam","collect","save"]:
		host.sfx(id)
		await capture_for(0.4)
	await capture_for(1.0)
	var mix: Dictionary = metrics(captured)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(captured.size()*4)
	for i: int in range(captured.size()):
		bytes.encode_s16(i*4,int(clampf(captured[i].x,-1,1)*32767))
		bytes.encode_s16(i*4+2,int(clampf(captured[i].y,-1,1)*32767))
	var wave: AudioStreamWAV = AudioStreamWAV.new()
	wave.mix_rate = int(AudioServer.get_mix_rate())
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.stereo = true
	wave.data = bytes
	wave.save_to_wav(evidence_dir.path_join("master-audio-capture.wav"))
	var report: Dictionary = {"method":"Godot AudioEffectCapture on Master; real event playback and ambience","audio_driver":AudioServer.get_driver_name(),"mix_rate":AudioServer.get_mix_rate(),"ambient":ambient,"mixed_events":mix,"checks":[{"name":"ambient_nonzero","pass":ambient.nonzero_frames>1000 and ambient.rms>0.00001},{"name":"event_mix_nonzero","pass":mix.nonzero_frames>1000 and mix.rms>0.0001},{"name":"no_clipping","pass":ambient.clipped_frames==0 and mix.clipped_frames==0},{"name":"time_varying_waveform","pass":mix.zero_crossings>50}],"limitations":["Digital mixer output measured; physical speaker routing and subjective listening not assessed."]}
	report.output_device = AudioServer.output_device
	report.output_devices = AudioServer.get_output_device_list()
	var file: FileAccess = FileAccess.open(evidence_dir.path_join("audio-mixer.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	AudioServer.remove_bus_effect(0,slot)
	await host.graceful_quit()
