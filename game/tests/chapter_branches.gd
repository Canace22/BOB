extends SceneTree
## Current-controller input routes. Scenario starts are fixtures; routes never set transforms.
var host: Node2D
var checks: Array[Dictionary] = []

func _initialize() -> void: run.call_deferred()
func tick(frames: int) -> void:
	for frame in frames: await physics_frame
func check(label: String, ok: bool, detail: Variant=null) -> void:
	checks.append({"id":label,"pass":ok,"detail":detail})
	print("BRANCH ",label," ",ok," ",detail)
func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/qa/r1-chapter-scenes/"+label+".png")
func settle() -> void:
	host.release_controls()
	await tick(24)
func interact(direction: String="") -> void:
	await settle()
	if not direction.is_empty(): Input.action_press(direction)
	Input.action_press("tp_interact")
	await tick(3)
	Input.action_release("tp_interact")
	await tick(48)
	if not direction.is_empty(): Input.action_release(direction)
func drive(target: Vector2, grounded: bool=false, expected: int=-1, budget: int=1100, use_rings: bool=true) -> bool:
	var initial: int=host.room_index
	var sequence: int=host.event_sequence
	var held_jump := 0
	var since_jump := 100
	for frame in budget:
		if host.room_index!=initial:
			host.release_controls()
			return host.room_index==expected and host.events.any(func(e: Dictionary)->bool:return int(e.seq)>sequence and e.event=="door" and int(e.data.from)==initial and int(e.data.to)==expected)
		var player: CharacterBody2D=host.player
		var delta: Vector2=target-player.position
		if absf(delta.x)<18 and absf(delta.y)<36 and (not grounded or player.is_on_floor()):
			host.release_controls()
			return true
		Input.action_release("tp_left");Input.action_release("tp_right")
		if absf(delta.x)>8: Input.action_press("tp_right" if delta.x>0 else "tp_left")
		if held_jump>0:
			held_jump-=1
			if held_jump==0: Input.action_release("tp_jump")
		since_jump+=1
		var launch: bool = (player.is_on_floor() and delta.y < -40 or player.grapple_hanging) and since_jump>35
		if player.is_on_floor():
			for surface: Array in host.room.surfaces:
				var edge: Vector2=host.point(surface[-1] if delta.x>0 else surface[0])
				if absf(player.position.x-edge.x)<65 and absf(player.position.y-edge.y)<45 and absf(delta.x)>95 and since_jump>35: launch=true
		if not player.is_on_floor() and delta.y < -65 and player.jump_count<2 and player.velocity.y>-40 and (not host.has_ability("float") or player.float_left<.1) and since_jump>36: launch=true
		if launch and held_jump==0:
			Input.action_press("tp_jump");held_jump=35;since_jump=0
		var platform_below := false
		for surface: Array in host.room.surfaces:
			if player.position.x>=float(surface[0][0]) and player.position.x<=float(surface[-1][0]):
				platform_below=true
		var gap_support: bool = not platform_below and absf(delta.x)>80 and host.has_ability("float")
		if (delta.y < -22 or gap_support) and not player.is_on_floor(): Input.action_press("float")
		else: Input.action_release("float")
		if use_rings and not player.is_on_floor() and absf(delta.x)>80 and host.has_ability("anchor") and player.grapple_target==Vector2.INF and frame%32==4: Input.action_press("grapple")
		if frame%32==5: Input.action_release("grapple")
		if frame%30==0 and host.enemies.any(func(e: Dictionary)->bool:return e.alive and Vector2(e.pos).distance_to(player.position)<170): Input.action_press("tp_attack")
		if frame%30==2: Input.action_release("tp_attack")
		await physics_frame
	host.release_controls()
	print("DRIVE_TIMEOUT ",host.room.id," at ",host.player.position," target ",target)
	return false
func point(label: String, target: Vector2, grounded: bool=false, expected: int=-1) -> bool:
	var ok := await drive(target,grounded,expected)
	check(label,ok,{"room":host.room.id,"position":host.player.position})
	return ok
func run() -> void:
	host=(load("res://content/whalebelly/main.tscn") as PackedScene).instantiate()
	host.qa=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host
	await tick(35)
	# Normal optional reward: land and wait for the action recovery before E.
	await host.flow_setup(2)
	await point("03_reward_approach",Vector2(1000,589),true)
	await point("03_reward_jump_lane",Vector2(990,360))
	await point("03_reward_platform",Vector2(1135,442),true)
	await interact()
	check("03_reward_with_normal_movement",host.collected.get("R1-03",false) and not host.abilities.float and not host.practice)
	await capture("03-reward-collected")
	await point("03_neighbor_exit",Vector2(1605,612),false,3)
	check("03_to_04_input_connection",host.room_index==3)
	# Normal-state ability door denial, using the real interact action.
	await host.flow_setup(1,[210,186])
	await interact()
	check("float_door_stays_locked_without_ability",host.room_index==1 and not host.abilities.float)
	# A single explicit practice setup; no formal progress changes or new abilities.
	await host.flow_setup(1,[225,716])
	await host.key_tap(KEY_F9)
	check("existing_practice_mode",host.practice)
	var upper: Array[Vector2]=[Vector2(100,420),Vector2(240,495),Vector2(110,265),Vector2(240,340),Vector2(90,110),Vector2(210,186)]
	for i in upper.size():
		if not await point("upper_step_"+str(i),upper[i],i%2==1,5): break
		if host.room_index==5: break
	if host.room_index==1: await interact("left")
	check("02_to_06_input_connection",host.room_index==5)
	if host.room_index==5:
		var stairs: Array[Vector2]=[Vector2(350,560),Vector2(490,643),Vector2(550,420),Vector2(760,482),Vector2(850,270),Vector2(1173,332)]
		for i in stairs.size():
			if not await point("06_stair_"+str(i),stairs[i],i%2==1): break
		await interact()
		check("06_reward_collected",host.collected.get("R1-06",false))
		await capture("06-reward-collected")
		await point("06_far_latch_walk",Vector2(1380,335),true)
		await interact("right")
		check("far_latch_does_not_open_R2",host.room_index==5)
		for target: Vector2 in [Vector2(850,482),Vector2(550,643),Vector2(315,792),Vector2(100,795)]:
			if not await point("06_return_"+str(int(target.x)),target,true,1): break
			if host.room_index==1: break
		if host.room_index==5: await interact("left")
		check("06_to_02_input_connection",host.room_index==1)
	# Separate fixture for the second authored branch, preserving the same practice rules.
	await host.flow_setup(1,[1100,690])
	if not host.practice: await host.key_tap(KEY_F9)
	var rings: Array[Vector2]=[Vector2(1130,575),Vector2(1245,465),Vector2(1360,345),Vector2(1320,230),Vector2(1570,277)]
	for i in rings.size():
		if not await point("02_ring_"+str(i),rings[i],i==4,6 if i==4 else -1): break
	if host.room_index==1: await interact("right")
	check("02_to_07_input_connection",host.room_index==6)
	if host.room_index==6:
		await point("07_gaps_to_reward",Vector2(1300,569),true)
		await interact()
		check("07_reward_collected",host.collected.get("R1-07",false))
		await capture("07-reward-collected")
		var returned := await drive(Vector2(95,568),true,1,1100,false)
		check("07_return_gaps",returned,{"room":host.room.id,"position":host.player.position})
		if host.room_index==6: await interact("left")
		check("07_to_02_input_connection",host.room_index==1)
	var failed: Array[Dictionary]=checks.filter(func(item: Dictionary)->bool:return not item.pass)
	FileAccess.open("res://build/qa/r1-chapter-scenes/branches.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed.size(),"scope":"original ability practice, real input; only initial branch fixture positions assigned"},"\t"))
	print("BRANCHES_COMPLETE checks=",checks.size()," failed=",failed.size())
	await host.graceful_quit(0 if failed.is_empty() else 1)
