extends Node
var host: Node2D
var tests: Array[Dictionary] = []
var max_ground_error: float = 0.0
var unsupported_frames: int = 0

func check(label: String, passed: bool, detail: Variant = null) -> void:
	tests.append({"name":label,"pass":passed,"detail":detail})
	print("REFERENCE_LEVEL ", label, " ", passed)

func walk(x: float) -> void:
	var start_room: int = host.room_index
	for frame in range(600):
		if host.room_index != start_room or absf(host.player.position.x-x)<8: break
		Input.action_press("right" if host.player.position.x<x else "left")
		await host.wait_physics(1)
		if host.player.is_on_floor():
			max_ground_error=maxf(max_ground_error,absf(host.player.position.y-host.ground_y(host.player.position.x,host.player.position.y)))
		else: unsupported_frames+=1
	host.release_controls()
	await host.wait_physics(12)
	check("walk_to_"+str(x),absf(host.player.position.x-x)<15 and host.player.is_on_floor(),[host.player.position.x,host.player.position.y])

func screenshot(label: String) -> void:
	host.ui.visible=false
	await host.evidence_frame(label)
	host.ui.visible=true

func run() -> void:
	await host.wait_physics(40)
	var env: Node = host.scenery.get_node("ReferenceEnvironment")
	if "--reference-level-reload" in OS.get_cmdline_user_args():
		host.load_progress()
		host.load_room(host.room_index,host.checkpoint.pos)
		await host.wait_physics(35)
		check("independent_process_saved_state",host.collected.get("REFERENCE_LEVEL_SENTINEL",false) and host.room_index==0 and host.player.is_on_floor())
		check("single_player_after_reload",not host.scenery.get_node("ReferenceEnvironment").has_node("CHARACTER") and is_instance_valid(host.player.art))
		await screenshot("reload")
		await finish()
		return
	check("spawn_grounded",host.player.is_on_floor())
	check("reference_display_removed",not env.has_node("CHARACTER"))
	check("controller_owns_reference_art",host.player.art.get_node("PlayerArt/OriginalSilhouette").texture.resource_path.ends_with("CHARACTER.png"))
	check("bubble_single_source",env.bubbles.size()==56 and not host.scenery.get_node("EnvironmentMotion/AmbientBubbles").visible)
	await screenshot("start")
	await walk(110)
	host.health=3
	await host.input_tap("interact")
	check("camp_existing_interaction",host.health==5 and int(host.checkpoint.room)==0)
	var start_y: float=host.player.position.y
	await host.input_tap("jump")
	await host.wait_physics(12)
	check("jump_controller",host.player.position.y<start_y-40)
	await host.wait_physics(70)
	await host.input_tap("attack")
	check("attack_existing_frames",host.player.visual_state=="attack")
	await host.wait_physics(25)
	for x: float in [450.0,650.0,850.0,1100.0,1350.0,1580.0]:
		await walk(x)
		if x==850:
			await screenshot("crest")
			host.outlines=true
			await screenshot("road-collision")
			host.outlines=false
			host.zoomed=true
			await host.wait_physics(3)
			await screenshot("camera-zoom")
			host.zoomed=false
	await screenshot("exit")
	check("walk_contour_alignment",max_ground_error<8,{"maximum_feet_contour_px":max_ground_error,"unsupported_frames":unsupported_frames})
	Input.action_press("right")
	await host.input_tap("interact")
	host.release_controls()
	await host.wait_physics(30)
	check("r1_01_to_r1_02",host.room_index==1)
	if host.room_index==1:
		check("next_room_keeps_legacy_art",host.scenery.has_node("World/WorldOriginalPixels") and not host.scenery.has_node("ReferenceEnvironment"))
		var door: Dictionary=host.room.doors[0]
		await host.drive_to(host.point(door.pos))
		Input.action_press("left")
		await host.input_tap("interact")
		host.release_controls()
		await host.wait_physics(30)
	check("return_to_r1_01",host.room_index==0 and host.player.is_on_floor())
	if host.room_index!=0:
		await finish()
		return
	await screenshot("return")
	for x: float in [1250.0,850.0,450.0,110.0]: await walk(x)
	env=host.scenery.get_node("ReferenceEnvironment")
	var time_before: float=env.elapsed
	get_tree().paused=true
	await get_tree().create_timer(0.25,true).timeout
	check("pause_freezes_new_environment",env.elapsed==time_before)
	get_tree().paused=false
	await host.wait_physics(4)
	check("resume_environment",env.elapsed>time_before)
	host.layer_solo=3
	host.update_layers()
	check("foreground_solo",env.get_node("FRONT-01").visible and not env.get_node("ROAD").visible)
	host.layer_solo=-1
	host.update_layers()
	var old_player: int=host.player.get_instance_id()
	host.player.invulnerable=0
	host.player.hurt(5)
	await host.wait_physics(40)
	check("death_respawn",host.player.get_instance_id()!=old_player and host.player.is_on_floor() and host.room_index==0)
	await screenshot("respawn")
	# Explicit legacy save-position fixture, not part of route traversal.
	host.load_room(0,[239,611])
	await host.wait_physics(35)
	check("legacy_ground_coordinate_migrates",host.player.is_on_floor() and absf(host.player.position.y-host.ground_y(239,611))<4)
	host.collected["REFERENCE_LEVEL_SENTINEL"]=true
	host.manual_save()
	await finish()

func finish() -> void:
	var passed=true
	for test in tests: passed=passed and test.pass
	var suffix="reload" if "--reference-level-reload" in OS.get_cmdline_user_args() else "route"
	var report={"pass":passed,"tests":tests,"engine":Engine.get_version_info().string,"method":"Actual Input actions for walking, jumping, combat animation, camp and doors. No position writes during traversal. Death uses damage API; legacy-coordinate load is explicitly separate. QA save only."}
	FileAccess.open(host.qa_output.get_base_dir().path_join("reference-level-"+suffix+".json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	await host.graceful_quit(0 if passed else 1)
