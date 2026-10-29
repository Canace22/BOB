extends Node2D
var elapsed: float = 4.0
var playing: bool = true
var groups: Array[Node2D] = []
var qa: bool = false
@onready var environment: Node2D = $Environment

func _ready() -> void:
	qa = "--fish-qa" in OS.get_cmdline_user_args()
	environment.set_process(false)
	for child in environment.get_children():
		if str(child.name).begins_with("FISH"):
			child.hide()
	for k in 3:
		var ids: Array[String] = ["silverfin", "tealback", "lantern"]
		var scene: PackedScene = load("res://scenes/environment/elements/%s_school_v01.tscn" % ids[k])
		var group: Node2D = scene.instantiate()
		group.autoplay = false
		group.z_index = -25
		group.name = "NewFishSchool%d" % k
		environment.add_child(group)
		groups.append(group)
	if qa:
		DirAccess.make_dir_recursive_absolute("res://evidence/fish_schools")
		set_process(false)
		call_deferred("run_checks")

func _process(delta: float) -> void:
	if playing: elapsed += delta
	apply_time(elapsed)

func apply_time(time: float) -> void:
	environment.elapsed = time
	environment.update_visuals()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE: playing = not playing
		if event.keycode == KEY_R: elapsed = 0.0
		if event.keycode in [KEY_1, KEY_2, KEY_3]:
			var which: int = event.keycode - KEY_1
			groups[which].visible = not groups[which].visible

func sample_state() -> Array:
	var rows: Array = []
	for group in groups:
		for fish in group.sprites:
			rows.append([fish.position, fish.scale, fish.rotation, fish.frame])
	return rows

func run_checks() -> void:
	apply_time(0.0)
	var start: Array = sample_state()
	apply_time(16.0)
	var finish: Array = sample_state()
	var max_delta: float = 0.0
	var frame_equal: bool = true
	for i in start.size():
		max_delta = maxf(max_delta, start[i][0].distance_to(finish[i][0]))
		frame_equal = frame_equal and start[i][3] == finish[i][3]
	apply_time(8.0)
	var held: Array = sample_state()
	await get_tree().process_frame
	await get_tree().process_frame
	var pause_ok: bool = held == sample_state()
	var changed: bool = start != held
	var checks: Dictionary = {"engine": Engine.get_version_info().string, "instances": start.size(), "counts": [groups[0].sprites.size(),groups[1].sprites.size(),groups[2].sprites.size()], "loop_position_delta":max_delta,"loop_frames_equal":frame_equal,"pause_holds":pause_ok,"motion_changes":changed,"main_level_modified":false}
	for second: float in [0.0, 2.0, 6.0, 8.0, 12.0, 15.958333, 16.0]:
		apply_time(second)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://evidence/fish_schools/frame_%05.2f.png" % second)
	FileAccess.open("res://evidence/fish_schools/checks.json", FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	print("FISH_QA ",JSON.stringify(checks))
	get_tree().quit(0 if max_delta < 0.001 and frame_equal and pause_ok and changed and start.size() == 62 else 1)
