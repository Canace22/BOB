extends "res://tests/whalebelly/combat_main_qa.gd"
var samples: Array[Dictionary] = []

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","route-direction")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	await tick(60)
	var view: WhaleCampaignRouteHUD = host.player_ui.hud.route_hud
	# 明确末段平台起点；只靠实际D输入跨过连续地图交界。
	for frame: int in 900:
		if host.streaming.is_ready(1): break
		await tick(1)
	var door: Dictionary = host.room.doors[0]
	var lane: Dictionary = host.room.layout.checkpoint_lanes.filter(func(value: Dictionary) -> bool: return float(value.x[0])<float(door.pos[0]) and float(value.x[1])>float(door.pos[0]) and absf(float(value.y)-float(door.pos[1]))<24)[0]
	host.player.position = Vector2(float(lane.x[0])+4,float(lane.y)-4)
	host.player.velocity = Vector2.ZERO
	await tick(15)
	var crossed: bool = false
	var entry_checked: bool = false
	var last_x: float = host.player.global_position.x
	var stopped: int = 0
	press(KEY_D,true)
	for frame: int in 600:
		await tick(1)
		stopped = stopped+1 if absf(host.player.global_position.x-last_x)<0.1 else 0
		last_x = host.player.global_position.x
		if stopped==30:
			await tap(KEY_SPACE)
			stopped = 0
		if frame%10==0:
			var sample: Dictionary = {"frame":frame,"room":str(host.room.id),"player":str(host.player.global_position),"arrows":[]}
			for marker: Dictionary in view.markers:
				sample.arrows.append({"target":marker.id,"side":marker.side,"world":str(marker.world_point)})
			samples.append(sample)
		if str(host.room.id)=="R1-02":
			crossed = true
			if view.source_id!="R1-02": continue
			var back: Array[Dictionary] = view.markers.filter(func(marker: Dictionary) -> bool: return marker.id=="R1-01")
			if back.is_empty(): continue
			if not entry_checked:
				check("D input crosses seamlessly from final platform into sieve",host.streaming.enabled)
				check("left destination stays left immediately after seam ownership switch",back[0].side=="left" and Vector2(back[0].world_point).x<host.player.global_position.x)
				await shot("route-direction-sieve-entry")
				entry_checked = true
			if host.player.position.x>180: break
	press(KEY_D,false)
	await tick(4)
	check("continuous D input reached the reported room",crossed and entry_checked)
	check("junction retains all four exits",view.markers.size()==4)
	check("both upper branches keep an upward direction",view.markers.filter(func(marker: Dictionary) -> bool: return marker.id in ["R1-06","R1-07"] and Vector2(marker.direction).y<0).size()==2)
	# 只布置长文避让条件；出口/房间与主角位置仍取本次实际步行结果。
	var prompt: WhaleInteractionPrompt = host.player_ui.hud.interaction_prompt
	host.player_ui.hud.set_process(false)
	prompt.present("牵引前方圆环 · 到环停挂 · 空格跃离", "G",false)
	await tick(15)
	var back: Array[Dictionary] = view.markers.filter(func(marker: Dictionary) -> bool: return marker.id=="R1-01")
	check("prompt clearance never moves the return marker to right",not back.is_empty() and back[0].side=="left")
	await shot("route-direction-prompt")
	host.player_ui.hud.set_process(true)
	root.size = Vector2i(960,540)
	await tick(8)
	back = view.markers.filter(func(marker: Dictionary) -> bool: return marker.id=="R1-01")
	check("small window preserves the real leftward return",not back.is_empty() and back[0].side=="left")
	await shot("route-direction-small-window")
	root.size = Vector2i(1280,720)
	press(KEY_A,true)
	for frame: int in 360:
		await tick(1)
		if str(host.room.id)=="R1-01" and view.source_id=="R1-01": break
	press(KEY_A,false)
	await tick(2)
	check("A input returns across the same seam",str(host.room.id)=="R1-01")
	check("after returning, sieve remains to the right",view.markers.size()==1 and view.markers[0].side=="right")
	await shot("route-direction-return")
	var file := FileAccess.open("res://build/qa/route-direction-samples.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(samples,"\t"))
	file.close()
	print("ROUTE_DIRECTION_QA failures=",failures)
	await host.graceful_quit(1 if failures else 0)
