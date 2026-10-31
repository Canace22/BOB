@warning_ignore_start("untyped_declaration")
class_name WhalebellyReferenceEnvironment
extends Node2D
## A reference-only environmental study. No player, gameplay or persistent state.
@export var animate_environment: bool = true
@export var camera_drift: bool = false
@export var level_mode: bool = false
var level_host: Node2D
var level_camera_offset: Vector2 = Vector2.ZERO
@export_range(0.0, 1.0) var motion_strength: float = 1.0
var elapsed: float = 0.0
var frames: int = 0
var bases: Dictionary = {}
var bubbles: Array[Dictionary] = []
var timings: Array[float] = []
var last_tick: int = 0
var qa: bool = false
var still: bool = false
var recycled: int = 0
const EVIDENCE = "res://build/qa/whalebelly/evidence/motion_elements/"
var evidence_directory: String = EVIDENCE
const REGIONS = [Rect2(143,170,89,220), Rect2(414,310,72,98), Rect2(786,119,154,282), Rect2(1036,358,95,128)]

func _ready() -> void:
	var args = OS.get_cmdline_user_args()
	qa = not level_mode and "--qa" in args
	still = not level_mode and "--static" in args
	if not FileAccess.file_exists("res://project.godot"): evidence_directory="user://whalebelly/environment_evidence/"
	if qa or still: DirAccess.make_dir_recursive_absolute(evidence_directory)
	if still: animate_environment = false
	if "--pan" in args: camera_drift = true
	for child in get_children():
		if child is Sprite2D: bases[child.name] = child.position
		if str(child.name).begins_with("BUBBLE-ZONE"):
			bubbles.append_array(child.bubbles)
	if level_mode:
		var display = get_node("CHARACTER")
		bases.erase(display.name)
		remove_child(display)
		display.queue_free()
	update_visuals()

func update_visuals() -> void:
	var pan = level_camera_offset if level_mode else (Vector2(sin(elapsed*TAU/24.0)*45.0,sin(elapsed*TAU/24.0)*8.0) if camera_drift else Vector2.ZERO)
	recycled=0
	for child in get_children():
		if str(child.name).begins_with("BUBBLE-ZONE"):
			child.update_at(elapsed)
			recycled+=child.recycled
		elif child.has_method("update_at"):
			child.update_at(elapsed,pan)
		elif child is Sprite2D:
			var amount=0.0
			# The far underpaint fills exposed edges; holes in the depth matte remain anchored.
			if str(child.name)=="ENV-UNDERPAINT": amount=0.14
			if str(child.name).begins_with("MID"): amount=0.045
			child.position=bases[child.name]+pan*amount

func _process(delta: float) -> void:
	if level_mode and is_instance_valid(level_host):
		visible = not level_host.reference_visible
		if not visible or level_host.layer_solo >= 0 or not level_host.capture_path.is_empty(): return
	var tick = Time.get_ticks_usec()
	if animate_environment: elapsed += delta * motion_strength
	frames += 1
	if qa and frames > 15: timings.append(float(tick-last_tick)/1000.0)
	last_tick = tick
	update_visuals()
	if frames == 12 and still:
		await capture("static.png")
		get_tree().quit()

	if qa and frames in [30,300,600,900,1200,1500]:
		await capture("motion-%04d.png" % frames)
	if qa and elapsed >= 72.0:
		qa = false
		await capture("final.png")
		write_report()
		get_tree().quit()

func set_level_layer(solo: int) -> void:
	for child in get_children():
		var id = str(child.name)
		var group = 2
		if id.begins_with("ENV") or id.begins_with("WATER"): group = 0
		elif id == "BALEEN-DISTANT" or id.begins_with("MID") or id.begins_with("BEAM") or id.begins_with("FISH") or id.begins_with("BUBBLE") or id.begins_with("CAUSTIC"): group = 1
		elif id.begins_with("FRONT"): group = 3
		child.visible = solo < 0 or solo == group

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence_directory+filename)

func write_report() -> void:
	timings.sort()
	var nodes: Array = []
	var missing: Array = []
	for child in get_children():
		nodes.append(str(child.name))
		if child is Sprite2D and child.texture == null: missing.append(str(child.name))
	var report = {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),"seconds":elapsed,"frames":frames,"frame_ms_p50":timings[int(timings.size()*.5)],"frame_ms_p95":timings[int(timings.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"bubble_instances":bubbles.size(),"bubble_recycles":recycled,"missing_textures":missing,"visible_elements":nodes,"scope":"No gameplay, physics, audio or persistence","camera_drift":camera_drift}
	FileAccess.open(evidence_directory+"runtime-report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ENVIRONMENT_QA ",JSON.stringify(report))
