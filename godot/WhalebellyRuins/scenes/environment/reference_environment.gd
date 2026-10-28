extends Node2D
## A reference-only environmental study. No player, gameplay or persistent state.
@export var animate_environment: bool = true
@export var camera_drift: bool = false
@export var level_mode: bool = false
var level_host: Node2D
var level_camera_offset: Vector2 = Vector2.ZERO
@export_range(0.0, 1.0) var motion_strength: float = 1.0
@export_range(0.0, 3.0) var foliage_amplitude_px: float = 1.8
@export_range(0.0, 12.0) var fish_amplitude_px: float = 8.0
var elapsed: float = 0.0
var frames: int = 0
var bases: Dictionary = {}
var bubbles: Array[Dictionary] = []
var timings: Array[float] = []
var last_tick: int = 0
var qa: bool = false
var still: bool = false
var recycled: int = 0
const EVIDENCE = "res://evidence/reference_environment/motion_refinement/"
const REGIONS = [Rect2(143,170,89,220), Rect2(414,310,72,98), Rect2(786,119,154,282), Rect2(1036,358,95,128)]

func _ready() -> void:
	var args = OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(EVIDENCE)
	qa = not level_mode and "--qa" in args
	still = not level_mode and "--static" in args
	if still: animate_environment = false
	if "--pan" in args: camera_drift = true
	for child in get_children():
		if child is Sprite2D:
			bases[child.name] = child.position
			if str(child.name).begins_with("BALEEN") or str(child.name).begins_with("PLANT") or str(child.name).begins_with("VINE"):
				var mat = ShaderMaterial.new()
				mat.shader = load("res://scenes/environment/root_sway.gdshader")
				mat.set_shader_parameter("root_at_bottom",str(child.name).begins_with("PLANT"))
				mat.set_shader_parameter("phase",float(child.get_index()) * 1.71)
				mat.set_shader_parameter("curtain",str(child.name).begins_with("BALEEN"))
				mat.set_shader_parameter("source_origin",child.position)
				child.material = mat
	if level_mode:
		var display = get_node("CHARACTER")
		bases.erase(display.name)
		remove_child(display)
		display.queue_free()
	# Overscan is hidden-only paint. Original road/character/architecture are not stretched.
	var under = get_node("ENV-UNDERPAINT") as Sprite2D
	under.scale = Vector2(1.04,1.067)
	under.position = Vector2(-25.6,-24.12)
	bases[under.name] = under.position
	var texture = load("res://assets/reference_environment/bubble.png")
	for region_id in range(4):
		var holder = Node2D.new()
		holder.name = "BUBBLE-ZONE-%02d" % (region_id+1)
		holder.z_index = -20
		add_child(holder)
		for i in range(9):
			var sprite = Sprite2D.new()
			sprite.texture = texture
			var near_bubble = region_id == 3 and i < 3
			var size_px = (9.0 + i * 3.0) if near_bubble else (2.5 + fmod(float(i*17+region_id*3),5.0))
			sprite.scale = Vector2.ONE * size_px / 12.0
			var opacity = 0.62 if near_bubble else 0.35 + float(i%3)*0.13
			sprite.modulate.a = opacity
			if near_bubble: sprite.z_index = 45 # In front of the road, behind the dark framing.
			holder.add_child(sprite)
			var region = Rect2(1060, 405, 74, 255) if near_bubble else REGIONS[region_id]
			bubbles.append({"node":sprite,"region":region_id,"bounds":region,"index":i,"speed":(21.0+i*3.0) if near_bubble else 7.0+float(i%7),"opacity":opacity,"near":near_bubble,"last_cycle":0})
	update_visuals()

func update_visuals() -> void:
	# The clock only advances while enabled. Toggling animation holds its pose.
	var t = elapsed
	var pan = level_camera_offset if level_mode else (Vector2(sin(t*TAU/24.0)*5.0,sin(t*TAU/17.0)*2.0) if camera_drift else Vector2.ZERO)
	for child in get_children():
		if not child is Sprite2D: continue
		var id = str(child.name)
		var parallax = 0.0
		if id.begins_with("ENV"): parallax = 0.13
		if id.begins_with("MID") or id.begins_with("BEAM"): parallax = 0.09
		# Outer foreground stays anchored at the crop to prevent exposed canvas edges.
		if id == "FRONT-02": parallax = -0.10
		child.position = bases[child.name] - pan * parallax
		if id.begins_with("FISH"):
			var phase = 0.65 if id == "FISH-02" else 2.2
			var period = 28.0 if id == "FISH-02" else 34.0
			child.position += Vector2((sin(t*TAU/period+phase)-sin(phase))*0.5*fish_amplitude_px,(sin(t*TAU/(period*0.5)+phase)-sin(phase))*0.6)
		if child.material is ShaderMaterial:
			child.material.set_shader_parameter("clock",t)
			child.material.set_shader_parameter("strength",foliage_amplitude_px)
		if id == "LAMP" or id.begins_with("BEAM"):
			var amp = 0.02 if id == "LAMP" else 0.012
			var phase = float(child.get_index())*1.37
			var value = 1.0+(sin(t*TAU/8.0+phase)-sin(phase))*0.5*amp
			child.modulate = Color(value,value,value,1.0)
	for bubble in bubbles:
		var region: Rect2 = bubble.bounds
		var traveled: float = t*bubble.speed+float(bubble.index)/9.0*region.size.y
		var cycle = int(traveled/region.size.y)
		if cycle > bubble.last_cycle:
			recycled += 1
			bubble.last_cycle = cycle
		var y = region.end.y-fmod(traveled,region.size.y)
		var x = region.position.x+region.size.x*(0.18+fmod(float(bubble.index)*0.367,0.64))
		x += sin(t*.5+float(bubble.index))*(3.0 if bubble.near else 1.3)
		bubble.node.position = Vector2(x,y)
		var edge = min(y-region.position.y,region.end.y-y)
		bubble.node.modulate.a = smoothstep(0.0,24.0 if bubble.near else 12.0,edge)*bubble.opacity

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
		if id.begins_with("ENV"): group = 0
		elif id.begins_with("MID") or id.begins_with("BEAM") or id.begins_with("FISH") or id.begins_with("BUBBLE"): group = 1
		elif id.begins_with("FRONT"): group = 3
		child.visible = solo < 0 or solo == group

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(EVIDENCE+filename)

func write_report() -> void:
	timings.sort()
	var nodes: Array = []
	var missing: Array = []
	for child in get_children():
		nodes.append(str(child.name))
		if child is Sprite2D and child.texture == null: missing.append(str(child.name))
	var report = {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),"seconds":elapsed,"frames":frames,"frame_ms_p50":timings[int(timings.size()*.5)],"frame_ms_p95":timings[int(timings.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"bubble_instances":bubbles.size(),"bubble_recycles":recycled,"missing_textures":missing,"visible_elements":nodes,"scope":"No gameplay, physics, audio or persistence","camera_drift":camera_drift}
	FileAccess.open(EVIDENCE+"runtime-report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ENVIRONMENT_QA ",JSON.stringify(report))
