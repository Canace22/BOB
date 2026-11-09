@warning_ignore_start("untyped_declaration")
class_name WhalebellyMotionPreview
extends Node2D
## Pure scene display. Camera has an authored track; no character controller.
@export var demonstration_camera: bool=false
@export var duration: float=64.0
var elapsed: float=0.0
var intervals: Array[float]=[]
var last_tick: int=0
var screenshot_done: Dictionary={}
var playing: bool=true
var stop_after_capture: bool=false
var capture_enabled: bool=false
var evidence_directory: String="res://build/qa/whalebelly/evidence/motion_elements/"
@onready var environment: Node2D=$ReferenceEnvironment
@onready var camera: Camera2D=$Camera2D
func _ready() -> void:
	demonstration_camera="--camera-demo" in OS.get_cmdline_user_args()
	stop_after_capture=OS.has_feature("movie") or "--benchmark" in OS.get_cmdline_user_args()
	capture_enabled=stop_after_capture or "--capture-preview" in OS.get_cmdline_user_args()
	if not FileAccess.file_exists("res://project.godot"):evidence_directory="user://whalebelly/environment_evidence/"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="):evidence_directory=arg.trim_prefix("--evidence-dir=").trim_suffix("/")+"/"
	if capture_enabled:DirAccess.make_dir_recursive_absolute(evidence_directory)
	if demonstration_camera:duration=32.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--duration="):duration=clampf(float(arg.trim_prefix("--duration=")),10.0,180.0)
	environment.set_process(false)
	environment.level_mode=true # Camera input only. Display character was already retained by _ready.
	last_tick=Time.get_ticks_usec()
func _process(delta: float) -> void:
	var now:=Time.get_ticks_usec()
	if elapsed>1.0:intervals.append(float(now-last_tick)/1000.0)
	last_tick=now
	if playing:elapsed+=delta
	environment.elapsed=elapsed
	var offset:=Vector2.ZERO
	if demonstration_camera:
		offset=Vector2(sin(elapsed*TAU/32.0)*65.0,sin(elapsed*TAU/32.0)*10.0)
		camera.zoom=Vector2.ONE*1.16
	camera.position=Vector2(640,360)+offset
	environment.level_camera_offset=offset
	environment.update_visuals()
	for second: int in [0,2,8,16,24,32,48,63]:
		if capture_enabled and elapsed>=second and not screenshot_done.has(second):
			screenshot_done[second]=true
			capture(second)
	if stop_after_capture and elapsed>=duration:
		set_process(false)
		intervals.sort()
		var suffix: String="camera" if demonstration_camera else "fixed"
		var report: Dictionary={"seconds":elapsed,"frames":intervals.size(),"frame_ms_p50":intervals[int(intervals.size()*0.5)],"frame_ms_p95":intervals[int(intervals.size()*0.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"renderer":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"movie_mode":OS.has_feature("movie"),"bubble_count":environment.bubbles.size(),"recycles":environment.recycled,"note":"Movie-writer frame time is capture throughput, not real-time game FPS."}
		FileAccess.open(evidence_directory+("movie-" if OS.has_feature("movie") else "live-")+suffix+"-runtime.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
		print("MOTION_RUNTIME ",JSON.stringify(report))
		get_tree().quit()
func capture(second: int) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence_directory+("camera" if demonstration_camera else "fixed")+"-%02d.png"%second)
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_SPACE:playing=not playing
		if event.keycode==KEY_C:
			demonstration_camera=not demonstration_camera
			if not demonstration_camera:camera.zoom=Vector2.ONE
