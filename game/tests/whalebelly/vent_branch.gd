extends "res://tests/chapter_branches.gd"
## Earn float at the existing memory reward fixture; all travel uses actual input.
class VentCampaign extends WhalebellyMain:
	func save_path() -> String: return "user://whalebelly/vent_qa_save.json"

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa/r1-chapter-scenes"))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(VentCampaign)
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(35)
	await host.flow_setup(6,[1300,569])
	await interact()
	check("earned_float_without_practice",host.abilities.float and not host.practice)
	check("memory_return",await drive(Vector2(95,568),true,1,1100,false))
	if host.room_index == 6: await interact("left")
	await tick(90)
	check("back_in_sieve",host.room_index == 1)
	check("drop_to_main",await drive(Vector2(1000,640),true,-1,1100,false))
	check("approach_left_stairs",await drive(Vector2(240,718),true,-1,1100,false))
	# Release jump before floating: only one jump, no second-jump rescue.
	Input.action_press("tp_jump")
	await tick(35)
	Input.action_release("tp_jump")
	await tick(2)
	Input.action_press("float")
	for frame in 110:
		await tick(1)
		if host.player.position.y < 450: break
	check("released_jump_does_not_cap_float",host.player.position.y < 450 and host.player.jump_count == 1)
	host.release_controls()
	var upper: Array[Vector2] = [Vector2(240,495),Vector2(240,280),Vector2(240,340),Vector2(240,130),Vector2(240,190)]
	for i in upper.size():
		if not await point("sieve_step_"+str(i),upper[i],i%2==0): break
	await point("leave_door_radius",Vector2(310,197),true)
	await point("vent_entry",Vector2(170,190),true)
	await interact()
	await tick(90)
	check("entered_vent",host.room_index == 5)
	if host.room_index == 5:
		var stairs: Array[Vector2] = [Vector2(350,560),Vector2(490,643),Vector2(550,420),Vector2(760,482),Vector2(850,270),Vector2(1173,332)]
		for i in stairs.size():
			if not await point("vent_step_"+str(i),stairs[i],i%2==1): break
		await interact()
		check("vent_reward",host.collected.get("R1-06",false))
		await capture("vent-reward")
		await point("far_latch",Vector2(1380,335),true)
		await interact()
		check("far_latch_remains_closed",host.room_index == 5)
		for target: Vector2 in [Vector2(850,482),Vector2(550,643),Vector2(315,792),Vector2(100,795)]:
			if not await point("return_"+str(int(target.x)),target,true): break
		await interact()
		await tick(90)
		check("return_to_sieve",host.room_index == 1 and host.player.position.y < 250)
		await point("drop_left_of_stairs",Vector2(80,718),true)
		check("safe_main_route",host.player.health > 0 and host.player.is_on_floor())
	var failed: int = checks.filter(func(row: Dictionary)->bool:return not row.pass).size()
	FileAccess.open("res://build/qa/vent-branch/route.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"\t"))
	await host.graceful_quit(1 if failed else 0)
